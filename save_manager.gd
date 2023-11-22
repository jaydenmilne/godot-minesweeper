extends Node
class_name save_manager

var DEFAULT_HIGHSCORES = {
	menu_bar.GameDifficulty.keys()[(menu_bar.GameDifficulty.BEGINNER)]: {
		"time": 999,
		"name": "Anonymous"
	},
	menu_bar.GameDifficulty.keys()[(menu_bar.GameDifficulty.INTERMEDIATE)]: {
		"time": 999,
		"name": "Anonymous"
	},
	menu_bar.GameDifficulty.keys()[(menu_bar.GameDifficulty.EXPERT)]: {
		"time": 999,
		"name": "Anonymous"
	}
}
const HIGHSCORES_FILE = "user://highscores.json"

func save_highscores(highscores: Dictionary):
	var highscores_text = JSON.stringify(highscores)
		
	var file = FileAccess.open(HIGHSCORES_FILE, FileAccess.WRITE)
	file.store_string(highscores_text)
	file = null

func load_highscores() -> Dictionary:
	var json = JSON.new()
	
	if not FileAccess.file_exists(self.HIGHSCORES_FILE):
		# create them
		save_highscores(self.DEFAULT_HIGHSCORES)
		
	assert(FileAccess.file_exists(self.HIGHSCORES_FILE), "highscores file doesn't exist but we probably tried to make it???")
	var highscores = FileAccess.open(HIGHSCORES_FILE, FileAccess.READ).get_as_text()
	var err = json.parse(highscores)
	
	if err:
		print("failed to parse json! %s", json.get_error_message())
		return DEFAULT_HIGHSCORES
	
	return json.data

func has_high_score(score: int, difficulty: menu_bar.GameDifficulty) -> bool:
	if difficulty == menu_bar.GameDifficulty.CUSTOM:
		return false
	var high_scores = load_highscores()
	var difficulty_name: String = menu_bar.GameDifficulty.keys()[difficulty]
	return high_scores[difficulty_name]["time"] > score

func store_score(score: int, difficulty: menu_bar.GameDifficulty, name: String):
	var high_scores = load_highscores()
	var difficulty_name: String = menu_bar.GameDifficulty.keys()[difficulty]
	
	print("storing score `%d` for name `%s` on difficulty `%s`" % [score, name, difficulty_name])
	high_scores[difficulty_name] = {
		"time": score,
		"name": name,
	}
	
	self.save_highscores(high_scores)

enum GameOptions {
	ENABLE_MARKS = 1,
	ENABLE_SOUND = 2,
	ENABLE_COLOR = 3,
	DIFFICULTY = 4,
	NUM_MINES = 5,
	WIDTH = 6,
	HEIGHT = 7
}

const OPTIONS_FILE = "user://options.json"

static func load_options() -> Dictionary:
	var json = JSON.new()
	if not FileAccess.file_exists(OPTIONS_FILE):
		# create them
		save_options(true, true, true, menu_bar.GameDifficulty.BEGINNER, 9, 9, 10)
		
	assert(FileAccess.file_exists(OPTIONS_FILE), "options file doesn't exist but we probably tried to make it???")
	var options = FileAccess.open(OPTIONS_FILE, FileAccess.READ).get_as_text()
	var err = json.parse(options)
	print(GameOptions.keys())
	if err:
		print("failed to parse json for options! %s", json.get_error_message())
		return {
			GameOptions.find_key(GameOptions.ENABLE_COLOR): true,
			GameOptions.find_key(GameOptions.ENABLE_MARKS): true,
			GameOptions.find_key(GameOptions.ENABLE_SOUND): true,
			GameOptions.find_key(GameOptions.DIFFICULTY): menu_bar.GameDifficulty.find_key(menu_bar.GameDifficulty.BEGINNER),

			GameOptions.find_key(GameOptions.NUM_MINES): 10,
			GameOptions.find_key(GameOptions.WIDTH): 9,
			GameOptions.find_key(GameOptions.HEIGHT): 9,
		}
	
	return json.data

static func save_options(color_enabled: bool, marks_enabled: bool, sound_enabled: bool, difficulty: menu_bar.GameDifficulty, width: int, height: int, num_mines: int):
	var options = {
			GameOptions.find_key(GameOptions.ENABLE_COLOR): color_enabled,
			GameOptions.find_key(GameOptions.ENABLE_MARKS): marks_enabled,
			GameOptions.find_key(GameOptions.ENABLE_SOUND): sound_enabled,
			GameOptions.find_key(GameOptions.DIFFICULTY): menu_bar.GameDifficulty.find_key(difficulty),
			
			# a little CYA - don't save custom sizes above the normal maximums
			# this prevents people from setting the size to 9999x9999, crashing
			# their game, and being unable to reload it
			GameOptions.find_key(GameOptions.NUM_MINES): clampi(num_mines, 0, custom_modal.get_max_mines(width, height)),
			GameOptions.find_key(GameOptions.WIDTH): clampi(width, 0, custom_modal.MAX_WIDTH),
			GameOptions.find_key(GameOptions.HEIGHT): clampi(height, 0, custom_modal.MAX_HEIGHT),
	}
	print("saving options", options)
	var options_text = JSON.stringify(options)
	
	
	var file = FileAccess.open(OPTIONS_FILE, FileAccess.WRITE)
	file.store_string(options_text)
