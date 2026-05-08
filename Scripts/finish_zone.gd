extends Area3D

signal level_complete

const INGREDIENTS = {
	"Level_1": {"emoji": "🍅", "name": "THE KETCHUP"},
	"Level_2": {"emoji": "🧅", "name": "THE ONION"},
	"Level_3": {"emoji": "🌭", "name": "THE BUN"},
	"Level_4": {"emoji": "🌶️", "name": "THE HOT SAUCE"},
	"Level_5": {"emoji": "🥒", "name": "THE PICKLE"},
	"Level_6": {"emoji": "🧂", "name": "THE RELISH"},
}

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		var level_name = get_tree().current_scene.name
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			if INGREDIENTS.has(level_name) and not SaveData.is_cutscene_seen(level_name):
				SaveData.mark_cutscene_seen(level_name)
				var ingredient = INGREDIENTS[level_name]
				gm.trigger_ingredient_cutscene(ingredient["emoji"], ingredient["name"])
			else:
				emit_signal("level_complete")
