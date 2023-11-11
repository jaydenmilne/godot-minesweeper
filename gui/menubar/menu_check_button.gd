extends TextureButton


var checked = false
var hovering = false

const check: Resource = preload("res://gui/menubar/check_normal.png")
const hover: Resource = preload("res://gui/menubar/check_hover.png")

func update_checked(new_checked: bool):
	checked = new_checked
	if checked:
		if hovering:
			$check.texture = hover
		else:
			$check.texture = check
	else:
		$check.texture = null 

func on_mouseenter():
	hovering = true
	update_checked(checked)

func on_mouseleave():
	hovering = false
	update_checked(checked)

func _on_visibility_changed():
	if visible:
		hovering = false
		update_checked(checked)
