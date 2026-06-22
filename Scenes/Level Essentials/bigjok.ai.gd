extends CharacterBody3D

# --- Node references ---
@onready var anim = $BigjokModel/AnimationPlayer
@onready var nav = $NavigationAgent3D
@onready var hearing_range = $HearingArea

# --- Stats ---
@export var move_speed := 2.2
@export var hearing_radius := 14.0
@export var attack_radius := 1.6
@export var attack_cooldown := 1.8
@export var respawn_delay := 3.0
@export var spawn_delay := 30.0

# --- Internal state ---
enum State { WAITING, IDLE, CHASE, ATTACK, DEAD }
var state := State.WAITING
var player : Node3D = null
var attack_timer := 0.0
var spawn_timer := 0.0
var teleport_timer := 0.0  # Tracks the 5-second interval
var is_attacking := false
var is_frozen := false
var original_y_level := 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Save his floor level at startup
	original_y_level = global_position.y
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	hearing_range.body_entered.connect(_on_player_entered_range)
	hearing_range.body_exited.connect(_on_player_exited_range)

	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)

	visible = false
	$CollisionShape3D.disabled = true
	hearing_range.monitoring = false

func _physics_process(delta):
	if is_frozen:
		velocity = Vector3.ZERO
		return

	# ONLY apply gravity if he has actually spawned and isn't waiting!
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

	# --- REPEATING TELEPORT CHECK ---
	# Checks every 5 seconds while active if the player is too far away
	if state != State.WAITING and state != State.DEAD and player:
		teleport_timer += delta
		if teleport_timer >= 5.0:
			teleport_timer = 0.0 # Reset the timer loop so it runs again in another 5s
			if global_position.distance_to(player.global_position) > 20.0:
				_teleport_near_player()

	# Always face player without tilting up or down
	if player and state != State.WAITING and state != State.DEAD:
		var dir = player.global_position - global_position
		dir.y = 0
		if dir.length() > 0.1:
			look_at(global_position + dir, Vector3.UP)

	move_and_slide()

# ─── TIME STOP ────────────────────────────────────────────────────────
func _on_ability_activated(ability_name: String):
	if ability_name == "mustard":
		is_frozen = true
		anim.pause()

func _on_ability_ended(ability_name: String):
	if ability_name == "mustard":
		is_frozen = false
		anim.play()

# ─── WAITING ──────────────────────────────────────────────────────────
func _do_waiting(delta):
	velocity = Vector3.ZERO
	spawn_timer += delta
	if spawn_timer >= spawn_delay:
		_spawn()

func _spawn():
	if player:
		var behind = player.global_position - player.global_transform.basis.z * 30.0
		behind.y = original_y_level + 0.1  
		global_position = behind

	visible = true
	$CollisionShape3D.disabled = false
	hearing_range.monitoring = true
	state = State.CHASE
	anim.play("Walk_B")
	teleport_timer = 0.0 # Clear timer on fresh spawn

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

	var my_pos_2d = Vector2(global_position.x, global_position.z)
	var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)

	if my_pos_2d.distance_to(player_pos_2d) <= attack_radius:
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

	var my_pos_2d = Vector2(global_position.x, global_position.z)
	var player_pos_2d = Vector2(player.global_position.x, player.global_position.z)

	if player and my_pos_2d.distance_to(player_pos_2d) > attack_radius + 0.6:
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
		_kill_player()

# ─── REPEATING ANTI-STUCK TELEPORT ───────────────────────────────────
func _teleport_near_player():
	if player == null:
		return
	var angle = randf() * TAU
	var offset = Vector3(cos(angle), 0, sin(angle)) * 15.0
	var new_pos = player.global_position + offset
	new_pos.y = original_y_level + 0.1  
	global_position = new_pos
	print("Bigjok teleported safely near player!")

# ─── PLAYER INTERACTIONS ──────────────────────────────────────────────
func _kill_player():
	var managers = get_tree().get_nodes_in_group("game_manager")
	if managers.size() > 0:
		managers[0]._on_player_died()

func _on_player_entered_range(body):
	if body.is_in_group("player") and state == State.IDLE:
		state = State.CHASE

func _on_player_exited_range(body):
	if body.is_in_group("player") and state == State.CHASE:
		state = State.IDLE
