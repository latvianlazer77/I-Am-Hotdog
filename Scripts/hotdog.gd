
extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = -9.8
const MOUSE_SENSITIVITY = 0.003

@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Rotate the whole body left/right (yaw)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Tilt the camera up/down (pitch), clamped to avoid flipping
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.2, 1.2)
	
	# Release mouse with Escape
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Get W/S input relative to where the player is facing
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):    # W
		input_dir -= transform.basis.z
	if Input.is_action_pressed("ui_down"):  # S
		input_dir += transform.basis.z

	input_dir = input_dir.normalized()
	velocity.x = input_dir.x * SPEED
	velocity.z = input_dir.z * SPEED

	move_and_slide()
