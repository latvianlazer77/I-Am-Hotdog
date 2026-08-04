extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Only trigger death if the object that entered is in the "player" group
	if body.is_in_group("player"):
		
		# ==========================================
		# THE INVINCIBILITY FIX (BUN)
		# ==========================================
		# If the bun is active, we exit the function immediately. 
		# The Game Manager never gets the message to kill the player!
		if AbilityManager.is_active("bun"):
			return 
			
		# Normal death logic
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm._on_player_died()
