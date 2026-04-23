extends Area3D

signal player_died

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		emit_signal("player_died")
