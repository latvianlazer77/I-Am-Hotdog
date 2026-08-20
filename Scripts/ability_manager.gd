extends Node

# These are now the BASE stats for Level 1
const BASE_COOLDOWNS = {
	"ketchup": 10.0,
	"mustard": 20.0,
	"bun": 18.0,
	"hotsauce": 8.0,
	"pickle": 15.0,
	"relish": 1.0
}

const ABILITY_DURATIONS = {
	"ketchup": 15.0,
	"mustard": 6.0,
	"bun": 6.0,
	"hotsauce": 0.0,
	"pickle": 8.0,
	"relish": 99999.0
}

var cooldowns = {"ketchup": 0.0, "mustard": 0.0, "bun": 0.0, "hotsauce": 0.0, "pickle": 0.0, "relish": 0.0}
var active = {"ketchup": false, "mustard": false, "bun": false, "hotsauce": false, "pickle": false, "relish": false}
var timers = {"ketchup": 0.0, "mustard": 0.0, "bun": 0.0, "hotsauce": 0.0, "pickle": 0.0, "relish": 0.0}

var paused = false

signal ability_activated(ability_name)
signal ability_ended(ability_name)
signal cooldown_updated(ability_name, remaining)

# ==========================================
# UPGRADE MATH FUNCTIONS
# ==========================================
func get_max_duration(ability_name: String) -> float:
	var level = SaveData.get_ingredient_level(ability_name)
	if level <= 0: return 0.0
	
	var extra_time = (level - 1) * 2.0 
	# Make sure it reads from ABILITY_DURATIONS here too!
	return ABILITY_DURATIONS[ability_name] + extra_time
func get_max_cooldown(ability_name: String) -> float:
	var level = SaveData.get_ingredient_level(ability_name)
	if level <= 0: return 999.0
	
	# Formula: Reduces cooldown by 1 second for every upgrade level above 1
	var reduced_time = (level - 1) * 1.0
	return max(BASE_COOLDOWNS[ability_name] - reduced_time, 1.0) # Never goes below 1 second

# ==========================================
# CORE ABILITY LOGIC
# ==========================================
func _process(delta):
	if paused:
		return

	for ability in cooldowns.keys():
		if cooldowns[ability] > 0:
			cooldowns[ability] = max(cooldowns[ability] - delta, 0.0)
			emit_signal("cooldown_updated", ability, cooldowns[ability])

		if active[ability] and get_max_duration(ability) > 0 and ability != "relish":
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
	timers[ability_name] = get_max_duration(ability_name)
	emit_signal("ability_activated", ability_name)
	
	# For instant abilities with 0 duration, start cooldown immediately
	if get_max_duration(ability_name) == 0.0:
		active[ability_name] = false
		cooldowns[ability_name] = get_max_cooldown(ability_name)
		emit_signal("ability_ended", ability_name)

func deactivate(ability_name: String):
	if not active[ability_name]:
		return
	active[ability_name] = false
	cooldowns[ability_name] = get_max_cooldown(ability_name)
	emit_signal("ability_ended", ability_name)

func reset_all():
	for ability in active.keys():
		if active[ability]:
			emit_signal("ability_ended", ability)
			cooldowns[ability] = get_max_cooldown(ability)
		active[ability] = false
		timers[ability] = 0.0

func hard_reset():
	paused = false
	for ability in active.keys():
		if active[ability] and ability != "relish":
			emit_signal("ability_ended", ability)
		active[ability] = false
		cooldowns[ability] = 0.0
		timers[ability] = 0.0

func pause_abilities():
	paused = true

func resume_abilities():
	paused = false

func is_active(ability_name: String) -> bool:
	return active[ability_name]

func get_cooldown_percent(ability_name: String) -> float:
	var max_cd = get_max_cooldown(ability_name)
	if max_cd == 0:
		return 0.0
	return cooldowns[ability_name] / max_cd
