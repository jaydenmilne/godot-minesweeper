extends TextureRect

signal change_value(value: String)

func set_value(value: String):
	$First.texture = lookup[value[0]]
	$Second.texture = lookup[value[1]]
	$Third.texture = lookup[value[2]]


var lookup = {
	"0": load("res://bitmap/numbers/0.tres"),
	"1": load("res://bitmap/numbers/1.tres"),
	"2": load("res://bitmap/numbers/2.tres"),
	"3": load("res://bitmap/numbers/3.tres"),
	"4": load("res://bitmap/numbers/4.tres"),
	"5": load("res://bitmap/numbers/5.tres"),
	"6": load("res://bitmap/numbers/6.tres"),
	"7": load("res://bitmap/numbers/7.tres"),
	"8": load("res://bitmap/numbers/8.tres"),
	"9": load("res://bitmap/numbers/9.tres"),
	" ": load("res://bitmap/numbers/blank.tres"),
	"-": load("res://bitmap/numbers/dash.tres"),
}

var color_atlas: Resource = load("res://bitmap/color_numbers_texture.tres")
var bw_atlas: Resource = load("res://bitmap/bw_numbers_texture.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.set_value("9- ")


func _on_change_value(value: String):
	self.set_value(value)
	
func set_color_mode(color: bool):
	var number_atlas = color_atlas if color else bw_atlas

	for atlas_texture in lookup.values():
		atlas_texture.atlas = number_atlas
