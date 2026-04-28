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
	player.set_physics_process(false)
	player.set_process_input(false)
	var level_name = get_tree().current_scene.name
	var is_new_best = false
	var best = SaveData.get_best_time(level_name)
	if time_elapsed < best:
		SaveData.save_best_time(level_name, time_elapsed)
		is_new_best = true
	var level_num = level_name.replace("level_", "").to_int()
	var next_level = "level_" + str(level_num + 1)
	SaveData.unlock_level(next_level)
	hud.show_complete(get_medal(), get_time_string(), is_new_best, format_time(best))

func _on_player_died():
	player.global_position = spawn_point.global_position
	player.velocity = Vector3.ZERO

func get_medal() -> String:
	if time_elapsed < 45.0:
		return "GOLD"
	elif time_elapsed < 60.0:
		return "SILVER"
	else:
		return "BRONZE"

func get_time_string() -> String:
	return format_time(time_elapsed)

func format_time(t: float) -> String:
	if t == INF:
		return "--:--.--"
	var minutes = int(t) / 60
	var seconds = int(t) % 60
	var milliseconds = int(fmod(t, 1.0) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]
