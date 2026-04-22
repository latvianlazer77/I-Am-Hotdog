extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = -9.8
const MOUSE_SENSITIVITY = 0.003

@onready var camera_pivot = $CameraPivot

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate the hotdog body left/right with mouse
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Tilt camera up/down only
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir += transform.basis.z

	input_dir.y = 0
	input_dir = input_dir.normalized()

	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

	move_and_slide()
