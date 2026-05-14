extends Node

const ABILITY_COOLDOWNS = {
	"ketchup": 10.0,
	"mustard": 20.0,
	"bun": 18.0,
	"hotsauce": 8.0,
	"pickle": 15.0,
	"relish": 0.0
}

const ABILITY_DURATIONS = {
	"ketchup": 15.0,
	"mustard": 6.0,
	"bun": 6.0,
	"hotsauce": 0.0,
	"pickle": 8.0,
	"relish": 0.0
}

var cooldowns = {
	"ketchup": 0.0,
	"mustard": 0.0,
	"bun": 0.0,
	"hotsauce": 0.0,
	"pickle": 0.0,
	"relish": 0.0
}

var active = {
	"ketchup": false,
	"mustard": false,
	"bun": false,
	"hotsauce": false,
	"pickle": false,
	"relish": false
}

var timers = {
	"ketchup": 0.0,
	"mustard": 0.0,
	"bun": 0.0,
	"hotsauce": 0.0,
	"pickle": 0.0,
	"relish": 0.0
}

var paused = false

signal ability_activated(ability_name)
signal ability_ended(ability_name)
signal cooldown_updated(ability_name, remaining)

func _process(delta):
	if paused:
		return

	for ability in cooldowns.keys():
		if cooldowns[ability] > 0:
			cooldowns[ability] = max(cooldowns[ability] - delta, 0.0)
			emit_signal("cooldown_updated", ability, cooldowns[ability])

		if active[ability]:
			timers[ability] = max(timers[ability] - delta, 0.0)
			if timers[ability] <= 0.0:
				deactivate(ability)

func can_use(ability_name: String) -> bool:
	if not SaveData:
		return false
	if not SaveData.has_ingredient(ability_name):
		return false
	if cooldowns[ability_name] > 0:
		return false
	if active[ability_name]:
		return false
	return true

func activate(ability_name: String):
	if not can_use(ability_name):
		return
	active[ability_name] = true
	timers[ability_name] = ABILITY_DURATIONS[ability_name]
	emit_signal("ability_activated", ability_name)

func deactivate(ability_name: String):
	active[ability_name] = false
	cooldowns[ability_name] = ABILITY_COOLDOWNS[ability_name]
	emit_signal("ability_ended", ability_name)

func reset_all():
	for ability in active.keys():
		if active[ability]:
			emit_signal("ability_ended", ability)
		active[ability] = false
		timers[ability] = 0.0

func pause_abilities():
	paused = true

func resume_abilities():
	paused = false

func is_active(ability_name: String) -> bool:
	return active[ability_name]

func get_cooldown_percent(ability_name: String) -> float:
	if ABILITY_COOLDOWNS[ability_name] == 0:
		return 0.0
	return cooldowns[ability_name] / ABILITY_COOLDOWNS[ability_name]

func hard_reset():
	paused = false
	for ability in active.keys():
		if active[ability]:
			emit_signal("ability_ended", ability)
		active[ability] = false
		cooldowns[ability] = 0.0
		timers[ability] = 0.0
	
