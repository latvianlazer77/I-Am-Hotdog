extends Node

const SAVE_PATH = "user://scores.cfg"

var config = ConfigFile.new()

func _ready():
	config.load(SAVE_PATH)
	if not config.has_section_key("unlocks", "level_1"):
		config.set_value("unlocks", "level_1", true)
		config.save(SAVE_PATH)

func get_best_time(level_name: String) -> float:
	return config.get_value("scores", level_name, INF)

func save_best_time(level_name: String, time: float):
	config.set_value("scores", level_name, time)
	config.save(SAVE_PATH)

func is_level_unlocked(level_name: String) -> bool:
	if level_name == "level_1":
		return true
	return config.get_value("unlocks", level_name, false)

func unlock_level(level_name: String):
	config.set_value("unlocks", level_name, true)
	config.save(SAVE_PATH)

# ==========================================
# ABILITY & UPGRADE SYSTEM
# ==========================================

func get_ingredient_level(ingredient_name: String) -> int:
	# Get the value, default to 0 if they don't have it
	var val = config.get_value("ingredients", ingredient_name, 0)
	
	# BACKWARDS COMPATIBILITY: 
	# If you have an old save file where it was saved as 'true', convert it to level 1!
	if typeof(val) == TYPE_BOOL:
		if val == true:
			return 1
		else:
			return 0
			
	return val as int

func has_ingredient(ingredient_name: String) -> bool:
	# If the level is 1 or higher, they own it!
	return get_ingredient_level(ingredient_name) > 0

func upgrade_ingredient(ingredient_name: String):
	# Gets the current level and adds 1 to it, then saves it to the hard drive
	var current_level = get_ingredient_level(ingredient_name)
	config.set_value("ingredients", ingredient_name, current_level + 1)
	config.save(SAVE_PATH)
func save_ingredient(ingredient_name: String):
	config.set_value("ingredients", ingredient_name, true)
	config.save(SAVE_PATH)

func is_cutscene_seen(level_name: String) -> bool:
	return config.get_value("cutscenes", level_name, false)

func mark_cutscene_seen(level_name: String):
	config.set_value("cutscenes", level_name, true)
	config.save(SAVE_PATH)

func get_coins() -> int:
	return config.get_value("wallet", "coins", 0)

func add_coins(amount: int):
	var current = get_coins()
	config.set_value("wallet", "coins", current + amount)
	config.save(SAVE_PATH)

func spend_coins(amount: int) -> bool:
	var current = get_coins()
	if current < amount:
		return false
	config.set_value("wallet", "coins", current - amount)
	config.save(SAVE_PATH)
	return true

# ==========================================
# NEW SKIN SYSTEM FUNCTIONS
# ==========================================

func get_equipped_skin() -> String:
	# Returns "default" if the player hasn't equipped anything yet
	return config.get_value("skins", "equipped", "default")

func equip_skin(skin_name: String):
	config.set_value("skins", "equipped", skin_name)
	config.save(SAVE_PATH)

func is_skin_owned(skin_name: String) -> bool:
	if skin_name == "default":
		return true # You always own the default skin!
	# Checks if the config file has "owned_silver" saved as true
	return config.get_value("skins", "owned_" + skin_name, false)

func unlock_skin(skin_name: String):
	config.set_value("skins", "owned_" + skin_name, true)
	config.save(SAVE_PATH)
