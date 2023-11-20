extends Control

class_name menu_bar

"""I don't know why I'm doing this but here we go!!"""

enum GameDifficulty {
	BEGINNER = 0,
	INTERMEDIATE = 1,
	EXPERT = 2,
	CUSTOM = 3
}

var marks_enabled = true
var sound_enabled = true
var color_enabled = true
var difficulty: GameDifficulty = self.GameDifficulty.BEGINNER

"""If right clicking to question marks are allowed"""
signal new_game
signal change_difficulty(width: int, height: int, num_mines: int)
signal marks_enabled_changed(new_state: bool)
signal sound_enabled_changed(new_state: bool)
signal color_enabled_changed(new_state: bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.update_difficulty(self.GameDifficulty.BEGINNER)
	
	$GameMenu/ColorButton.update_checked(self.color_enabled)
	self.color_enabled_changed.emit(self.color_enabled)
	
	$GameMenu/MarksButton.update_checked(self.marks_enabled)
	self.marks_enabled_changed.emit(self.marks_enabled)

	$GameMenu/SoundButton.update_checked(self.sound_enabled)
	self.sound_enabled_changed.emit(self.sound_enabled)
	

var menus_activated = false
"""If menus are activated, then we get special behavior, namely:
	
	1. Hovering over the other menu button will activate that menu & deactivate
	   this one
	2. Clicking anywhere else outside the menu will dismiss the menus """

func show_game_menu():
	self.menus_activated = true
	$ClickOutsideMenuDetectorHack.set_process(true)
	$ClickOutsideMenuDetectorHack.visible = true	
	$GameMenu.visible = true
	$HelpMenu.visible = false
	$GameButton.grab_focus()
	
func show_help_menu():
	self.menus_activated = true
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
	self.menus_activated = false
	$GameMenu.visible = false
	$HelpMenu.visible = false

func _on_game_button_button_down():
	if self.menus_activated:
		self.hide_menus()
		return
	self.show_game_menu()

func _on_help_button_button_down():
	if self.menus_activated:
		self.hide_menus()
		return
	return self.show_help_menu()

func _on_game_button_mouse_entered():
	if self.menus_activated:
		self.show_game_menu()

func _on_help_button_mouse_entered():
	if self.menus_activated:
		self.show_help_menu()

func _on_click_outside_menu_detector_hack_gui_input(event):
	if (event is InputEventMouseButton) and event.is_pressed() and self.menus_activated:
		self.hide_menus()


func _on_new_button_pressed():
	hide_menus()
	new_game.emit()

# very unhappy with the code below, but I got er done? maybe should have made
# a reusable menu entry component?

func update_difficulty(new_difficulty: GameDifficulty):
	self.difficulty = new_difficulty
	# this is gross and I hate it. maybe I should've figured out how to use the
	# built in radio group?
	match new_difficulty:
		GameDifficulty.BEGINNER:
			$GameMenu/BeginnerButton.update_checked(true)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(false)
			self.change_difficulty.emit(9, 9, 10)
			
		GameDifficulty.INTERMEDIATE:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(true)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(false)
			self.change_difficulty.emit(16, 16, 40)
			
		GameDifficulty.EXPERT:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(true)
			$GameMenu/CustomButton.update_checked(false)
			self.change_difficulty.emit(30, 16, 99)
			
		GameDifficulty.CUSTOM:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(true)

func _on_beginner_button_pressed():
	self.hide_menus()
	self.update_difficulty(self.GameDifficulty.BEGINNER)

func _on_intermediate_button_pressed():
	self.hide_menus()
	self.update_difficulty(self.GameDifficulty.INTERMEDIATE)


func _on_expert_button_pressed():
	self.hide_menus()
	self.update_difficulty(self.GameDifficulty.EXPERT)


func _on_custom_button_pressed():
	self.hide_menus()
	$CustomModal.visible = true

func _on_marks_button_pressed():
	self.hide_menus()
	self.marks_enabled = not self.marks_enabled
	self.marks_enabled_changed.emit(self.marks_enabled)
	$GameMenu/MarksButton.update_checked(self.marks_enabled)

func _on_color_button_pressed():
	self.hide_menus()
	self.color_enabled = not self.color_enabled
	self.color_enabled_changed.emit(self.color_enabled)
	$GameMenu/ColorButton.update_checked(self.color_enabled)

func _on_sound_button_pressed():
	self.hide_menus()
	self.sound_enabled = not self.sound_enabled
	self.sound_enabled_changed.emit(self.sound_enabled)
	$GameMenu/SoundButton.update_checked(self.sound_enabled)

func _on_custom_modal_change_difficulty(width: int, height: int, num_mines: int):
	self.update_difficulty(self.GameDifficulty.CUSTOM)
	self.change_difficulty.emit(width, height, num_mines)


func _on_best_times_button_pressed():
	self.hide_menus()
	$fastest_minesweepers.show_scores()
