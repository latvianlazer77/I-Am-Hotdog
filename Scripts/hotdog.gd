
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
# Default friction (stops instantly)
	var friction = SPEED 
	
	# Check if we are on ice
	if is_on_floor():
		var floor_collision = get_last_slide_collision()
		if floor_collision and floor_collision.get_collider().is_in_group("Ice"):
			friction = 0.02 # Lower this to slide more, raise it to slide less!

	# Apply the movement or the slide
	if input_dir != Vector3.ZERO:
		# If you are pressing movement keys, run normal speed
		velocity.x = input_dir.x * SPEED
		velocity.z = input_dir.z * SPEED
	else:
		# If you let go, use the friction variable to slide to a stop
		velocity.x = move_toward(velocity.x, 0, friction)
		velocity.z = move_toward(velocity.z, 0, friction)
	move_and_slide()
