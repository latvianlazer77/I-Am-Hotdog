extends Area3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready():
	mesh_instance_3d.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D:
		body.is_on_burner = true

func _on_body_exited(body):
	if body is CharacterBody3D:
		body.is_on_burner = false
