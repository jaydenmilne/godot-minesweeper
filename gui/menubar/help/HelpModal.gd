extends Control


func _ready():
	$TitleBarDragZone.get_screen_position = self.get_screen_position
	
func _on_title_bar_drag_zone_update_window_position(pos):
	self.set_global_position(pos)


func _on_x_pressed():
	self.hide()


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			$WhatElseDoYouWant.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
			$WhatElseDoYouWant.show()
