extends TextureButton

var x: int = -1
var y: int = -1

const x_offset: int = 15
const y_offset: int = 96

signal grid_down(x, y)
signal grid_up(x, y)
signal grid_pressed(x, y)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func init(x: int, y: int):
	self.global_position = Vector2(x_offset + x * 16, y_offset + y * 16)


func _on_button_down():
	grid_down.emit(x, y)


func _on_button_up():
	grid_up.emit(x, y)


func _on_pressed():
	grid_pressed.emit(x, y)
