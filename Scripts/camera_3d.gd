extends Camera3D

@export var target: Node3D
@export var y_offset: float = 1.5
@export var z_offset_normal: float = 5.0
@export var z_offset_moving: float = 3.0
@export var zoom_speed: float = 2.0
@export var follow_smoothness: float = 4.0 # Lower = floatier, Higher = tighter

var current_z_offset: float = 5.0

func _process(delta):
	if not target:
		return
		
	# 1. Check if the hotdog is rolling to the level select screen.
	# Since it rests at 0.0 and moves to -8.0, we just check if it's past -0.1!
	var is_transitioning = target.position.z < -0.1
	
	# 2. Smoothly calculate our desired Z zoom distance
	var target_z_offset = z_offset_moving if is_transitioning else z_offset_normal
	current_z_offset = lerp(current_z_offset, target_z_offset, zoom_speed * delta)
	
	# 3. Calculate the exact 3D coordinate where the camera SHOULD be
	var desired_position = Vector3(
		target.position.x,
		target.position.y + y_offset,
		target.position.z + current_z_offset
	)
	
	# 4. THE MAGIC FIX: Smoothly glide the entire camera towards that spot!
	position = position.lerp(desired_position, follow_smoothness * delta)
	
	# Keep the rotation locked perfectly
	rotation_degrees = Vector3(-15, 0, 0)
