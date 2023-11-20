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
