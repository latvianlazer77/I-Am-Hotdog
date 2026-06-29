extends Area3D

@export var spider_scene: PackedScene 
@export var horde_size: int = 15
@export var spawn_location_node: Node3D 
@export var bigjok_kickback_position := Vector3(0, 0, 0) 

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 1. IF BIGJOK HITS THE TRIGGER: Kick him out and ban his tracking
	if body.name.to_lower().contains("bigjok") or body.is_in_group("enemy"):
		if "is_banned_from_maze" in body:
			body.is_banned_from_maze = true
			body.state = body.State.IDLE # Force him to stop chasing
		body.global_position = bigjok_kickback_position
		return 

	# 2. IF PLAYER HITS THE TRIGGER: Turn on spiders, lock BigJok out
	if body.is_in_group("player"):
		# Find BigJok in the scene and tell him he's banned from tracking
		var enemies = get_tree().get_nodes_in_group("enemy") # Or whatever group BigJok is in
		for enemy in enemies:
			if "is_banned_from_maze" in enemy:
				enemy.is_banned_from_maze = true
				enemy.state = enemy.State.IDLE

		if triggered:
			return
			
		triggered = true
		
		# Spawn the spiders
		for i in range(horde_size):
			var spider = spider_scene.instantiate()
			var offset = Vector3(i * 0.4, 0.0, i * -0.4)
			spider.global_position = spawn_location_node.global_position + offset
			get_tree().current_scene.add_child(spider)
