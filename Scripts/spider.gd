extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

@export var speed := 4.5
var player: Node3D = null
var active := false

func _ready():
	# Find the player in the scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(_delta):
	if not active or not player:
		return
		
	# Target the player's position through the maze navigation mesh
	nav_agent.target_position = player.global_position
	
	if not nav_agent.is_navigation_finished():
		var next_path_pos = nav_agent.get_next_path_position()
		var direction = (next_path_pos - global_position).normalized()
		
		# Move the spider
		velocity = direction * speed
		move_and_slide()
		
		# Make the spider face where it's running
		var look_dir = direction
		look_dir.y = 0
		if look_dir.length() > 0.1:
			look_at(global_position + look_dir, Vector3.UP)

func start_chase():
	active = true
	# If you have an AnimationPlayer, play your walk animation here:
	# $AnimationPlayer.play("walk")
