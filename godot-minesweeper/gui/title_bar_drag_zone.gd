extends Control

var dragpoint = null
signal update_window_position(pos: Vector2)

var get_screen_position = func() -> Vector2: 
	assert(false, "You need to override this")
	return Vector2()


func _on_title_bar_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			self.dragpoint = self.get_global_mouse_position() - get_screen_position.call()
		else:
			dragpoint = null
	
	if event is InputEventMouseMotion and dragpoint != null:
		self.update_window_position.emit(self.get_global_mouse_position() - dragpoint)
