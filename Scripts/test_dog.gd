extends CharacterBody3D

const MAX_SPEED = 20.0
const SPRINT_SPEED = 35.0
const GRAVITY = -20.0
const MOUSE_SENSITIVITY = 0.003
const ACCELERATION = 0.5
const FRICTION = 1.5
const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 25.0
const STAMINA_REGEN = 10.0
const MAX_BURN = 100.0
const BURN_DRAIN = 15.0
const DASH_DISTANCE = 50.0
const DASH_SPEED = 40.0

@onready var camera_pivot = $CameraPivot
@onready var ketchup_particles = $KetchupEffect/KetchupParticles
@onready var lightning_light = $KetchupEffect/LightningLight
@onready var ketchup_sound = $KetchupSound
@onready var mustard_sound = $MustardSound
@onready var smoke = $SmokeParticles
@onready var dash_particles = $DashParticles

var current_speed = 0.0
var stamina = MAX_STAMINA
var is_sprinting = false
var burn_meter = 0.0
var is_on_burner = false
var shake_amount = 0.0
var level_complete = false
var lightning_timer = 0.0
var bun_flash_tween = null
var is_dashing = false
var dash_target = Vector3.ZERO
var dash_start = Vector3.ZERO
var dash_progress = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)
	ketchup_particles.emitting = false
	lightning_light.visible = false
	dash_particles.emitting = false

func _on_ability_activated(ability_name: String):
	print("Ability activated: ", ability_name)
	match ability_name:
		"ketchup":
			ketchup_particles.emitting = true
			lightning_light.visible = true
			ketchup_sound.play()
		"mustard":
			mustard_sound.play()
		"bun":
			start_bun_flash()
		"hotsauce":
			perform_dash()

func _on_ability_ended(ability_name: String):
	print("Ability ended: ", ability_name)
	match ability_name:
		"ketchup":
			ketchup_particles.emitting = false
			lightning_light.visible = false
			ketchup_sound.stop()
		"mustard":
			mustard_sound.stop()
		"bun":
			stop_bun_flash()
		"hotsauce":
			dash_particles.emitting = false

func perform_dash():
	if is_dashing:
		return
	is_dashing = true
	dash_start = global_position
	var dash_dir = -transform.basis.z
	dash_dir.y = 0
	dash_dir = dash_dir.normalized()

	# Raycast to check for walls
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + dash_dir * DASH_DISTANCE
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if result:
		dash_target = result.position - dash_dir * 0.2
	else:
		dash_target = global_position + dash_dir * DASH_DISTANCE

	dash_progress = 0.0
	dash_particles.emitting = true

	var tween = create_tween()
	tween.tween_method(func(v):
		global_position = dash_start.lerp(dash_target, v)
	, 0.0, 1.0, DASH_DISTANCE / DASH_SPEED)
	tween.tween_callback(func():
		is_dashing = false
		dash_particles.emitting = false
	)

func start_bun_flash():
	if bun_flash_tween:
		bun_flash_tween.kill()
	bun_flash_tween = create_tween().set_loops()
	bun_flash_tween.tween_callback(func():
		$Sausage.get_active_material(0).albedo_color = Color(1, 1, 1, 0.3)
	)
	bun_flash_tween.tween_interval(0.15)
	bun_flash_tween.tween_callback(func():
		$Sausage.get_active_material(0).albedo_color = Color(1, 1, 1, 1.0)
	)
	bun_flash_tween.tween_interval(0.15)

func stop_bun_flash():
	if bun_flash_tween:
		bun_flash_tween.kill()
	$Sausage.get_active_material(0).albedo_color = Color(1, 1, 1, 1.0)

func pause_sounds():
	if ketchup_sound.playing:
		ketchup_sound.stream_paused = true
	if mustard_sound.playing:
		mustard_sound.stream_paused = true

func resume_sounds():
	if ketchup_sound.stream_paused:
		ketchup_sound.stream_paused = false
	if mustard_sound.stream_paused:
		mustard_sound.stream_paused = false

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x((-event.relative.y * MOUSE_SENSITIVITY) + randf_range(-shake_amount, shake_amount))
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -0.8, 0.6)

func _process(delta):
	if Input.is_action_just_pressed("ability_ketchup"):
		AbilityManager.activate("ketchup")
	if Input.is_action_just_pressed("ability_mustard"):
		AbilityManager.activate("mustard")
	if Input.is_action_just_pressed("ability_bun"):
		AbilityManager.activate("bun")
	if Input.is_action_just_pressed("ability_hotsauce"):
		AbilityManager.activate("hotsauce")

	if AbilityManager.is_active("ketchup"):
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_light.visible = !lightning_light.visible
			lightning_light.light_energy = randf_range(2.0, 5.0)
			lightning_light.omni_range = randf_range(2.0, 4.0)
			lightning_light.light_color = Color(
				randf_range(0.8, 1.0),
				randf_range(0.6, 1.0),
				randf_range(0.0, 0.3)
			)
			lightning_timer = randf_range(0.03, 0.1)

func _physics_process(delta):
	if is_dashing:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if not level_complete:
		if is_on_burner and not AbilityManager.is_active("mustard") and not AbilityManager.is_active("bun"):
			burn_meter = min(burn_meter + delta * 50.0, MAX_BURN)
		else:
			burn_meter = max(burn_meter - BURN_DRAIN * delta, 0.0)

		if burn_meter >= MAX_BURN:
			burn_meter = 0.0
			var gm = get_tree().get_first_node_in_group("game_manager")
			if gm:
				gm._on_player_died()

		smoke.emitting = burn_meter > 50.0
		shake_amount = (burn_meter / MAX_BURN) * 0.015
	else:
		burn_meter = 0.0
		smoke.emitting = false
		shake_amount = 0.0

	var burn_speed_mult = 1.0 - (burn_meter / MAX_BURN) * 0.7
	var wants_to_sprint = Input.is_action_pressed("sprint") and stamina > 0
	is_sprinting = wants_to_sprint and Input.is_action_pressed("move_forward")

	if is_sprinting:
		stamina = max(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		stamina = min(stamina + STAMINA_REGEN * delta, MAX_STAMINA)

	var ketchup_mult = 3.0 if AbilityManager.is_active("ketchup") else 1.0
	var top_speed = (SPRINT_SPEED if is_sprinting else MAX_SPEED) * burn_speed_mult * ketchup_mult

	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir += camera_pivot.global_transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir -= camera_pivot.global_transform.basis.z

	input_dir.y = 0
	input_dir = input_dir.normalized()

	if input_dir.length() > 0.1:
		current_speed = min(current_speed + ACCELERATION, top_speed)
		var target_velocity = input_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
		$Sausage.rotate_x(current_speed * delta * 3.0)
	else:
		current_speed = max(current_speed - FRICTION, 0.0)
		var bleed_dir = Vector3(velocity.x, 0, velocity.z).normalized()
		var target_velocity = bleed_dir * current_speed
		velocity.x = lerp(velocity.x, target_velocity.x, FRICTION * delta)
		velocity.z = lerp(velocity.z, target_velocity.z, FRICTION * delta)

	if shake_amount > 0:
		camera_pivot.rotation.z = randf_range(-shake_amount, shake_amount)
	else:
		camera_pivot.rotation.z = lerp(camera_pivot.rotation.z, 0.0, delta * 5.0)

	if is_sprinting:
		camera_pivot.get_child(0).fov = lerp(camera_pivot.get_child(0).fov, 90.0, delta * 5.0)
	else:
		camera_pivot.get_child(0).fov = lerp(camera_pivot.get_child(0).fov, 75.0, delta * 5.0)

	move_and_slide()

func start_cutscene_float():
	set_physics_process(false)
	set_process_input(false)
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", global_position.y + 0.5, 0.8)
	tween.tween_property(self, "position:y", global_position.y, 0.8)
	var spin_tween = create_tween().set_loops()
	spin_tween.tween_property($Sausage, "rotation:y", TAU, 1.5)

func stop_cutscene_float():
	$Sausage.rotation.y = 0.0

func get_stamina_percent() -> float:
	return stamina / MAX_STAMINA

func get_burn_percent() -> float:
	return burn_meter / MAX_BURN
