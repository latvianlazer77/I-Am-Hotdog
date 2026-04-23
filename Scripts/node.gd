extends Node

var time_elapsed = 0.0
var running = true

@onready var hud = $HUD
@onready var player = $Player
@onready var spawn_point = $SpawnPoint
@onready var finish_zone = $FinishZone
@onready var kill_zone = $KillZone

func _ready():
	finish_zone.level_complete.connect(_on_level_complete)
	kill_zone.player_died.connect(_on_player_died)

func _process(delta):
	if running:
		time_elapsed += delta
		hud.update_timer(get_time_string())

func _on_level_complete():
	running = false
	print(get_medal())

func _on_player_died():
	player.global_position = spawn_point.global_position
	player.velocity = Vector3.ZERO
	time_elapsed = 0.0

func get_medal():
	if time_elapsed < 45.0:
		return "GOLD"
	elif time_elapsed < 60.0:
		return "SILVER"
	else:
		return "BRONZE"

func get_time_string():
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	var milliseconds = int(fmod(time_elapsed, 1.0) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
