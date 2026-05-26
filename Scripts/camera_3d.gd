extends Camera3D

@export var target: Node3D
@export var y_offset: float = 1.5
@export var z_offset_normal: float = 5.0
@export var z_offset_moving: float = 3.0
@export var zoom_speed: float = 1.5

var current_z_offset: float = 5.0

func _process(delta):
	if not target:
		return
	var moving = abs(target.position.z - position.z + current_z_offset) > 0.1
	var target_z = z_offset_moving if moving else z_offset_normal
	current_z_offset = lerp(current_z_offset, target_z, zoom_speed * delta)
	position.x = target.position.x
	position.y = target.position.y + y_offset
	position.z = target.position.z + current_z_offset
	rotation_degrees.x = -15
	rotation_degrees.y = 0
	rotation_degrees.z = 0
