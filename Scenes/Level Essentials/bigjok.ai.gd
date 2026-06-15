extends CharacterBody3D

# --- Node references (adjust names to match your scene) ---
@onready var anim = $BigjokModel/AnimationPlayer        # or $YourGLBName/AnimationPlayer
@onready var nav = $NavigationAgent3D
@onready var hearing_range = $HearingArea   # Area3D with sphere CollisionShape3D

# --- Stats ---
@export var move_speed := 10.2
@export var hearing_radius := 14.0
@export var attack_radius := 1.6
@export var attack_cooldown := 1.8
@export var respawn_delay := 3.0
@export var spawn_delay := 5.0

# --- Internal state ---
enum State { WAITING, IDLE, CHASE, ATTACK, DEAD }
var state := State.WAITING
var player : Node3D = null
var attack_timer := 0.0
var spawn_timer := 0.0
var is_attacking := false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	print("Bigjok _ready called!")
	var players = get_tree().get_nodes_in_group("player")
	print("Players found: ", players.size())
	if players.size() > 0:
		player = players[0]

	hearing_range.body_entered.connect(_on_player_entered_range)
	hearing_range.body_exited.connect(_on_player_exited_range)

	visible = false
	$CollisionShape3D.disabled = true
	hearing_range.monitoring = false
	print("Bigjok ready done, spawn delay is: ", spawn_delay)

	hearing_range.body_entered.connect(_on_player_entered_range)
	hearing_range.body_exited.connect(_on_player_exited_range)

	visible = false
	$CollisionShape3D.disabled = true
	hearing_range.monitoring = false

func _physics_process(delta):
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

	move_and_slide()

# ─── WAITING ─────────────────────────────────────────────────────────────────
func _do_waiting(delta):
	velocity.x = 0
	velocity.z = 0
	spawn_timer += delta
	if fmod(spawn_timer, 1.0) < delta:
		print("Waiting... ", snapped(spawn_timer, 0.1), "s / ", spawn_delay, "s")
	if spawn_timer >= spawn_delay:
		_spawn()
	velocity.x = 0
	velocity.z = 0
	spawn_timer += delta
	if spawn_timer >= spawn_delay:
		_spawn()

func _spawn():
	if player:
		var behind = player.global_position - player.global_transform.basis.z * 6.0
		global_position = behind
		look_at(player.global_position, Vector3.UP)
	
	visible = true
	$CollisionShape3D.disabled = false
	hearing_range.monitoring = true
	state = State.CHASE
	anim.play("Walk_B")
	print("Spawning Bigjok!")
	
	# Spawn 2 meters behind the player
	if player:
		var behind = player.global_position - player.global_transform.basis.z * 6.0
		global_position = behind
	
	visible = true
	$CollisionShape3D.disabled = false
	hearing_range.monitoring = true
	state = State.CHASE  # go straight to chase since it spawns right behind you
	anim.play("Walk_B")
	print("Bigjok spawned at: ", global_position, " visible: ", visible)

# ─── IDLE ─────────────────────────────────────────────────────────────────────
func _do_idle():
	velocity.x = 0
	velocity.z = 0
	if anim.current_animation != "Idle_B":
		anim.play("Idle_B")

# ─── CHASE ───────────────────────────────────────────────────────────────────
func _do_chase():
	if player == null:
		return

	if anim.current_animation != "Walk_B":
		anim.play("Walk_B")

	if global_position.distance_to(player.global_position) <= attack_radius:
		state = State.ATTACK
		return

	nav.target_position = player.global_position
	var next = nav.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

	if dir.length() > 0.1:
		look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

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
			anim.play("Attack_B")   # Bite
		else:
			anim.play("Attack2_B")  # Lick

		await anim.animation_finished
		is_attacking = false
		_kill_player()

# ─── KILL PLAYER ─────────────────────────────────────────────────────────────
func _kill_player():
	if player == null or state == State.DEAD:
		return

	if player.has_method("die"):
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
