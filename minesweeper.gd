extends Control

## STATE VARIABLES
var time: int = 0
var mines_remaining: int = 10
var current_state: GameState = GameState.READY_TO_START
var DEBUG_SHOW_BOARD = true

# menu options
var enable_marks: bool = false
var enable_color: bool = false
var enable_sound: bool = false

@export var grid_width: int = 20
@export var grid_height: int = 20
@export var total_mines: int = 10

var cell_data = []
"""Array of arrays of ints/bitfields. See masks below for how to read"""

var clicking = false
"""Game allows you to click and drag and the cells are updated as you move. This
is used to emulate that"""

var mouseover = false
"""Used to determine if we can apply the stopped clock cheat"""

## CONSTANT VALUES
# atlas indexes for cells
const BLANK = Vector2i(0, 0)
const FLAG = Vector2i(0, 1)
const QUESTION = Vector2i(0, 2)
const MINE_HIT = Vector2i(0, 3)
const NOT_MINE = Vector2i(0, 4)
const MINE = Vector2i(0, 5)
const QUESTION_PRESSED = Vector2i(0, 6)
const EMPTY = Vector2i(0, 15)

const FACE_OOOOOO: Resource = preload("res://bitmap/face/face_shocked.tres")
const FACE_HAPPY: Resource = preload("res://bitmap/face/face_happy.tres")
const FACE_DEAD: Resource = preload("res://bitmap/face/face_dead.tres")
const FACE_COOL: Resource = preload("res://bitmap/face/face_cool.tres")
const FACE_PRESSED: Resource = preload("res://bitmap/face/face_pressed.tres")

const FACE_COLOR_ATLAS: Resource = preload("res://bitmap/face/face_color_atlas.tres")
const FACE_BW_ATLAS: Resource = preload("res://bitmap/face/face_bw_atlas.tres")

const SOUND_CLOCK: Resource = preload("res://sound/432.wav")
const SOUND_WIN: Resource = preload("res://sound/433.wav")
const SOUND_KABOOM: Resource = preload("res://sound/434.wav")

const GRID_TILESET_COLOR: Resource = preload("res://bitmap/minebtn/color_tileset.tres")
const GRID_TILESET_BW: Resource = preload("res://bitmap/minebtn/bw_tileset.tres")

const NINE_PATCH_COLOR: Resource = preload("res://bitmap/9patch_texture.tres")
const NINE_PATCH_BW: Resource = preload("res://bitmap/9patch_bw_texture.tres")


const NUMBER_LOOKUP = {
	1: Vector2i(0, 14),
	2: Vector2i(0, 13),
	3: Vector2i(0, 12),
	4: Vector2i(0, 11),
	5: Vector2i(0, 10),
	6: Vector2i(0, 9),
	7: Vector2i(0, 8),
	8: Vector2i(0, 7)
}

const NUMBER_MASK = 15
const FLAG_MINE = 16
const FLAG_FLAG = 32
const FLAG_QUESTION = 64
const FLAG_REVEALED = 128


enum GameState {
	READY_TO_START,
	GAME_RUNNING,
	GAME_OVER_LOST,
	GAME_OVER_WON
}

func set_window_size():
	"""Resize the 9patch to match the grid size. This could probably be done with no code if I was
	smarter with godot layout stuff"""
	
	# magic numbers!
	const top_height = 96
	const left_margin = 15
	const right_margin = 11
	const bottom_margin =  11
	
	const grid_cell_size = 16
	
	var width = left_margin + right_margin + grid_cell_size * grid_width
	var height = top_height + bottom_margin	+ grid_cell_size * grid_height
	
	self.set_size(Vector2i(width, height))
	
func set_face(res: Resource):
	$Window/MarginContainer/Bar/FaceButtonFrame/FaceButton.texture_normal = res

func change_game_state(new_state: GameState):
	print("changing state %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
	var game_over_lost = func():
		save_manager.clear_save_game()
		$Timer.stop()
		set_face(FACE_DEAD)
		show_board()
		if enable_sound:
			$Sound.stream = SOUND_KABOOM
			$Sound.play()
	
	var game_over_won = func():
		# Why does this crash here (save_manager is not defined???)
		# save_manager.clear_save_game()
		$Timer.stop()
		set_face(FACE_COOL)
		if enable_sound:
			$Sound.stream = SOUND_WIN
			$Sound.play()

		var save_manager = self.get_node("/root/SaveManager")
		if save_manager.has_high_score(self.time, $MenuBar.difficulty):
			$fastest_time_modal.show_modal($MenuBar.difficulty)
			var new_name = await $fastest_time_modal.player_name
			save_manager.store_score(self.time, $MenuBar.difficulty, new_name)
			$MenuBar/fastest_minesweepers.show_scores()
			
	match current_state:
		GameState.READY_TO_START:
			match new_state:
				GameState.GAME_RUNNING:
					start_game()
				GameState.READY_TO_START:
					reset_game()
				_:
					assert(false, "unexpected transition READY_TO_START -> %s" % GameState.keys()[new_state])
		GameState.GAME_RUNNING:
			match new_state:
				GameState.GAME_OVER_LOST:
					game_over_lost.call()
				GameState.GAME_RUNNING:
					# restart
					update_mine_count(total_mines)
					start_game()
				GameState.READY_TO_START:
					reset_game()
				GameState.GAME_OVER_WON:
					save_manager.clear_save_game()
					game_over_won.call()
				_:
					assert(false, "unexpected transition GAME_RUNNING -> %s" % GameState.keys()[new_state])
		GameState.GAME_OVER_LOST, GameState.GAME_OVER_WON:
			match new_state:
				GameState.READY_TO_START:
					save_manager.clear_save_game()
					reset_game()
				_:
					assert(false, "unexpected transition GAME_OVER_LOST / GAME_OVER_WON -> %s" % GameState.keys()[new_state])
		_:
			assert(false, "you forgot to handle state %s" % GameState.keys()[current_state])
	current_state = new_state
	
func global2grid(location: Vector2i):
	return $Grid.local_to_map($Grid.to_local(location))

func loc_in_grid(location: Vector2i):
	"""
	Returns true if the location is within the grid
	"""
	return (
		location.x >= 0 and location.y >= 0 and 
		location.x < grid_width and location.y < grid_height
	)

func update_mine_count(new_count: int) -> void:
	mines_remaining = new_count
	var value = "%03d" % mines_remaining
	if mines_remaining < 0:
		value[0] = "-"
	$Window/MarginContainer/Bar/MineCounter.change_value.emit(value)

func set_cell_data(cell_data: Array):
	"""Forces the grid to match cell_data
	
	Normally changes are made to the grid and cell_data in parallel, so we don't
	have to do something like this often. After loading a game though we need
	to force the grid to match
	"""
	
	self.cell_data = cell_data
	self.grid_height = len(self.cell_data)
	self.grid_width = len(self.cell_data[0])
	
	$Grid.clear()
	
	for y in range(grid_height):
		for x in range(grid_width):
			var location = Vector2i(x, y)
			var cell = self.cell_data[y][x]
			$Grid.set_cell(0, location, 0, BLANK, 0)
			
			if cell & self.FLAG_FLAG:
				$Grid.set_cell(0, location, 0, FLAG, 0)
			
			if cell & self.FLAG_QUESTION:
				$Grid.set_cell(0, location, 0, QUESTION, 0)
			
			
			if cell & self.FLAG_REVEALED:
				var number = cell & NUMBER_MASK
				if number:
					$Grid.set_cell(0, location, 0, NUMBER_LOOKUP[number], 0)
				else:
					$Grid.set_cell(0, location, 0, EMPTY, 0)
			
			if self.DEBUG_SHOW_BOARD and cell & self.FLAG_MINE:
				$Grid.set_cell(0, Vector2i(x, y), 0, MINE, 0)

func right_click_cell(location: Vector2i):
	var type = get_cell_type(location)
	
	if type == BLANK:
		$Grid.set_cell(0, location, 0, FLAG, 0)
		cell_data[location.y][location.x] |= FLAG_FLAG
		update_mine_count(mines_remaining - 1)
	elif type == FLAG and enable_marks:
		update_mine_count(mines_remaining + 1)
		cell_data[location.y][location.x] &= ~FLAG_FLAG
		cell_data[location.y][location.x] |= FLAG_QUESTION
		$Grid.set_cell(0, location, 0, QUESTION, 0)
	elif type == FLAG and not enable_marks:
		cell_data[location.y][location.x] &= ~FLAG_FLAG
		$Grid.set_cell(0, location, 0, BLANK, 0)
	elif type == QUESTION:
		cell_data[location.y][location.x] &= ~FLAG_QUESTION
		$Grid.set_cell(0, location, 0, BLANK, 0)
	

func handle_first_click_mine(location: Vector2i) -> void:
	"""On the first click of the game, the player can't lose. If they click on
	a mine, it is instead moved to the first available spot."""
	var cell = cell_data[location.y][location.x]
	if not cell & FLAG_MINE:
		return
	print("relocating mine - you're welcome")
	# it's a mine, and we need to move it
	# clear the mine flag where they clicked
	self.cell_data[location.y][location.x] = 0
	
	var move_mine = func(): 
		# move the mine to the first empty spot
		for y in range(grid_height):
			for x in range(grid_width):
				if y == location.y and x == location.x:
					# don't put it back where we started!
					continue
				if not(cell_data[y][x] & FLAG_MINE):
					print("new mine is at (%d, %d)" % [x, y])
					# clear any number flags & set the mine bit
					cell_data[y][x] = FLAG_MINE
					return
		assert(false, "uhhh we didn't find a place to put this mine, is the board full?")
	
	# clear all the numbers, we're going to recreate them below
	for y in range(grid_height):
		for x in range(grid_width):
			var data = cell_data[y][x]
			cell_data[y][x] = (data | self.NUMBER_MASK) ^ self.NUMBER_MASK
	
	move_mine.call()
	self.update_numbers()
	
	if DEBUG_SHOW_BOARD:
		show_board()

func save() -> void:
	save_manager.save_game_state(self.time, self.mines_remaining, self.cell_data)

func click_cell(location: Vector2i) -> void:
	var cell = cell_data[location.y][location.x]
	if cell & FLAG_REVEALED:
		# no sense doing anything if its been clicked
		return
	
	if cell & FLAG_FLAG:
		# can't click on flagged cell
		return
	
	if cell & FLAG_MINE:
		# game over
		change_game_state(GameState.GAME_OVER_LOST)
		# set the current cell red
		$Grid.set_cell(0, location, 0, MINE_HIT, 0)
		return
	
	# we're going to reveal it now
	
	if cell & NUMBER_MASK:
		$Grid.set_cell(0, location, 0, NUMBER_LOOKUP[cell & NUMBER_MASK], 0)
		cell_data[location.y][location.x] |= FLAG_REVEALED
		self.save()
		
		if game_is_won():
			change_game_state(GameState.GAME_OVER_WON)
		return # no flooding if you clicked on a number
	$Grid.set_cell(0, location, 0, EMPTY, 0)
	
	# BFS
	var queue = [location]
	while len(queue):
		var cur = queue.pop_front()
		if (cur.x < 0 or cur.x >= grid_width or
			cur.y < 0 or cur.y >= grid_height):
				# illegal position
				continue
		var cur_data = cell_data[cur.y][cur.x]
		if cur_data & FLAG_REVEALED:
			# already visited
			continue
		if cur_data & FLAG_FLAG:
			# flags block exploration, do nothing
			continue
		# committing to visiting it
		cell_data[cur.y][cur.x] |= FLAG_REVEALED
		
		var number = cur_data & NUMBER_MASK
		if number:
			$Grid.set_cell(0, cur, 0, NUMBER_LOOKUP[number], 0)
			# don't explore neighbors
			continue

		# add neighbors to queue
		queue.append_array([
			cur + Vector2i(-1, -1), cur + Vector2i(0, -1), cur + Vector2i(1, -1),
			cur + Vector2i(-1, 0),                         cur + Vector2i(1, 0),
			cur + Vector2i(1, 1),   cur + Vector2i(0, 1),  cur + Vector2i(1, 1)
		])

		# it's blank, reveal it
		$Grid.set_cell(0, cur, 0, EMPTY, 0)
	
	self.save()
	if game_is_won():
		change_game_state(GameState.GAME_OVER_WON)
	
func game_is_won():
	"""Win condition: every cell is revealed except for the mines"""
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = cell_data[y][x]
			if cell & FLAG_MINE:
				continue
			
			if (
				not ( cell & FLAG_REVEALED )  # is blank, revealed tile
			):
				# this cell has not been revealed, meaning they aren't done yet
				return false
	return true

func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if current_state not in [GameState.GAME_RUNNING, GameState.READY_TO_START]:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and event.position.y >= 40:
				# always set face to shocked, the game does this for some reason
				set_face(FACE_OOOOOO)
				clicking = true
			else:
				# mouseup
				
				# use self.get_global_mouse_position() insetad of event.global_position
				# global_position is not scale dependent, but the rest of the functions
				# we call are scale dependent
				var click_grid_location = global2grid(self.get_global_mouse_position())
				if loc_in_grid(click_grid_location):
					if clicking and current_state == GameState.READY_TO_START:
						change_game_state(GameState.GAME_RUNNING)
						handle_first_click_mine(click_grid_location)
						
					click_cell(click_grid_location)
				clicking = false
				$Grid.clear_layer(1)
				var face_texture = FACE_HAPPY
				if current_state == GameState.GAME_OVER_LOST:
					face_texture = FACE_DEAD
				elif current_state == GameState.GAME_OVER_WON:
					face_texture = FACE_COOL
					
				set_face(face_texture)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var location = global2grid(event.global_position)
			if loc_in_grid(location):
				right_click_cell(location)

func show_board() -> void:
	"""End-of-game board state"""
	
	for x in range(grid_width):
		for y in range(grid_height):
			var cell =  cell_data[y][x]
			#var number_val = cell_data[y][x] & NUMBER_MASK
			
			if cell & FLAG_FLAG and not cell & FLAG_MINE:
				$Grid.set_cell(0, Vector2i(x, y), 0, NOT_MINE, 0)
			elif cell & FLAG_MINE and not cell & FLAG_FLAG:
				$Grid.set_cell(0, Vector2i(x, y), 0, MINE, 0)

func update_numbers() -> void:
	var get_number = func(x: int, y: int) -> int:
		"""Count the number of adjacent mines at x,y"""
		var sum = 0
		for i in range(x - 1, x + 2):
			if i < 0 or i >= grid_width:
				continue
			for j in range(y - 1, y + 2):
				if j < 0 or j >= grid_height:
					continue
				if cell_data[j][i] & FLAG_MINE:
					sum += 1
		return sum
		
	for y in range(grid_height):
		for x in range(grid_width):
			if not(cell_data[y][x] & FLAG_MINE):
				assert(cell_data[y][x] & NUMBER_MASK == 0)
				var mine_count = get_number.call(x, y)
				assert(mine_count < 9)
				cell_data[y][x] |= mine_count

func prepare_board() -> void:
	cell_data = []
	
	# set visible area
	for y in range(grid_height):
		var new_row = []
		new_row.resize(grid_width)
		new_row.fill(0)
		cell_data.append(new_row)
		for x in range(grid_width):
			$Grid.set_cell(0, Vector2i(x, y), 0, BLANK, 0)

	var rng = RandomNumberGenerator.new()
	
	# the actual minesweeper uses a 16 bit PRNG. In the same spirit, we restrict
	# the seeds to 2^16 so that there are only that many boards. No, I'm not
	# implementing board cycles and stuff
	var seed = rng.randi_range(0, 2**16-1)
	print("seed is ", seed)
	rng.seed = seed
	
	
	# place mines
	for i in range(total_mines):
		var get_random_cell = func():
			var x1 = rng.randi_range(0, grid_width - 1)
			var y1 = rng.randi_range(0, grid_height - 1)
			return Vector2i(x1, y1)
			
		var loc = get_random_cell.call()
		
		while cell_data[loc.y][loc.x] & FLAG_MINE:
			loc = get_random_cell.call()
		
		cell_data[loc.y][loc.x] |= FLAG_MINE
		
	# compute number cells
	update_numbers()

	if DEBUG_SHOW_BOARD:
		show_board()
	
func load_save(save: Array):
	self.mines_remaining = save[save_manager.LoadSaveGameResult.MINES_REMAINING]
	self.time = save[save_manager.LoadSaveGameResult.TIME]
	assert(len(cell_data) and len(cell_data[0]))
	
	self.set_cell_data(save[save_manager.LoadSaveGameResult.CELL_DATA])
	set_window_size()
	

# Called when the node enters the scene tree for the first time.
func _ready():

	prepare_board()
	set_window_size()
	
	if save_manager.has_save_game():
		var save = save_manager.load_save_game()
		if (
			save[save_manager.LoadSaveGameResult.WORKED]
			and len(save[save_manager.LoadSaveGameResult.CELL_DATA])
			and len(save[save_manager.LoadSaveGameResult.CELL_DATA][0])
		):
			print("valid save detected, attempting to load...")
			load_save(save)
			self.change_game_state(GameState.GAME_RUNNING)
		
	
	$Window/MarginContainer/Bar/MineCounter.change_value.emit("%03d" % mines_remaining)
	$Window/MarginContainer/Bar/TimeBox.change_value.emit("000")
	$MarginContainer3/HBoxContainer/TitleBarDragZone.get_screen_position = self.get_screen_position
	

func get_cell_type(grid_loc: Vector2i):
	return $Grid.get_cell_atlas_coords(0, grid_loc)

func reset_game():
	"""Get the game back to the default/starting position, but not running"""
	time = 0
	$Timer.stop()
	$Window/MarginContainer/Bar/TimeBox.change_value.emit("%03d" % time)
	update_mine_count(total_mines)
	set_face(FACE_HAPPY)
	prepare_board()
	

func start_game():
	# for some reason it starts at one, so call this method to increment it
	_on_timer_timeout()
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (
			self.mouseover
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) 
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) 
			and Input.is_key_pressed(KEY_ESCAPE)
			and not $Timer.is_stopped()
		):
			# left and right click cheat
			print("enabling stopped clock cheat")
			$Timer.stop()
	if clicking:
		$Grid.clear_layer(1)
		var grid_loc = global2grid(self.get_global_mouse_position())
		if loc_in_grid(grid_loc):
			var clicked_cell_type = get_cell_type(grid_loc)
			var set_cell = func(type):
				$Grid.set_cell(1, grid_loc, 0, type, 0)
			
			if clicked_cell_type == BLANK:
				set_cell.call(EMPTY)
			elif clicked_cell_type == QUESTION:
				set_cell.call(QUESTION_PRESSED)
			

func _on_face_button_pressed():
	change_game_state(GameState.READY_TO_START)

func _on_timer_timeout():
	self.time = clampi(self.time + 1, 0, 999)
	
	if enable_sound:
		$Sound.stream = SOUND_CLOCK
		$Sound.play()
		
	$Window/MarginContainer/Bar/TimeBox.change_value.emit("%03d" % time)

func _on_menu_bar_new_game():
	change_game_state(GameState.READY_TO_START)

func _on_menu_bar_change_difficulty(width, height, num_mines):
	print("difficulty changed. width = %d height = %d num_mines = %d" % [width, height, num_mines])
	grid_width = width
	grid_height = height
	total_mines = num_mines
	$Grid.clear()
	set_window_size()
	change_game_state(GameState.READY_TO_START)
	
	$MenuBar/CustomModal/Height.text = str(height)
	$MenuBar/CustomModal/Width.text = str(width)
	$MenuBar/CustomModal/Mines.text = str(num_mines)
	

func _on_menu_bar_marks_enabled_changed(new_state):
	enable_marks = new_state

func _on_menu_bar_color_enabled_changed(new_state):
	# things that need to change:
	# - base 9patch
	# - face
	# - timer colors
	# - atlas for grid
	
	$Window/MarginContainer/Bar/MineCounter.set_color_mode(new_state)
	$Window/MarginContainer/Bar/TimeBox.set_color_mode(new_state)
	
	for face in [FACE_OOOOOO, FACE_HAPPY, FACE_DEAD, FACE_COOL, FACE_PRESSED]:
		face.atlas = self.FACE_COLOR_ATLAS if new_state else FACE_BW_ATLAS
	
	$Grid.tile_set = self.GRID_TILESET_COLOR if new_state else self.GRID_TILESET_BW
	
	$Window.texture = self.NINE_PATCH_COLOR if new_state else self.NINE_PATCH_BW

func _on_menu_bar_sound_enabled_changed(new_state):
	enable_sound = new_state

func _on_title_bar_drag_zone_update_window_position(pos: Vector2):
	self.set_global_position(pos)


func _on_mouse_entered():
	self.mouseover = true
	

func _on_mouse_exited():
	self.mouseover = false
