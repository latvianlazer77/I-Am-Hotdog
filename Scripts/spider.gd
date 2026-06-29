extends CharacterBody3D

# --- Node references ---
@onready var nav = $NavigationAgent3D
# NEW: Grab the spider's animation player node
@onready var anim = $Sketchfab_Scene/AnimationPlayer

@export var move_speed := 12.0 
var player : Node3D = null
var original_y_level := 0.0

var is_frozen := false

func _ready():
	scale = Vector3(0.2, 0.2, 0.2)
	original_y_level = global_position.y
	
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)

func _physics_process(_delta):
	if is_frozen:
		velocity = Vector3.ZERO
		return

	if player == null:
		return

	nav.target_position = player.global_position
	var next = nav.get_next_path_position()
	
	var dir = (next - global_position)
	dir.y = 0
	dir = dir.normalized()
	
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed

	var look_dir = player.global_position - global_position
	look_dir.y = 0
	if look_dir.length() > 0.1:
		look_at(global_position + look_dir, Vector3.UP)

	move_and_slide()
	
	global_position.y = original_y_level + 0.05

# ─── TIME STOP SIGNALS ────────────────────────────────────────────────
func _on_ability_activated(ability_name: String):
	if ability_name == "mustard":
		is_frozen = true
		# Pause the autoplaying run animation
		if anim:
			anim.pause() 

func _on_ability_ended(ability_name: String):
	if ability_name == "mustard":
		is_frozen = false
		# Resume the animation right where it left off
		if anim:
			anim.play()
