extends Node3D

@export var spin_speed: float = 100.0 

func _physics_process(delta):
	rotation_degrees.y += spin_speed * delta
