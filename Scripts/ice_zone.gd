extends Area3D

const CURRENT_STRENGTH = 12.0
var current_direction = Vector3.RIGHT

func _ready():
	$MeshInstance3D.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D:
		body.is_in_current = true
		body.current_direction = current_direction
		body.current_strength = CURRENT_STRENGTH

func _on_body_exited(body):
	if body is CharacterBody3D:
		body.is_in_current = false
		body.current_direction = Vector3.ZERO
		body.current_strength = 0.0
