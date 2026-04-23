extends CharacterBody3D

const SPEED = 10.0
const GRAVITY = -20.0
const MOUSE_SENSITIVITY = 0.003
const ACCELERATION = 3.0
const FRICTION = 2.0

@onready var camera_pivot = $CameraPivot

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir += camera_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir -= camera_pivot.global_transform.basis.z

	input_dir.y = 0
	input_dir = input_dir.normalized()

	var target_velocity = input_dir * SPEED
	if input_dir.length() > 0.1:
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
		$Sausage.rotate_x(SPEED * delta * 3.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, FRICTION * delta)
		velocity.z = lerp(velocity.z, 0.0, FRICTION * delta)

	move_and_slide()
