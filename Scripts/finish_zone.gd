extends Node3D

signal level_complete(medal: String, time: float)

func _on_body_entered(body):
	if body.name == "Player":
		emit_signal("level_complete")
