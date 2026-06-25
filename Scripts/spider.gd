extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

@export var speed := 4.5
var player: Node3D = null
var active := false

func _ready():
	# Shrink the spider
	scale = Vector3(0.2, 0.2, 0.2)
	
	# Find the player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		print("CRITICAL: Spider can't find any node in the 'player' group!")

	# SAFETY NET: Keep the killzone disabled for 0.5 seconds 
	# to completely stop the single-frame glitch death.
	if has_node("KillZone/CollisionShape3D"):
		$KillZone/CollisionShape3D.disabled = true
		await get_tree().create_timer(0.5).timeout
		$KillZone/CollisionShape3D.disabled = false

func _physics_process(_delta):
	if not active or not player:
		return
		
	# Update pathfinding target
	nav_agent.target_position = player.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		velocity = direction * speed
		move_and_slide()
		
		var look_dir = direction
		look_dir.y = 0
		if look_dir.length() > 0.1:
			look_at(global_position + look_dir, Vector3.UP)

func start_chase():
	active = true
