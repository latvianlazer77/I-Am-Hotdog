extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm._on_player_died()
