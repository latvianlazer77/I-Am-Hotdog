extends Control

const LEVELS = [
	"level_1", "level_2", "level_3",
	"level_4", "level_5", "level_6"
]

const LEVEL_PATHS = {
	"level_1": "res://Scenes/Levels/level_1.tscn",
	"level_2": "res://Scenes/Levels/level_2.tscn",
	"level_3": "res://Scenes/Levels/level_3.tscn",
	"level_4": "res://Scenes/Levels/level_4.tscn",
	"level_5": "res://Scenes/Levels/level_5.tscn",
	"level_6": "res://Scenes/Levels/level_6.tscn",
}

func _ready():
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn"))
	for i in range(LEVELS.size()):
		var level_name = LEVELS[i]
		var button = $GridContainer.get_child(i)
		var unlocked = SaveData.is_level_unlocked(level_name)
		var best = SaveData.get_best_time(level_name)
		var medal = get_medal(best)
		if unlocked:
			button.disabled = false
			button.modulate = Color(1, 1, 1)
			var label_text = "Level " + str(i + 1)
			if best != INF:
				label_text += "\n" + format_time(best)
				label_text += "\n" + medal
			else:
				label_text += "\nNo time yet"
			button.text = label_text
			button.pressed.connect(_on_level_pressed.bind(level_name))
			style_medal(button, medal, best)
		else:
			button.disabled = true
			button.modulate = Color(0.4, 0.4, 0.4)
			button.text = "Level " + str(i + 1) + "\n🔒"

func style_medal(button: Button, medal: String, best: float):
	if best == INF:
		return
	match medal:
		"GOLD":
			button.modulate = Color(1, 0.84, 0)
		"SILVER":
			button.modulate = Color(0.75, 0.75, 0.75)
		"BRONZE":
			button.modulate = Color(0.8, 0.5, 0.2)

func _on_level_pressed(level_name: String):
	get_tree().change_scene_to_file(LEVEL_PATHS[level_name])

func get_medal(best: float) -> String:
	if best == INF:
		return ""
	if best < 45.0:
		return "🥇 GOLD"
	elif best < 60.0:
		return "🥈 SILVER"
	else:
		return "🥉 BRONZE"

func format_time(t: float) -> String:
	if t == INF:
		return "--:--.--"
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	var milliseconds = int(fmod(t, 1.0) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
