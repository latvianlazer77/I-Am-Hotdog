extends CharacterBody3D

# --- Node references ---
@onready var anim = $BigjokModel/AnimationPlayer
@onready var nav = $NavigationAgent3D
@onready var hearing_range = $HearingArea
@onready var attack_range = $AttackArea

# --- Stats ---
@export var move_speed := 2.2
@export var hearing_radius := 14.0
@export var attack_cooldown := 1.8
@export var respawn_delay := 3.0
@export var spawn_delay := 5.0 # TESTING ONLY

# --- Massive Proximity Shader Settings ---
@export var max_effect_distance := 80.0  # Faint edge glitches start way out at 80 meters
@export var min_effect_distance := 10.0  # 100% full screen tearing hits at 10 meters

# --- Massive Teleport Settings ---
@export var max_chase_distance := 90.0   # If player gets 90+ meters away, he loses them and teleports
@export var teleport_forward_dist := 25.0 # Teleports him 25 meters away to keep the chase going

# --- Internal state ---
enum State { WAITING, IDLE, CHASE, ATTACK, DEAD }
var state := State.WAITING
var player : Node3D = null
var attack_timer := 0.0
var spawn_timer := 0.0
var is_attacking := false
var is_frozen := false
var player_in_attack_range := false
var original_y_level := 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var shader_rect : ColorRect = null

func _ready():
	original_y_level = global_position.y
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	hearing_range.body_entered.connect(_on_player_entered_range)
	hearing_range.body_exited.connect(_on_player_exited_range)
	attack_range.body_entered.connect(_on_attack_area_body_entered)
	attack_range.body_exited.connect(_on_attack_area_body_exited)

	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)

	visible = false
	$CollisionShape3D.disabled = true
	hearing_range.monitoring = false
	attack_range.monitoring = false
	
	_find_shader_rect()
	_reset_shader()

func _find_shader_rect():
	var managers = get_tree().get_nodes_in_group("game_manager")
	if managers.size() > 0:
		var game_manager = managers[0]
		if game_manager.has_node("PostProcessing/ColorRect"):
			shader_rect = game_manager.get_node("PostProcessing/ColorRect") as ColorRect
			print("Found Bigjok's glitch shader successfully via GameManager!")
		elif game_manager.has_node("PostProcessing"):
			shader_rect = game_manager.get_node("PostProcessing") as ColorRect

func _physics_process(delta):
	if is_frozen:
		velocity = Vector3.ZERO
		return

	if state != State.WAITING and state != State.DEAD and not is_on_floor():
		velocity.y -= gravity * delta
	elif is_on_floor():
		velocity.y = 0 

	match state:
		State.WAITING:
			_do_waiting(delta)
		State.IDLE:
			_do_idle()
		State.CHASE:
			_do_chase()
		State.ATTACK:
			_do_attack(delta)
		State.DEAD:
			pass

	# --- STRICT SHADER STATE & INSTANT TELEPORT CHECKS ---
	if player and state != State.WAITING and state != State.DEAD:
		var current_dist = global_position.distance_to(player.global_position)
		
		# 1. Update Shader Proximity based on actual distance
		if (state == State.CHASE or state == State.ATTACK) and visible == true:
			_update_shader_proximity(current_dist)
		else:
			_reset_shader()

		# 2. INSTANT TELEPORT CHECK (Runs every frame, no 5s timer delay)
		if current_dist > max_chase_distance:
			_teleport_far_away()

	if player and state != State.WAITING and state != State.DEAD:
		var dir = player.global_position - global_position
		dir.y = 0
		if dir.length() > 0.1:
			look_at(global_position + dir, Vector3.UP)

	move_and_slide()
	
	# Keep his height perfectly locked to the map baseline floor
	if state != State.WAITING and state != State.DEAD:
		global_position.y = original_y_level + 0.1

func _update_shader_proximity(dist: float):
	if shader_rect == null:
		return
	
	# Linear distance calculation (80m down to 10m)
	var strength = 1.0 - ((dist - min_effect_distance) / (max_effect_distance - min_effect_distance))
	strength = clamp(strength, 0.0, 1.0) 
	
	if strength <= 0.0:
		shader_rect.visible = false
	else:
		shader_rect.visible = true
		if shader_rect.material:
			# Sharp exponential curve: 
			# At 40m out, strength is 0.5 -> 0.5^4 = 0.06 (barely 6% visible!)
			# At 12m out, strength is 0.9 -> 0.9^4 = 0.65 (suddenly hits like a truck!)
			var skewed_strength = pow(strength, 4.0)
			shader_rect.material.set_shader_parameter("proximity_strength", skewed_strength)
func _reset_shader():
	if shader_rect != null:
		shader_rect.visible = false
		if shader_rect.material:
			shader_rect.material.set_shader_parameter("proximity_strength", 0.0)

# ─── INSTANT TELEPORTATION SYSTEM ────────────────────────────────────
func _teleport_far_away():
	if player == null:
		return
		
	# Pick a random angle around the player
	var angle = randf() * TAU
	# Spawns him further away (at your exact customized teleport distance setting)
	var offset = Vector3(cos(angle), 0, sin(angle)) * teleport_forward_dist
	
	var new_pos = player.global_position + offset
	new_pos.y = original_y_level + 0.1  
	global_position = new_pos
	
	print("Player outran Bigjok! Instantly relocated 25m away.")

# ─── TIME STOP ────────────────────────────────────────────────────────
func _on_ability_activated(ability_name: String):
	if ability_name == "mustard":
		is_frozen = true
		anim.pause()

func _on_ability_ended(ability_name: String):
	if ability_name == "mustard":
		is_frozen = false
		anim.play()

# ─── WAITING & SPAWN LOOP ─────────────────────────────────────────────
func _do_waiting(delta):
	velocity = Vector3.ZERO
	_reset_shader()
	spawn_timer += delta
	if spawn_timer >= spawn_delay:
		_spawn()

func _spawn():
	if player:
		# Lands 25 meters back right away
		var behind = player.global_position - player.global_transform.basis.z * 25.0
		behind.y = original_y_level + 0.1  
		global_position = behind

	visible = true
	$CollisionShape3D.disabled = false
	hearing_range.monitoring = true
	attack_range.monitoring = true  
	state = State.CHASE
	anim.play("Walk_B")

# ─── IDLE ─────────────────────────────────────────────────────────────
func _do_idle():
	velocity.x = 0
	velocity.z = 0
	if anim.current_animation != "Idle_B":
		anim.play("Idle_B")

# ─── CHASE ────────────────────────────────────────────────────────────
func _do_chase():
	if player == null:
		return

	if anim.current_animation != "Walk_B":
		anim.play("Walk_B")

	if player_in_attack_range:
		state = State.ATTACK
		return

	nav.target_position = player.global_position
	var next = nav.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

# ─── ATTACK ───────────────────────────────────────────────────────────
func _do_attack(delta):
	if is_attacking:
		return

	if not player_in_attack_range:
		state = State.CHASE
		attack_timer = 0.0
		return

	velocity.x = 0
	velocity.z = 0
	attack_timer -= delta

	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		is_attacking = true

		if randf() > 0.5:
			anim.play("Attack_B")
		else:
			anim.play("Attack2_B")

		await anim.animation_finished
		is_attacking = false
		
		if player_in_attack_range:
			_kill_player()

# ─── PLAYER INTERACTIONS & COLLISION DETECTORS ───────────────────────
func _kill_player():
	_reset_shader()
	state = State.WAITING
	spawn_timer = 0.0
	visible = false
	$CollisionShape3D.disabled = true

	var managers = get_tree().get_nodes_in_group("game_manager")
	if managers.size() > 0:
		managers[0]._on_player_died()

func _on_player_entered_range(body):
	if body.is_in_group("player") and state == State.IDLE:
		state = State.CHASE

func _on_player_exited_range(body):
	if body.is_in_group("player") and state == State.CHASE:
		state = State.IDLE

func _on_attack_area_body_entered(body):
	if body.is_in_group("player"):
		player_in_attack_range = true

func _on_attack_area_body_exited(body):
	if body.is_in_group("player"):
		player_in_attack_range = false
