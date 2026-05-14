extends Node

var time_elapsed = 0.0
var running = true
var cutscene_active = false

@onready var hud = $HUD
@onready var player = $Player
@onready var spawn_point = $SpawnPoint
@onready var finish_zone = $FinishZone
@onready var world_env = get_parent().get_node("WorldEnvironment")

func _ready():
	finish_zone.level_complete.connect(_on_level_complete)
	hud.pause_menu.paused.connect(_on_paused)
	hud.pause_menu.resumed.connect(_on_resumed)
	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)
	time_elapsed = 0.0
	running = true
	cutscene_active = false
	AbilityManager.hard_reset()

func _on_ability_activated(ability_name: String):
	if ability_name == "mustard":
		if world_env:
			var tween = create_tween()
			tween.tween_method(func(v):
				world_env.environment.adjustment_saturation = v
				world_env.environment.adjustment_brightness = lerp(1.0, 0.8, 1.0 - v)
			, 1.0, 0.1, 0.4)

func _on_ability_ended(ability_name: String):
	if ability_name == "mustard":
		if world_env:
			var tween = create_tween()
			tween.tween_method(func(v):
				world_env.environment.adjustment_saturation = v
				world_env.environment.adjustment_brightness = lerp(1.0, 0.8, 1.0 - v)
			, 0.1, 1.0, 0.4)

func reset_world_env():
	if world_env:
		world_env.environment.adjustment_saturation = 1.0
		world_env.environment.adjustment_brightness = 1.0

func _process(delta):
	if running and not cutscene_active and not AbilityManager.is_active("mustard"):
		time_elapsed += delta
		hud.update_timer(get_time_string())

func _on_paused():
	running = false
	player.set_physics_process(false)
	player.set_process_input(false)
	player.pause_sounds()
	AbilityManager.pause_abilities()

func _on_resumed():
	running = true
	player.set_physics_process(true)
	player.set_process_input(true)
	player.resume_sounds()
	AbilityManager.resume_abilities()

func trigger_ingredient_cutscene(emoji: String, display_name: String):
	cutscene_active = true
	running = false
	player.set_physics_process(false)
	player.set_process_input(false)
	hud.play_ingredient_cutscene(emoji, display_name, func():
		cutscene_active = false
		_on_level_complete()
	)

func _on_level_complete():
	running = false
	player.level_complete = true
	player.set_physics_process(false)
	player.set_process_input(false)
	AbilityManager.hard_reset()
	reset_world_env()
	var level_name = get_tree().current_scene.name
	print("Saving score under: ", level_name)
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
	player.level_complete = false
	player.burn_meter = 0.0
	player.is_on_burner = false
	AbilityManager.hard_reset()
	reset_world_env()
	player.global_position = spawn_point.global_position
	player.velocity = Vector3.ZERO

func get_medal() -> String:
	if time_elapsed < 30.0:
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
