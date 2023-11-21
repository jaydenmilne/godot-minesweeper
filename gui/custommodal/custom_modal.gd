extends Control

signal change_difficulty(width: int, height: int, num_mines: int)

var max_width = 30
var max_height = 24
var fully_unlimited = false

func _ready():
	$TitleBarDragZone.get_screen_position = self.get_screen_position

func _on_ok_pressed():
	self.visible = false
	
	var width = clampi(int($Width.text), 9, self.max_width)
	var height = clampi(int($Height.text), 9, self.max_height)
	
	var max_mines = (width - 1) * (height - 1)
	if self.fully_unlimited:
		max_mines = width * height
	
	var num_mines = clampi(int($Mines.text), 10, max_mines)

	# reset values in case they got CLAMPED.jpeg
	$Width.text = str(width)
	$Height.text = str(height)
	$Mines.text = str(num_mines)
	
	self.change_difficulty.emit(width, height, num_mines)


func _on_cancel_pressed():
	self.visible = false


func _on_question_pressed():
	$AcceptDialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	$AcceptDialog.visible = true
	self.max_height = 99999
	self.max_width = 99999
	self.fully_unlimited = true

const ANGRY_DING: Resource = preload("res://gui/custommodal/ding.wav")

func _on_another_dirty_focus_hack_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# blink and ding angrily
		$AnimationPlayer.stop()
		$AnimationPlayer.play('blink')
		
		$Sound.stream = self.ANGRY_DING
		$Sound.play()

func _on_title_bar_drag_zone_update_window_position(pos):
	self.set_global_position(pos)
