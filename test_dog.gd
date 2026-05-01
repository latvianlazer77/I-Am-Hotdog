extends CharacterBody3D

const MAX_SPEED = 20.0
const MIN_SPEED = 3.0
const GRAVITY = -20.0
const MOUSE_SENSITIVITY = 0.003
const ACCELERATION = 0.5
const FRICTION = 1.5

@onready var camera_pivot = $CameraPivot

var current_speed = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

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

	if input_dir.length() > 0.1:
		# Build up speed the longer you hold W, capped at MAX_SPEED
		current_speed = min(current_speed + ACCELERATION, MAX_SPEED)
		var target_velocity = input_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, 0.1)
		velocity.z = lerp(velocity.z, target_velocity.z, 0.1)
		$Sausage.rotate_x(current_speed * delta * 3.0)
	else:
		# Slowly bleeds off speed when you let go, doesnt stop instantly
		current_speed = max(current_speed - FRICTION, 0.0)
		var bleed_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_velocity = bleed_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, 0.1)
		velocity.z = lerp(velocity.z, target_velocity.z, 0.1)

	move_and_slide()
