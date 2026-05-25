extends Camera3D

@export var target : Node3D

@export var follow_speed := 5.0
@export var x_offset := 0.0
@export var y_offset := 2.5
@export var z_offset := 8.0

func _process(delta):

	if !target:
		return

	var desired_position = Vector3(
		target.global_position.x + x_offset,
		target.global_position.y + y_offset,
		target.global_position.z + z_offset
	)

	global_position = global_position.lerp(
		desired_position,
		follow_speed * delta
	)

	# LOCK rotation completely
	rotation_degrees.x = -10
	rotation_degrees.y = 0
	rotation_degrees.z = 0
