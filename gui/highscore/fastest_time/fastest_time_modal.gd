extends Control

const beginner = preload("res://gui/highscore/fastest_time/fastest_time.png")
const intermediate = preload("res://gui/highscore/fastest_time/fastest_time_intermediate.png")
const expert = preload("res://gui/highscore/fastest_time/fastest_time_expert.png")

signal player_name(name: String)

const DING: Resource = preload("res://gui/custommodal/ding.wav")

func show_modal(difficulty: menu_bar.GameDifficulty):
	match difficulty:
		menu_bar.GameDifficulty.BEGINNER:
			$ModalBody.texture = beginner
		menu_bar.GameDifficulty.INTERMEDIATE:
			$ModalBody.texture = intermediate
		menu_bar.GameDifficulty.EXPERT:
			$ModalBody.texture = expert
		_:
			assert(false, "unknown difficulty: %v" % menu_bar.GameDifficulty.keys()[difficulty])

	self.visible = true

func _on_ok_pressed():
	self.player_name.emit($NameInput.text)
	self.visible = false


func _on_why_do_i_keep_doing_this_dirty_hack_gui_input(event):
	if event is InputEventMouseButton and event.pressed and not $Sound.playing:
		# ding angrily
		$Sound.stream = DING
		$Sound.play()

