extends Area3D

signal level_complete

const INGREDIENTS = {
	"level_1": {"emoji": "🍅", "name": "THE KETCHUP", "key": "ketchup"},
	"level_2": {"emoji": "🧅", "name": "THE ONION", "key": "onion"},
	"level_3": {"emoji": "🌭", "name": "THE BUN", "key": "bun"},
	"level_4": {"emoji": "🌶️", "name": "THE HOT SAUCE", "key": "hotsauce"},
	"level_5": {"emoji": "🥒", "name": "THE PICKLE", "key": "pickle"},
	"level_6": {"emoji": "🧂", "name": "THE RELISH", "key": "relish"},
}

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		var level_name = get_tree().current_scene.name
		print("Finish zone hit, level: ", level_name)
		var gm = get_tree().get_first_node_in_group("game_manager")
		print("Game manager found: ", gm)
		if gm:
			if INGREDIENTS.has(level_name):
				print("Playing cutscene")
				var ingredient = INGREDIENTS[level_name]
				SaveData.save_ingredient(ingredient["key"])
				print("Ingredient saved: ", ingredient["key"])
				gm.trigger_ingredient_cutscene(ingredient["emoji"], ingredient["name"])
			else:
				print("No ingredient for this level")
				emit_signal("level_complete")
