extends Area3D

# Drag and drop your spider.tscn file into this slot in the Inspector
@export var spider_scene: PackedScene 

@onready var spawn_points = $SpawnPoints

var triggered := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered:
		return
		
	if body.is_in_group("player"):
		triggered = true
		spawn_horde()

func spawn_horde():
	# Loop through every marker node inside our SpawnPoints folder
	for marker in spawn_points.get_children():
		if marker is Node3D:
			# Instantiate a new spider
			var spider_instance = spider_scene.instantiate()
			
			# Put the spider exactly where the marker is placed in the map
			get_tree().current_scene.add_child(spider_instance)
			spider_instance.global_position = marker.global_position
			
			# Wake the spider up and tell it to sprint at the player
			spider_instance.start_chase()
