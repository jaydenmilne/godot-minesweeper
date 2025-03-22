extends Control


func comma_sep(number: int) -> String:
	"""really godot"""
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res
	
func _ready():
	$TitleBarDragZone.get_screen_position = self.get_screen_position
	
	var memory_kb = OS.get_memory_info()['physical'] / 1024
	
	# in web browser this returns 0
	if memory_kb != 0:
		$FreeMemory.text = "Physical memory available to Godot: %s KB" % comma_sep(memory_kb)
	else:
		memory_kb = OS.get_static_memory_usage() / 1024
		
		$FreeMemory.text = "Physical memory used by Godot: %s KB" % comma_sep(memory_kb)

func _on_title_bar_drag_zone_update_window_position(pos):
	self.set_global_position(pos)

func _on_ok_pressed():
	self.hide()

func _on_source_code_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			OS.shell_open("https://github.com/jaydenmilne/godot-minesweeper")

func _on_font_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			OS.shell_open("https://web.archive.org/web/20230326165147/https://w95font.com/")


func _on_license_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			OS.shell_open("https://github.com/jaydenmilne/godot-minesweeper/blob/main/LICENSE")
