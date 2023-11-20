extends Control


const DING: Resource = preload("res://gui/custommodal/ding.wav")

func _ready():
	$TitleBarDragZone.get_screen_position = self.get_screen_position

func show_scores():
	var save_manager = self.get_node("/root/SaveManager")
	var highscores = save_manager.load_highscores()
	self.show()
	
	$BeginnerTime.text = "%d seconds" % highscores[menu_bar.GameDifficulty.find_key(menu_bar.GameDifficulty.BEGINNER)]["time"]
	$BeginnerName.text = highscores[menu_bar.GameDifficulty.keys()[menu_bar.GameDifficulty.BEGINNER]]["name"]

	$IntermediateTime.text = "%d seconds" % highscores[menu_bar.GameDifficulty.keys()[menu_bar.GameDifficulty.INTERMEDIATE]]["time"]
	$IntermediateName.text = highscores[menu_bar.GameDifficulty.keys()[menu_bar.GameDifficulty.INTERMEDIATE]]["name"]

	$ExpertTime.text = "%d seconds" % highscores[menu_bar.GameDifficulty.keys()[menu_bar.GameDifficulty.EXPERT]]["time"]
	$ExpertName.text = highscores[menu_bar.GameDifficulty.keys()[menu_bar.GameDifficulty.EXPERT]]["name"]


func _on_question_pressed():
	$NoEasterEggs.visible = true


func _on_ok_pressed():
	self.hide()


func _on_reset_scores_pressed():
	var save_manager = self.get_node("/root/SaveManager")
	save_manager.save_highscores(save_manager.DEFAULT_HIGHSCORES)
	self.show_scores()


func _on_title_bar_drag_zone_update_window_position(pos):
	self.set_global_position(pos)


func _on_focus_hack_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# blink and ding angrily
		$AnimationPlayer.stop()
		$AnimationPlayer.play('blink')
		
		# ding angrily
		$Sound.stream = DING
		$Sound.play()

