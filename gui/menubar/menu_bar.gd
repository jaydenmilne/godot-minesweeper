extends Control

"""I don't know why I'm doing this but here we go!!"""

enum GameDifficulty {
	BEGINNER,
	INTERMEDIATE,
	EXPERT,
	CUSTOM
}

var marks_enabled = true
var sound_enabled = true
var color_enabled = true
"""If right clicking to question marks are allowed"""

signal new_game
signal change_difficulty(width: int, height: int, num_mines: int)
signal marks_enabled_changed(new_state: bool)
signal sound_enabled_changed(new_state: bool)
signal color_enabled_changed(new_state: bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	update_difficulty(GameDifficulty.BEGINNER)
	
	$GameMenu/ColorButton.update_checked(color_enabled)
	color_enabled_changed.emit(color_enabled)
	
	$GameMenu/MarksButton.update_checked(marks_enabled)
	marks_enabled_changed.emit(marks_enabled)

	$GameMenu/SoundButton.update_checked(sound_enabled)
	sound_enabled_changed.emit(sound_enabled)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var menus_activated = true
"""If menus are activated, then we get special behavior, namely:
	
	1. Hovering over the other menu button will activate that menu & deactivate
	   this one
	2. Clicking anywhere else outside the menu will dismiss the menus """

func show_game_menu():
	menus_activated = true
	$ClickOutsideMenuDetectorHack.set_process(true)
	$ClickOutsideMenuDetectorHack.visible = true	
	$GameMenu.visible = true
	$HelpMenu.visible = false
	$GameButton.grab_focus()
	
func show_help_menu():
	menus_activated = true
	$ClickOutsideMenuDetectorHack.set_process(true)
	$ClickOutsideMenuDetectorHack.visible = true
	$HelpMenu.visible = true
	$GameMenu.visible = false
	$HelpButton.grab_focus()

func hide_menus():
	$ClickOutsideMenuDetectorHack.set_process(false)
	$ClickOutsideMenuDetectorHack.visible = false
	$GameButton.release_focus()
	$HelpButton.release_focus()
	menus_activated = false
	$GameMenu.visible = false
	$HelpMenu.visible = false

func _on_game_button_button_down():
	if menus_activated:
		hide_menus()
		return
	show_game_menu()

func _on_help_button_button_down():
	if menus_activated:
		hide_menus()
		return
	return	show_help_menu()

func _on_game_button_mouse_entered():
	if menus_activated:
		show_game_menu()

func _on_help_button_mouse_entered():
	if menus_activated:
		show_help_menu()

func _on_click_outside_menu_detector_hack_gui_input(event):
	if (event is InputEventMouseButton) and event.is_pressed() and menus_activated:
		hide_menus()


func _on_new_button_pressed():
	hide_menus()
	new_game.emit()

# very unhappy with the code below, but I got er done? maybe should have made
# a reusable menu entry component?

func update_difficulty(new_difficulty: GameDifficulty):
	# this is gross and I hate it. maybe I should've figured out how to use the
	# built in radio group?
	match new_difficulty:
		GameDifficulty.BEGINNER:
			$GameMenu/BeginnerButton.update_checked(true)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(false)
			change_difficulty.emit(9, 9, 10)
			
		GameDifficulty.INTERMEDIATE:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(true)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(false)
			change_difficulty.emit(16, 16, 40)
			
		GameDifficulty.EXPERT:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(true)
			$GameMenu/CustomButton.update_checked(false)
			change_difficulty.emit(30, 16, 99)
			
		GameDifficulty.CUSTOM:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(true)
			change_difficulty.emit(4, 4, 1)
			


func _on_beginner_button_pressed():
	hide_menus()
	update_difficulty(GameDifficulty.BEGINNER)

func _on_intermediate_button_pressed():
	hide_menus()
	update_difficulty(GameDifficulty.INTERMEDIATE)


func _on_expert_button_pressed():
	hide_menus()
	update_difficulty(GameDifficulty.EXPERT)


func _on_custom_button_pressed():
	hide_menus()
	update_difficulty(GameDifficulty.CUSTOM)
	# todo: dialog and stuff

func _on_marks_button_pressed():
	hide_menus()
	marks_enabled = not marks_enabled
	marks_enabled_changed.emit(marks_enabled)
	$GameMenu/MarksButton.update_checked(marks_enabled)

func _on_color_button_pressed():
	hide_menus()
	color_enabled = not color_enabled
	color_enabled_changed.emit(color_enabled)
	$GameMenu/ColorButton.update_checked(color_enabled)

func _on_sound_button_pressed():
	hide_menus()
	sound_enabled = not sound_enabled
	sound_enabled_changed.emit(sound_enabled)
	$GameMenu/SoundButton.update_checked(sound_enabled)

