extends Area3D

var push_timer = 0.0
var push_interval = 1.5
var push_right = true

func _ready():
	$MeshInstance3D.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	push_timer += delta
	if push_timer >= push_interval:
		push_timer = 0.0
		push_right = !push_right

func _on_body_entered(body):
	if body is CharacterBody3D:
		body.is_on_ice = true

func _on_body_exited(body):
	if body is CharacterBody3D:
		body.is_on_ice = false

func get_push_direction(body) -> Vector3:
	if push_right:
		return Vector3.RIGHT
	else:
		return Vector3.LEFT
