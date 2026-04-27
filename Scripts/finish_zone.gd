extends Area3D

signal level_complete

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D:
		emit_signal("level_complete")
