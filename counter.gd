extends TextureRect

signal change_value(value: String)

func set_value(value: String):
	assert(len(value) == 3, "this is supposed to be 3 chars long dum dum")
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


# Called when the node enters the scene tree for the first time.
func _ready():
	set_value("9- ")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_change_value(value: String):
	set_value(value)
