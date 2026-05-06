extends CharacterBody3D

const MAX_SPEED = 20.0
const SPRINT_SPEED = 35.0
const GRAVITY = -20.0
const MOUSE_SENSITIVITY = 0.003
const ACCELERATION = 0.5
const FRICTION = 1.5
const ICE_ACCELERATION = 0.05
const ICE_FRICTION = 0.02
const ICE_DRIFT_STRENGTH = 1.5
const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 25.0
const STAMINA_REGEN = 10.0
const MAX_BURN = 100.0
const BURN_DRAIN = 15.0

@onready var camera_pivot = $CameraPivot
@onready var smoke = $SmokeParticles

var current_speed = 0.0
var is_on_ice = false
var ice_drift = 0.0
var stamina = MAX_STAMINA
var is_sprinting = false
var burn_meter = 0.0
var is_on_burner = false
var shake_amount = 0.0
var level_complete = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x((-event.relative.y * MOUSE_SENSITIVITY) + randf_range(-shake_amount, shake_amount))
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if not level_complete:
		# Burn meter
		if is_on_burner:
			burn_meter = min(burn_meter + delta * 50.0, MAX_BURN)
		else:
			burn_meter = max(burn_meter - BURN_DRAIN * delta, 0.0)

		# Die if burn meter full
		if burn_meter >= MAX_BURN:
			burn_meter = 0.0
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm:
				gm._on_player_died()

		# Smoke starts at 50% burn
		smoke.emitting = burn_meter > 50.0

		# Screen shake increases with burn
		shake_amount = (burn_meter / MAX_BURN) * 0.015
	else:
		burn_meter = 0.0
		smoke.emitting = false
		shake_amount = 0.0

	# Speed penalty from burn
	var burn_speed_mult = 1.0 - (burn_meter / MAX_BURN) * 0.7

	# Sprint logic
	var wants_to_sprint = Input.is_action_pressed("sprint") and stamina > 0
	is_sprinting = wants_to_sprint and Input.is_action_pressed("move_forward")

	if is_sprinting:
		stamina = max(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		stamina = min(stamina + STAMINA_REGEN * delta, MAX_STAMINA)

	var top_speed = (SPRINT_SPEED if is_sprinting else MAX_SPEED) * burn_speed_mult
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
		current_speed = min(current_speed + accel, top_speed)

		if is_on_ice:
			ice_drift = min(ice_drift + delta * ICE_DRIFT_STRENGTH, 1.0)
			var ice_zone = get_tree().get_first_node_in_group("ice_zone")
			var push = Vector3.ZERO
			if ice_zone:
				push = ice_zone.get_push_direction(self) * 8.0
			var drift_dir = (input_dir + push).normalized()
			velocity.x = lerp(velocity.x, drift_dir.x * current_speed, accel)
			velocity.z = lerp(velocity.z, drift_dir.z * current_speed, accel)
		else:
			var target_velocity = input_dir * current_speed
			velocity.x = lerp(velocity.x, target_velocity.x, accel)
			velocity.z = lerp(velocity.z, target_velocity.z, accel)

		$Sausage.rotate_x(current_speed * delta * 3.0)
	else:
		ice_drift = max(ice_drift - delta * 0.5, 0.0)
		current_speed = max(current_speed - friction, 0.0)
		var bleed_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_velocity = bleed_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, friction)
		velocity.z = lerp(velocity.z, target_velocity.z, friction)

	# Camera shake
	if shake_amount > 0:
		camera_pivot.rotation.z = randf_range(-shake_amount, shake_amount)
	else:
		camera_pivot.rotation.z = lerp(camera_pivot.rotation.z, 0.0, delta * 5.0)

	# Sprint camera fov
	if is_sprinting:
		camera_pivot.get_child(0).fov = lerp(camera_pivot.get_child(0).fov, 90.0, delta * 5.0)
	else:
		camera_pivot.get_child(0).fov = lerp(camera_pivot.get_child(0).fov, 75.0, delta * 5.0)

	move_and_slide()

func get_stamina_percent() -> float:
	return stamina / MAX_STAMINA

func get_burn_percent() -> float:
	return burn_meter / MAX_BURN
