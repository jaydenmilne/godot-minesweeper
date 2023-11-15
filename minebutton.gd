extends TextureButton

var x: int = -1
var y: int = -1

const x_offset: int = 15
const y_offset: int = 96

signal grid_down(x, y)
signal grid_up(x, y)
signal grid_pressed(x, y)


func init(x: int, y: int):
	self.global_position = Vector2(self.x_offset + x * 16, self.y_offset + y * 16)


func _on_button_down():
	self.grid_down.emit(x, y)


func _on_button_up():
	self.grid_up.emit(x, y)


func _on_pressed():
	self.grid_pressed.emit(x, y)
