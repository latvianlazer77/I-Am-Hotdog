extends Node3D

const EXTEND_OFFSET = Vector3(0, 3, 0)
const EXTEND_TIME = 1
const RETRACT_TIME = 0.3
const WAIT_TIME = 1.5

@onready var hitbox = $Area3D
@onready var mesh = $MeshInstance3D

var tween = null
var base_pos = Vector3.ZERO
var retract_pos = Vector3.ZERO
var extend_pos = Vector3.ZERO

func _ready():
	base_pos = global_position
	retract_pos = base_pos + Vector3(0, -1.5, 0)
	extend_pos = base_pos + EXTEND_OFFSET
	global_position = retract_pos
	mesh.visible = false
	print("Spike ready, hitbox: ", hitbox)
	print("Mesh: ", mesh)
	hitbox.body_entered.connect(_on_body_entered)
	start_cycle()
	print("Cycle started")

func start_cycle():
	if tween:
		tween.kill()
	tween = create_tween().set_loops()
	tween.tween_interval(WAIT_TIME)
	tween.tween_callback(func():
		print("Spike extending!")
		mesh.visible = true
	)
	tween.tween_property(self, "global_position", extend_pos, EXTEND_TIME).set_trans(Tween.TRANS_EXPO)
	tween.tween_interval(0.3)
	tween.tween_property(self, "global_position", retract_pos, RETRACT_TIME).set_trans(Tween.TRANS_EXPO)
	tween.tween_callback(func(): mesh.visible = false)

func _process(_delta):
	if AbilityManager.is_active("mustard"):
		if tween:
			tween.pause()
	else:
		if tween and not tween.is_running():
			tween.play()

func _on_body_entered(body):
	if body is CharacterBody3D:
		if AbilityManager.is_active("bun"):
			return
		var gm = get_tree().get_first_node_in_group("game_manager")
		if gm:
			gm._on_player_died()
