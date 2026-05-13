extends Node

const SAVE_PATH = "user://scores.cfg"

var config = ConfigFile.new()

func _ready():
	config.load(SAVE_PATH)
	if not config.has_section_key("unlocks", "level_1"):
		config.set_value("unlocks", "level_1", true)
		config.save(SAVE_PATH)

func get_best_time(level_name: String) -> float:
	return config.get_value("scores", level_name, INF)

func save_best_time(level_name: String, time: float):
	config.set_value("scores", level_name, time)
	config.save(SAVE_PATH)

func is_level_unlocked(level_name: String) -> bool:
	if level_name == "level_1":
		return true
	return config.get_value("unlocks", level_name, false)

func unlock_level(level_name: String):
	config.set_value("unlocks", level_name, true)
	config.save(SAVE_PATH)

func has_ingredient(ingredient_name: String) -> bool:
	return config.get_value("ingredients", ingredient_name, false)

func save_ingredient(ingredient_name: String):
	config.set_value("ingredients", ingredient_name, true)
	config.save(SAVE_PATH)

func is_cutscene_seen(level_name: String) -> bool:
	return config.get_value("cutscenes", level_name, false)

func mark_cutscene_seen(level_name: String):
	config.set_value("cutscenes", level_name, true)
	config.save(SAVE_PATH)
