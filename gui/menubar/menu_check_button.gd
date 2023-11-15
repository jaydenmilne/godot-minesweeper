extends TextureButton


var checked = false
var hovering = false

const check: Resource = preload("res://gui/menubar/check_normal.png")
const hover: Resource = preload("res://gui/menubar/check_hover.png")

func update_checked(new_checked: bool):
	self.checked = new_checked
	if self.checked:
		if self.hovering:
			$check.texture = self.hover
		else:
			$check.texture = self.check
	else:
		$check.texture = null 

func on_mouseenter():
	self.hovering = true
	update_checked(self.checked)

func on_mouseleave():
	self.hovering = false
	update_checked(self.checked)

func _on_visibility_changed():
	if self.visible:
		self.hovering = false
		update_checked(self.checked)
