extends Node3D

@export var spin_speed: float = 100.0 

func _physics_process(delta):
	# ==========================================
	# 1. THE TIME STOP (PICKLE)
	# ==========================================
	# If the pickle is active, we skip the rotation math. It freezes instantly!
	if AbilityManager.is_active("mustard"):
		return 
		
	# Normal spinning code
	rotation_degrees.y += spin_speed * delta


# ==========================================
# 2. THE INVINCIBILITY (BUN)
# ==========================================
# Connect your Area3D's "body_entered" signal to this function!
func _on_body_entered(body):
	if body.is_in_group("player"):
		
		# If the bun is active, do nothing (player survives!)
		if AbilityManager.is_active("bun"):
			return 
			
		# Otherwise, squish the hotdog
		if body.has_method("die"): # Change "die" if your death function has a different name
			body.die()
