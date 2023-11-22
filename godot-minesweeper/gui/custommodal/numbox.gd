extends LineEdit


var regex = RegEx.new()
var old_text: String = ""


func _ready() -> void:
	regex.compile("^[0-9.]*$")

func _on_gui_input(event: InputEvent):
	if event is InputEventKey:
		var code = event.get_unicode()
		if code == 0:
			return
		if code < '0'.unicode_at(0) or code > '9'.unicode_at(0):
			self.accept_event()
