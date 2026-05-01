extends CharacterBody3D

const MAX_SPEED = 20.0
const GRAVITY = -20.0
const MOUSE_SENSITIVITY = 0.003
const ACCELERATION = 0.5
const FRICTION = 1.5
const ICE_ACCELERATION = 0.05
const ICE_FRICTION = 0.02
const ICE_DRIFT_STRENGTH = 1.5

@onready var camera_pivot = $CameraPivot

var current_speed = 0.0
var is_on_ice = false
var ice_drift = 0.0

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

	var accel = ICE_ACCELERATION if is_on_ice else ACCELERATION
	var friction = ICE_FRICTION if is_on_ice else FRICTION

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir += camera_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir -= camera_pivot.global_transform.basis.z

	input_dir.y = 0
	input_dir = input_dir.normalized()

	if input_dir.length() > 0.1:
		current_speed = min(current_speed + accel, MAX_SPEED)

		if is_on_ice:
			# Build up drift the longer you hold W on ice
			ice_drift = min(ice_drift + delta * ICE_DRIFT_STRENGTH, 1.0)
			# Blend movement direction toward the right over time
			var drift_dir = input_dir.lerp(transform.basis.x, ice_drift).normalized()
			velocity.x = lerp(velocity.x, drift_dir.x * current_speed, accel)
			velocity.z = lerp(velocity.z, drift_dir.z * current_speed, accel)
		else:
			var target_velocity = input_dir * current_speed
			velocity.x = lerp(velocity.x, target_velocity.x, accel)
			velocity.z = lerp(velocity.z, target_velocity.z, accel)

		$Sausage.rotate_x(current_speed * delta * 3.0)
	else:
		# Drift resets slowly when you let go
		ice_drift = max(ice_drift - delta * 0.5, 0.0)
		current_speed = max(current_speed - friction, 0.0)
		var bleed_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_velocity = bleed_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, friction)
		velocity.z = lerp(velocity.z, target_velocity.z, friction)

	move_and_slide()
