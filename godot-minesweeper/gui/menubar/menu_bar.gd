extends Control

class_name menu_bar

"""I don't know why I'm doing this but here we go!!"""

enum GameDifficulty {
	BEGINNER = 0,
	INTERMEDIATE = 1,
	EXPERT = 2,
	CUSTOM = 3
}

var marks_enabled = false
var sound_enabled = false
var color_enabled = false
var difficulty: GameDifficulty = self.GameDifficulty.BEGINNER
var num_mines: int = 0
var width: int = 0
var height: int =0

"""If right clicking to question marks are allowed"""
signal new_game
signal change_difficulty(width: int, height: int, num_mines: int)
signal marks_enabled_changed(new_state: bool)
signal sound_enabled_changed(new_state: bool)
signal color_enabled_changed(new_state: bool)

# Called when the node enters the scene tree for the first time.
func _ready():
	# load saved options
	var options = save_manager.load_options()
	
	print("loading options", options)
	
	self.color_enabled = options[save_manager.GameOptions.find_key(save_manager.GameOptions.ENABLE_COLOR)]
	self.marks_enabled = options[save_manager.GameOptions.find_key(save_manager.GameOptions.ENABLE_MARKS)]
	self.sound_enabled = options[save_manager.GameOptions.find_key(save_manager.GameOptions.ENABLE_SOUND)]
	
	self.change_difficulty_helper(
		options[save_manager.GameOptions.find_key(save_manager.GameOptions.WIDTH)],
		options[save_manager.GameOptions.find_key(save_manager.GameOptions.HEIGHT)],
		options[save_manager.GameOptions.find_key(save_manager.GameOptions.NUM_MINES)]
	)
	
	# update the checks
	self.update_difficulty(
		self.GameDifficulty[
			options[
				save_manager.GameOptions.find_key(save_manager.GameOptions.DIFFICULTY)
			]
		]
	)
	
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
			self.change_difficulty_helper(9, 9, 10)
			
		GameDifficulty.INTERMEDIATE:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(true)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(false)
			self.change_difficulty_helper(16, 16, 40)
			
		GameDifficulty.EXPERT:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(true)
			$GameMenu/CustomButton.update_checked(false)
			self.change_difficulty_helper(30, 16, 99)
			
		GameDifficulty.CUSTOM:
			$GameMenu/BeginnerButton.update_checked(false)
			$GameMenu/IntermediateButton.update_checked(false)
			$GameMenu/ExpertButton.update_checked(false)
			$GameMenu/CustomButton.update_checked(true)
	self.save_options()
	
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

func change_difficulty_helper(width: int, height: int, num_mines: int):
	self.width = width
	self.height = height
	self.num_mines = num_mines
	
	self.change_difficulty.emit(width, height, num_mines)

func save_options():
	save_manager.save_options(
		self.color_enabled, 
		self.marks_enabled,
		self.sound_enabled,
		self.difficulty,
		self.width,
		self.height,
		self.num_mines
	)
	

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
	self.save_options()

func _on_sound_button_pressed():
	self.hide_menus()
	self.sound_enabled = not self.sound_enabled
	self.sound_enabled_changed.emit(self.sound_enabled)
	$GameMenu/SoundButton.update_checked(self.sound_enabled)
	self.save_options()
	

func _on_custom_modal_change_difficulty(width: int, height: int, num_mines: int):
	self.change_difficulty_helper(width, height, num_mines)
	self.update_difficulty(self.GameDifficulty.CUSTOM)


func _on_best_times_button_pressed():
	self.hide_menus()
	$fastest_minesweepers.show_scores()


func _on_show_help():
	self.hide_menus()
	$HelpModal.show()

func _on_about_minesweeper_pressed():
	self.hide_menus()
	$AboutDialog.show()


func _on_exit_button_pressed():
	self.get_tree().quit()
