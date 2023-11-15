extends Control

var scale_index = 2
const SCALE_FACTORS = [0.25, 0.5, 1, 2, 3, 4, 6]

func _on_magnifier_pressed():
	scale_index += 1
	scale_index = scale_index % len(SCALE_FACTORS)
	get_tree().root.content_scale_factor = SCALE_FACTORS[scale_index]
