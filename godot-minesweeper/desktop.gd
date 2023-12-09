extends Control

var scale_index = 2

const SCALE_FACTORS = [0.25, 0.5, 1, 2, 3, 4, 6]
var callback_handle = null
var pixel_ratio = 1.0

func on_update_pixel_ratio(arr):
	# install custom scaling logic
	pixel_ratio = JavaScriptBridge.eval("window.devicePixelRatio")
	print("window.devicePixelRatio is `%f`" % pixel_ratio)
	scale_index = clampi(ceili(pixel_ratio) + 1, 0, len(SCALE_FACTORS) - 1)
	var scale = SCALE_FACTORS[scale_index]
	set_custom_scale(scale)

func _enter_tree():
	if OS.get_name() == "Web":
		# install some javascript stuff to make sure we adjust the DPI correctly on high dpi
		# displays
		callback_handle = JavaScriptBridge.create_callback(on_update_pixel_ratio)
		
		JavaScriptBridge.eval("""
// stolen without shame from MDN
let remove = null;

window.on_size_cllback = () => console.log("didn't work :(");
window.cllback_setter = {
	seter: (cllback) => window.on_size_cllback = cllback
};

const updatePixelRatio = () => {
  if (remove != null) {
	remove();
  }
  const mqString = `(resolution: ${window.devicePixelRatio}dppx)`;
  const media = matchMedia(mqString);
  media.addEventListener("change", updatePixelRatio);
  remove = () => {
	media.removeEventListener("change", updatePixelRatio);
  };

  window.on_size_cllback()
};

updatePixelRatio();

	""")
		JavaScriptBridge.get_interface("window").on_size_cllback = callback_handle
		on_update_pixel_ratio([])
		
func set_custom_scale(scale: float):
	get_tree().root.content_scale_factor = scale
	print("scale set to `%f`" % scale)
	$VBoxContainer/HBoxContainer/Magnifier.custom_minimum_size = Vector2i((25 / scale) * pixel_ratio, (22 / scale) * pixel_ratio)

func _on_magnifier_pressed():
	scale_index += 1
	scale_index = scale_index % len(SCALE_FACTORS)
	set_custom_scale(SCALE_FACTORS[scale_index])

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
	if $CheatPixel.visible:
		var click_grid_location = $Minesweeper.global2grid(self.get_global_mouse_position())
		if $Minesweeper.loc_in_grid(click_grid_location):
			var cell = $Minesweeper.cell_data[click_grid_location.y][click_grid_location.x]
			if cell & $Minesweeper.FLAG_MINE:
				$CheatPixel.color = BLACK
				return
		$CheatPixel.color = WHITE
	
