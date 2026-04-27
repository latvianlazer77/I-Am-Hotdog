extends Node

const SAVE_PATH = "user://scores.cfg"

var config = ConfigFile.new()

func _ready():
	config.load(SAVE_PATH)

func get_best_time(level_name: String) -> float:
	return config.get_value("scores", level_name, INF)

func save_best_time(level_name: String, time: float):
	config.set_value("scores", level_name, time)
	config.save(SAVE_PATH)
