extends Area3D

@export var spider_scene: PackedScene 
@export var horde_size: int = 12
@export var spawn_radius: float = 3.0
@export var spawn_location_node: Node3D

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
		
	if body.is_in_group("player"):
		if not spawn_location_node:
			print("Error: Assign the spawn_location_node in the inspector!")
			return
			
		triggered = true
		spawn_horde_automatically()

func spawn_horde_automatically():
	for i in range(horde_size):
		var spider_instance = spider_scene.instantiate()
		
		var random_offset = Vector3(
			randf_range(-spawn_radius, spawn_radius),
			0,
			randf_range(-spawn_radius, spawn_radius)
		)
		
		# FIX: Set the position FIRST, before adding it to the scene tree.
		# This stops the single-frame (0,0,0) ghost spawning completely.
		spider_instance.global_position = spawn_location_node.global_position + random_offset
		
		get_tree().current_scene.add_child(spider_instance)
		spider_instance.start_chase()
