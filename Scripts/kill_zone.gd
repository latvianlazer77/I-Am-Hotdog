extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Only trigger death if the object that entered is in the "player" group
	if body.is_in_group("player"):
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm._on_player_died()
