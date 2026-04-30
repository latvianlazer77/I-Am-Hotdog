extends RigidBody3D

const SPEED = 50.0
const MOUSE_SENSITIVITY = 0.003
const WOBBLE_STRENGTH = 3.0
const WOBBLE_SPEED = 3.0

@onready var camera_pivot = $CameraPivot

var wobble_time = 0.0
var target_rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		target_rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

func _physics_process(delta):
	# Apply Y rotation manually since RigidBody3D blocks direct rotation
	var current = rotation.y
	rotation.y = lerp_angle(current, target_rotation_y, 0.3)

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir += camera_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir -= camera_pivot.global_transform.basis.z

	input_dir.y = 0
	input_dir = input_dir.normalized()

	if input_dir.length() > 0.1:
		wobble_time += delta * WOBBLE_SPEED
		var wobble_offset = transform.basis.x * sin(wobble_time) * WOBBLE_STRENGTH
		apply_central_force((input_dir * SPEED) + wobble_offset)
		$Sausage.rotate_x(SPEED * delta * 0.05)
	else:
		wobble_time = 0.0
		linear_velocity.x = lerp(linear_velocity.x, 0.0, 0.1)
		linear_velocity.z = lerp(linear_velocity.z, 0.0, 0.1)

	angular_velocity.x = 0.0
	angular_velocity.z = 0.0
