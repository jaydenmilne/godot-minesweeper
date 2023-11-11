extends Control

# state variables
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
	READY_TO_START, # kind of a weird state, there is game board and stuff, but the clock is not running
	GAME_RUNNING,
	GAME_OVER_LOST,
	GAME_OVER_WON
}

func set_window_size():
	"""Resize the 9patch to match the grid size. This could probably be done with no code if I was
	smarter with godot layout stuff"""
	
	# magic numbers!
	# 
	var top_height = 96
	var left_margin = 15
	var right_margin = 11
	var bottom_margin =  11
	
	var grid_cell_size = 16
	
	var width = left_margin + right_margin + grid_cell_size * grid_width
	var height = top_height + bottom_margin	+ grid_cell_size * grid_height
	
	$Window.set_size(Vector2i(width, height))
	
func set_face(res: Resource):
	$Window/MarginContainer/Bar/FaceButtonFrame/FaceButton.texture_normal = res

func change_game_state(new_state: GameState):
	print("changing state %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
	var game_over_lost = func():
		$Timer.stop()
		set_face(FACE_DEAD)
		show_board()
	
	var game_over_won = func():
		$Timer.stop()
		set_face(FACE_COOL)
	
	match current_state:
		GameState.READY_TO_START:
			match new_state:
				GameState.GAME_RUNNING:
					start_game()
				GameState.GAME_OVER_LOST:
					# unlucky lol
					game_over_lost.call()
				GameState.READY_TO_START:
					reset_game()
				_:
					assert(false, "unexpected transition NEW_WINDOW -> %s" % GameState.keys()[new_state])
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
					game_over_lost.call()
				_:
					assert(false, "unexpected transition GAME_RUNNING -> %s" % GameState.keys()[new_state])
		GameState.GAME_OVER_LOST, GameState.GAME_OVER_WON:
			match new_state:
				GameState.GAME_RUNNING:
					assert(false, "I guess this is used after all")
					update_mine_count(total_mines)
					start_game()
				GameState.READY_TO_START:
					update_mine_count(total_mines)
					start_game()
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

func right_click_cell(location: Vector2i):
	var type = get_cell_type(location)
	print(cell_data[location.y][location.x])
	
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
	print(cell_data[location.y][location.x])
	

func click_cell(location: Vector2i) -> void:
	print(location)
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
			if event.pressed:
				# always set face to shocked, the game does this for some reason
				# TODO: not if its in the menu bar
				set_face(FACE_OOOOOO)
				clicking = true
			else:
				# mouseup
				var click_grid_location = global2grid(event.position)
				if loc_in_grid(click_grid_location):
					if clicking and current_state == GameState.READY_TO_START:
						change_game_state(GameState.GAME_RUNNING)
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
			var location = global2grid(event.position)
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

	print(len(cell_data), len(cell_data[0]))
	var rng = RandomNumberGenerator.new()
	rng.seed = 420
	
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
	print(len(cell_data), len(cell_data[0]))
	for y in range(grid_height):
		for x in range(grid_width):
			if not(cell_data[y][x] & FLAG_MINE):
				assert(cell_data[y][x] & NUMBER_MASK == 0)
				var mine_count = get_number.call(x, y)
				assert(mine_count < 9)
				cell_data[y][x] |= mine_count

	if DEBUG_SHOW_BOARD:
		show_board()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$Window/MarginContainer/Bar/MineCounter.change_value.emit("%03d" % mines_remaining)
	$Window/MarginContainer/Bar/TimeBox.change_value.emit("000")
	
	prepare_board()
	set_window_size()

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
	reset_game()
	# for some reason it starts at one, so call this method to increment it
	_on_timer_timeout()
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if clicking:
		$Grid.clear_layer(1)
		var grid_loc = global2grid(get_viewport().get_mouse_position())
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
	time = clampi(time + 1, 0, 999)
	# TODO: Play sound
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

func _on_menu_bar_marks_enabled_changed(new_state):
	enable_marks = new_state

func _on_menu_bar_color_enabled_changed(new_state):
	enable_color = new_state

func _on_menu_bar_sound_enabled_changed(new_state):
	enable_sound = new_state
