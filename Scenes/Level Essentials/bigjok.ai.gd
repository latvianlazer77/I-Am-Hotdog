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
@export var max_distance := 20.0  # teleport if further than this

# --- Internal state ---
enum State { WAITING, IDLE, CHASE, ATTACK, DEAD }
var state := State.WAITING
var player : Node3D = null
var attack_timer := 0.0
var spawn_timer := 0.0
var is_attacking := false
var is_frozen := false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
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

	if not is_on_floor():
		velocity.y -= gravity * delta

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

	# Constantly check distance and teleport if too far
	if state != State.WAITING and state != State.DEAD and player:
		if global_position.distance_to(player.global_position) > max_distance:
			_teleport_near_player()

	# Always face player
	if player and state != State.WAITING and state != State.DEAD:
		var dir = player.global_position - global_position
		dir.y = 0
		if dir.length() > 0.1:
			look_at(global_position + dir, Vector3.UP)

	move_and_slide()

# ─── TELEPORT ────────────────────────────────────────────────────────────────
func _teleport_near_player():
	if player == null:
		return
	var angle = randf() * TAU
	var offset = Vector3(cos(angle), 0, sin(angle)) * 35.0
	global_position = player.global_position + offset
	print("Bigjok teleported near player!")

# ─── TIME STOP ───────────────────────────────────────────────────────────────
func _on_ability_activated(ability_name: String):
	if ability_name == "mustard":
		is_frozen = true
		anim.pause()

func _on_ability_ended(ability_name: String):
	if ability_name == "mustard":
		is_frozen = false
		anim.play()

# ─── WAITING ─────────────────────────────────────────────────────────────────
func _do_waiting(delta):
	velocity.x = 0
	velocity.z = 0
	spawn_timer += delta
	if spawn_timer >= spawn_delay:
		_spawn()

func _spawn():
	if player:
		var behind = player.global_position - player.global_transform.basis.z * 50.0
		global_position = behind

	visible = true
	$CollisionShape3D.disabled = false
	hearing_range.monitoring = true
	state = State.CHASE
	anim.play("Walk_B")
	print("Bigjok spawned!")

# ─── IDLE ────────────────────────────────────────────────────────────────────
func _do_idle():
	velocity.x = 0
	velocity.z = 0
	if anim.current_animation != "Idle_B":
		anim.play("Idle_B")

# ─── CHASE ───────────────────────────────────────────────────────────────────
func _do_chase():
	if player == null:
		return

	if global_position.distance_to(player.global_position) <= attack_radius:
		velocity.x = 0
		velocity.z = 0
		state = State.ATTACK
		return

	if anim.current_animation != "Walk_B":
		anim.play("Walk_B")

	nav.target_position = player.global_position
	var next = nav.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
# ─── ATTACK ──────────────────────────────────────────────────────────────────
func _do_attack(delta):
	if is_attacking:
		return

	if player and global_position.distance_to(player.global_position) > attack_radius + 0.6:
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

# ─── KILL PLAYER ─────────────────────────────────────────────────────────────
func _kill_player():
	if player == null or state == State.DEAD:
		return

	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("_on_player_died"):
		game_manager._on_player_died()
	elif player.has_method("die"):
		player.die()
	else:
		await get_tree().create_timer(respawn_delay).timeout
		get_tree().reload_current_scene()

# ─── DETECTION ───────────────────────────────────────────────────────────────
func _on_player_entered_range(body):
	if body.is_in_group("player") and state != State.WAITING and state != State.DEAD:
		player = body
		state = State.CHASE

func _on_player_exited_range(body):
	if body.is_in_group("player"):
		state = State.IDLE

# ─── DEATH ───────────────────────────────────────────────────────────────────
func die():
	if state == State.DEAD:
		return
	state = State.DEAD
	velocity = Vector3.ZERO
	anim.play("Died_B")
	await anim.animation_finished
	queue_free()
