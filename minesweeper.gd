extends Node2D

var time: int = 0
var mines_remaining: int = 10

var grid_width: int = 9
var grid_height: int = 9
var total_mines: int = 10

# atlas indexes
const BLANK = Vector2i(0, 0)
const FLAG = Vector2i(0, 1)
const QUESTION = Vector2i(0, 2)
const MINE_HIT = Vector2i(0, 3)
const NOT_MINE = Vector2i(0, 4)
const MINE = Vector2i(0, 5)
const QUESTION_PRESSED = Vector2i(0, 6)
const EMPTY = Vector2i(0, 15)

enum GameState {
	# kind of a weird state, there is game board and stuff, but the clock is not running
	NEW_GAME, 
	GAME_RUNNING,
	GAME_OVER_LOST,
	GAME_OVER_WON
}

var current_state: GameState = GameState.NEW_GAME

func change_game_state(new_state: GameState):
	print("changing state %s -> %s" % [GameState.keys()[current_state], GameState.keys()[new_state]])
	var game_over = func():
		$Timer.stop()
		$Bar/FaceButton.texture_normal = FACE_DEAD
		show_board()
	
	
	match current_state:
		GameState.NEW_GAME:
			match new_state:
				GameState.GAME_RUNNING:
					start_game()
				GameState.GAME_OVER_LOST:
					# unlucky lol
					game_over.call()
				_:
					assert(false, "unexpected transition NEW_WINDOW -> %s" % GameState.keys()[new_state])
		GameState.GAME_RUNNING:
			match new_state:
				GameState.GAME_OVER_LOST:
					game_over.call()
				GameState.GAME_RUNNING:
					# restart
					update_mine_count(total_mines)
					start_game()
				_:
					assert(false, "unexpected transition GAME_RUNNING -> %s" % GameState.keys()[new_state])
		GameState.GAME_OVER_LOST, GameState.GAME_OVER_WON:
			match new_state:
				GameState.GAME_RUNNING:	
					update_mine_count(total_mines)
					start_game()
				_:
					assert(false, "you forgot to handle state %s" % GameState.keys()[current_state])
		_:
			assert(false, "you forgot to handle state %s" % GameState.keys()[current_state])
	current_state = new_state
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

var clicking = false

var cell_data = []

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

const NUMBER_MASK = 15
const FLAG_MINE = 16
const FLAG_FLAG = 32
const FLAG_QUESTION = 64
const FLAG_REVEALED = 128

func update_mine_count(new_count: int) -> void:
	mines_remaining = new_count
	var value = "%03d" % mines_remaining
	if mines_remaining < 0:
		value[0] = "-"
	$Bar/MineCounter.change_value.emit(value)

func right_click_cell(location: Vector2i):
	var type = get_cell_type(location)
	print(cell_data[location.y][location.x])
	
	if type == BLANK:
		$Grid.set_cell(0, location, 0, FLAG, 0)
		cell_data[location.y][location.x] |= FLAG_FLAG
		update_mine_count(mines_remaining - 1)
	elif type == FLAG:
		update_mine_count(mines_remaining + 1)		
		cell_data[location.y][location.x] &= ~FLAG_FLAG
		cell_data[location.y][location.x] |= FLAG_QUESTION
		$Grid.set_cell(0, location, 0, QUESTION, 0)
	elif type == QUESTION:
		cell_data[location.y][location.x] &= ~FLAG_QUESTION
		$Grid.set_cell(0, location, 0, BLANK, 0)
	print(cell_data[location.y][location.x])
	

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
		
func _unhandled_input(event) -> void:
	if event is InputEventMouseButton:
		if current_state not in [GameState.GAME_RUNNING, GameState.NEW_GAME]:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# always set face to shocked, the game does this for some reason
				# TODO: not if its in the menu bar
				$Bar/FaceButton.texture_normal = FACE_OOOOOO
				clicking = true
			else:
				# mouseup
				var click_grid_location = global2grid(event.position)
				if loc_in_grid(click_grid_location):
					if clicking and current_state == GameState.NEW_GAME:
						change_game_state(GameState.GAME_RUNNING)
					click_cell(click_grid_location)
				clicking = false
				$Grid.clear_layer(1)
				var face_texture = FACE_HAPPY
				if current_state == GameState.GAME_OVER_LOST:
					face_texture = FACE_DEAD
				elif current_state == GameState.GAME_OVER_WON:
					face_texture = FACE_COOL
					
				$Bar/FaceButton.texture_normal = face_texture
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var location = global2grid(event.position)
			if loc_in_grid(location):
				right_click_cell(location)


const DEBUG_SHOW_BOARD = false

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
			#elif number_val != 0:
			#	$Grid.set_cell(0, Vector2i(x, y), 0, NUMBER_LOOKUP[number_val], 0)
				

func prepare_board() -> void:
	cell_data = []
	
	# set visible area
	
	for x in range(grid_width):
		var new_row = []
		new_row.resize(grid_height)
		new_row.fill(0)
		cell_data.append(new_row)
		for y in range(grid_height):
			$Grid.set_cell(0, Vector2i(x, y), 0, BLANK, 0)

	var rng = RandomNumberGenerator.new()
	rng.seed = 420
	
	# place mines
	
	for x in range(total_mines):
		var get_random_cell = func():
			var x1 = rng.randi_range(0, grid_width - 1)
			var y1 = rng.randi_range(0, grid_height - 1)
			return Vector2i(x1, y1)
			
		var loc = get_random_cell.call()
		
		while cell_data[loc.x][loc.y] & FLAG_MINE:
			loc = get_random_cell.call()
		
		cell_data[loc.x][loc.y] |= FLAG_MINE
		
	# compute number cells
	
	var get_number = func(x: int, y: int) -> int:
		"""Count the number of adjacent mines at x,y"""
		var sum = 0
		for i in range(x - 1, x + 2):
			if i < 0 or i >= grid_width:
				continue
			for j in range(y - 1, y + 2):
				if j < 0 or j >= grid_width:
					continue
				if cell_data[j][i] & FLAG_MINE:
					sum += 1
		return sum

	for x in range(grid_height):
		for y in range(grid_width):
			if not(cell_data[y][x] & FLAG_MINE):
				assert(cell_data[y][x] & NUMBER_MASK == 0)
				var mine_count = get_number.call(x, y)
				assert(mine_count < 9)
				cell_data[y][x] |= mine_count

	if DEBUG_SHOW_BOARD:
		show_board()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	$Bar/MineCounter.change_value.emit("%03d" % mines_remaining)
	$Bar/TimeBox.change_value.emit("000")
	
	prepare_board()

func get_cell_type(grid_loc: Vector2i):
	return $Grid.get_cell_atlas_coords(0, grid_loc)

func start_game():
	time = 0
	$Bar/TimeBox.change_value.emit("000")
	$Bar/FaceButton.texture_normal = FACE_HAPPY
	$Timer.start()
	prepare_board()


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
	change_game_state(GameState.NEW_GAME)

func _on_timer_timeout():
	time = clampi(time + 1, 0, 999)
	# TODO: Play sound
	$Bar/TimeBox.change_value.emit("%03d" % time)

const FACE_OOOOOO = preload("res://bitmap/face/face_shocked.tres")
const FACE_HAPPY = preload("res://bitmap/face/face_happy.tres")
const FACE_DEAD = preload("res://bitmap/face/face_dead.tres")
const FACE_COOL = preload("res://bitmap/face/face_cool.tres")
