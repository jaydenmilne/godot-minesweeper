extends Control

var scale_index = 2

const SCALE_FACTORS = [0.25, 0.5, 1, 2, 3, 4, 6]

func _on_magnifier_pressed():
	scale_index += 1
	scale_index = scale_index % len(SCALE_FACTORS)
	get_tree().root.content_scale_factor = SCALE_FACTORS[scale_index]

# XYZZY shift+enter

const pixel_cheat = [KEY_X, KEY_Y, KEY_Z, KEY_Z, KEY_Y]
var cheat_index = 0

func _unhandled_key_input(event):
	if event.pressed:
		if cheat_index == len(pixel_cheat):
			if event.keycode == KEY_SHIFT:
				return # ignore these
			if event.shift_pressed and event.keycode == KEY_ENTER:
				print("enabling secret pixel cheat")
				cheat_index = 0
				$CheatPixel.show()
				return
		
		if event.keycode == pixel_cheat[cheat_index]:
			cheat_index += 1
		else:
			cheat_index = 0

const WHITE = Color('white')
const BLACK = Color('black')

func _process(_delta):
	var click_grid_location = $Minesweeper.global2grid(self.get_global_mouse_position())
	if $Minesweeper.loc_in_grid(click_grid_location):
		var cell = $Minesweeper.cell_data[click_grid_location.y][click_grid_location.x]
		if cell & $Minesweeper.FLAG_MINE:
			$CheatPixel.color = BLACK
			return
	$CheatPixel.color = WHITE
	
