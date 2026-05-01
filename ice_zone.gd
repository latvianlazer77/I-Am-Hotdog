extends Area3D

func _ready():
	$MeshInstance3D.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D:
		body.is_on_ice = true

func _on_body_exited(body):
	if body is CharacterBody3D:
		body.is_on_ice = false
