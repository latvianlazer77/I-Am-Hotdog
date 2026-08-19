extends Control

@onready var title_label = $CanvasLayer/MainMenuUI/TitleLabel
@onready var play_button = $CanvasLayer/MainMenuUI/VBoxContainer/PlayButton
@onready var options_button = $CanvasLayer/MainMenuUI/VBoxContainer/OptionsButton
@onready var shop_button = $CanvasLayer/MainMenuUI/VBoxContainer/ShopButton
@onready var quit_button = $CanvasLayer/MainMenuUI/VBoxContainer/QuitButton

@onready var options_popup = $CanvasLayer/MainMenuUI/OptionsPopup
@onready var shop_popup = $CanvasLayer/MainMenuUI/ShopPopup
@onready var coin_text = $CanvasLayer/MainMenuUI/ShopPopup/CoinText

# === SHOP SCREENS ===
@onready var selection_screen = $"CanvasLayer/MainMenuUI/ShopPopup/Selection Screen"
@onready var skins_screen = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen
@onready var abilities_screen = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen

# === SHOP NAVIGATION & CLOSE BUTTONS ===
@onready var btn_go_skins = $"CanvasLayer/MainMenuUI/ShopPopup/Selection Screen/SkinsOptionButton"
@onready var btn_go_abilities = $"CanvasLayer/MainMenuUI/ShopPopup/Selection Screen/AbilitiesOptionButton"
@onready var close_shop_button_skins = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen/CloseShopButton
@onready var close_shop_button_abilities = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/CloseShopButton

# === SKIN BUTTONS (Inside HBoxContainer) ===
@onready var btn_regular = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen/HBoxContainer/BtnRegular
@onready var btn_silver = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen/HBoxContainer/BtnSilver
@onready var btn_india = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen/HBoxContainer/BtnIndia
@onready var btn_iceman = $CanvasLayer/MainMenuUI/ShopPopup/SkinsScreen/HBoxContainer/BtnIceman

# === ABILITY BUTTONS (Inside HBoxContainer) ===
@onready var btn_ketchup = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnKetchup
@onready var btn_mustard = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnMustard
@onready var btn_bun = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnBun
@onready var btn_hotsauce = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnHotsauce
@onready var btn_pickle = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnPickle
@onready var btn_relish = $CanvasLayer/MainMenuUI/ShopPopup/AbilitiesScreen/HBoxContainer/BtnRelish

@onready var menu_hotdog = $SubViewportContainer/SubViewport/MenuHotdog
@onready var menu_hotdog_mesh = $SubViewportContainer/SubViewport/MenuHotdog/Sausage

@onready var buttons = $CanvasLayer/MainMenuUI/VBoxContainer
@onready var main_menu_ui = $CanvasLayer/MainMenuUI
@onready var level_select_ui = $CanvasLayer/LevelSelectUI
@onready var back_button = $CanvasLayer/LevelSelectUI/BackButton

var hotdog_speed = 4.5
var hotdog_rest_z = 0.0
var transitioning = false

# Prices
const SILVER_PRICE = 100
const INDIA_PRICE = 67
const ICEMAN_PRICE = 36
const MAX_ABILITY_LEVEL = 5

# === CUSTOM ABILITY PRICING ===
# "base" is the cost for level 1. 
# "multiplier" is how much the price increases per level.
const ABILITY_PRICES = {
	"ketchup":  {"base": 10,  "multiplier": 10},
	"mustard":  {"base": 30,  "multiplier": 20},
	"bun":      {"base": 50,  "multiplier": 30},
	"pickle":   {"base": 60,  "multiplier": 40},
	"hotsauce": {"base": 80, "multiplier": 50}, # Expensive OP Distance!
	"relish":   {"base": 100, "multiplier": 60}  # Expensive OP Speed!
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	options_popup.visible = false
	level_select_ui.visible = false
	shop_popup.visible = false
	
	# === SAFE CONNECTIONS ===
	if play_button: play_button.pressed.connect(_on_play)
	else: printerr("MISSING NODE: play_button")
		
	if options_button: options_button.pressed.connect(_on_options)
	else: printerr("MISSING NODE: options_button")
		
	if shop_button: shop_button.pressed.connect(_on_shop)
	else: printerr("MISSING NODE: shop_button")
		
	if quit_button: quit_button.pressed.connect(_on_quit)
	else: printerr("MISSING NODE: quit_button")
		
	if back_button: back_button.pressed.connect(_on_back)
	else: printerr("MISSING NODE: back_button")

	var options_close = $CanvasLayer/MainMenuUI/OptionsPopup/CloseButton
	if options_close: options_close.pressed.connect(func(): options_popup.visible = false)
	else: printerr("MISSING NODE: OptionsPopup CloseButton")
	
	if close_shop_button_skins: close_shop_button_skins.pressed.connect(_close_shop)
	else: printerr("MISSING NODE: close_shop_button_skins")
		
	if close_shop_button_abilities: close_shop_button_abilities.pressed.connect(_close_shop)
	else: printerr("MISSING NODE: close_shop_button_abilities")
	
	if btn_go_skins: btn_go_skins.pressed.connect(show_skins_screen)
	else: printerr("MISSING NODE: btn_go_skins")
		
	if btn_go_abilities: btn_go_abilities.pressed.connect(show_abilities_screen)
	else: printerr("MISSING NODE: btn_go_abilities")
	
	if btn_regular: btn_regular.pressed.connect(_on_regular_skin_pressed)
	if btn_silver: btn_silver.pressed.connect(_on_silver_skin_pressed)
	if btn_india: btn_india.pressed.connect(_on_india_skin_pressed)
	if btn_iceman: btn_iceman.pressed.connect(_on_iceman_skin_pressed)
	
	if btn_ketchup: btn_ketchup.pressed.connect(func(): handle_ability_button("ketchup"))
	if btn_mustard: btn_mustard.pressed.connect(func(): handle_ability_button("mustard"))
	if btn_bun: btn_bun.pressed.connect(func(): handle_ability_button("bun"))
	if btn_hotsauce: btn_hotsauce.pressed.connect(func(): handle_ability_button("hotsauce"))
	if btn_pickle: btn_pickle.pressed.connect(func(): handle_ability_button("pickle"))
	if btn_relish: btn_relish.pressed.connect(func(): handle_ability_button("relish"))
	
	# Load shop and 3D skin on startup
	refresh_shop_ui()
	update_menu_hotdog_skin()
	
	title_label.modulate = Color(1, 1, 1, 0)
	title_label.scale = Vector2(0.1, 0.1)
	buttons.modulate = Color(1, 1, 1, 0)
	menu_hotdog.position.z = hotdog_rest_z
	await get_tree().create_timer(0.3).timeout
	play_title_animation()

func play_title_animation():
	var tween = create_tween()
	tween.tween_property(title_label, "scale", Vector2(1.3, 1.3), 0.3).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.parallel().tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(title_label, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(title_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_interval(0.2)
	tween.tween_property(buttons, "modulate", Color(1, 1, 1, 1), 0.5)

func _on_play():
	if transitioning:
		return
	transitioning = true
	play_button.disabled = true
	options_button.disabled = true
	shop_button.disabled = true 
	quit_button.disabled = true

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC) 
	
	tween.tween_property(main_menu_ui, "modulate:a", 0.0, 0.2)
	
	tween.set_parallel(true) 
	
	var rolling_part = menu_hotdog.get_child(0)
	tween.tween_property(menu_hotdog, "position:z", -8.0, 3.0)
	tween.tween_property(rolling_part, "rotation:x", rolling_part.rotation.x + (PI * 2), 3.0)
	
	tween.set_parallel(false) 
	
	await tween.finished

	level_select_ui.visible = true
	level_select_ui.modulate.a = 0.0
	
	var tween2 = create_tween()
	tween2.tween_property(level_select_ui, "modulate:a", 1.0, 0.2)

func _on_back():
	level_select_ui.visible = false
	transitioning = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.3)
	
	tween.set_parallel(true)
	
	var rolling_part = menu_hotdog.get_child(0)
	tween.tween_property(menu_hotdog, "position:z", hotdog_rest_z, 2.0)
	tween.tween_property(rolling_part, "rotation:x", rolling_part.rotation.x - (PI * 2), 2.0)
	
	tween.set_parallel(false)
	
	await tween.finished
	
	play_button.disabled = false
	options_button.disabled = false
	shop_button.disabled = false 
	quit_button.disabled = false

func _on_options():
	options_popup.visible = true
	
func _on_shop():
	show_selection_screen() 
	refresh_shop_ui()
	shop_popup.visible = true

func _close_shop():
	shop_popup.visible = false
	show_selection_screen() 

# ==========================================
# SHOP NAVIGATION
# ==========================================

func show_selection_screen():
	selection_screen.visible = true
	skins_screen.visible = false
	abilities_screen.visible = false

func show_skins_screen():
	selection_screen.visible = false
	skins_screen.visible = true
	abilities_screen.visible = false

func show_abilities_screen():
	selection_screen.visible = false
	skins_screen.visible = false
	abilities_screen.visible = true

# ==========================================
# SCALABLE SHOP SYSTEM (SKINS & ABILITIES)
# ==========================================

func refresh_shop_ui():
	coin_text.text = "Coins: " + str(SaveData.get_coins())
	
	# --- SKINS UPDATE ---
	var equipped = SaveData.get_equipped_skin()
	
	if equipped == "regular" or equipped == "default":
		btn_regular.text = "EQUIPPED"
		btn_regular.disabled = true
	else:
		btn_regular.text = "EQUIP REGULAR"
		btn_regular.disabled = false
		
	if equipped == "silver":
		btn_silver.text = "EQUIPPED"
		btn_silver.disabled = true
	elif SaveData.is_skin_owned("silver"):
		btn_silver.text = "EQUIP SILVER"
		btn_silver.disabled = false
	else:
		btn_silver.text = "BUY SILVER (" + str(SILVER_PRICE) + " Coins)"
		btn_silver.disabled = false
		
	if equipped == "india":
		btn_india.text = "EQUIPPED"
		btn_india.disabled = true
	elif SaveData.is_skin_owned("india"):
		btn_india.text = "EQUIP INDIA"
		btn_india.disabled = false
	else:
		btn_india.text = "BUY INDIA (" + str(INDIA_PRICE) + " Coins)"
		btn_india.disabled = false
		
	if equipped == "iceman":
		btn_iceman.text = "EQUIPPED"
		btn_iceman.disabled = true
	elif SaveData.is_skin_owned("iceman"):
		btn_iceman.text = "EQUIP ICEMAN"
		btn_iceman.disabled = false
	else:
		btn_iceman.text = "BUY ICEMAN (" + str(ICEMAN_PRICE) + " Coins)"
		btn_iceman.disabled = false

	# --- ABILITIES UPDATE ---
	update_ability_button_text(btn_ketchup, "ketchup", "Ketchup")
	update_ability_button_text(btn_mustard, "mustard", "Mustard")
	update_ability_button_text(btn_bun, "bun", "Bun")
	update_ability_button_text(btn_hotsauce, "hotsauce", "Hot Sauce")
	update_ability_button_text(btn_pickle, "pickle", "Pickle")
	if btn_relish:
		update_ability_button_text(btn_relish, "relish", "Relish")

func update_ability_button_text(btn: Button, ability_id: String, display_name: String):
	var upgrade_stat = ""
	match ability_id:
		"ketchup": upgrade_stat = "Speed"
		"mustard": upgrade_stat = "Duration"
		"bun": upgrade_stat = "Duration"
		"hotsauce": upgrade_stat = "Distance"
		"pickle": upgrade_stat = "Duration"
		"relish": upgrade_stat = "Speed"

	var level = SaveData.get_ingredient_level(ability_id)
	
	if level >= MAX_ABILITY_LEVEL:
		btn.text = display_name + " (MAX LEVEL)"
		btn.disabled = true
	else:
		# Use the brand new Dictionary to get the specific cost for THIS item!
		var item_data = ABILITY_PRICES.get(ability_id, {"base": 50, "multiplier": 25}) # Fallback just in case
		var cost = item_data["base"] + (level * item_data["multiplier"])
		
		if level == 0:
			btn.text = "BUY " + display_name + "\n" + upgrade_stat + " (" + str(cost) + " Coins)"
		else:
			btn.text = "UPGRADE " + display_name + "\n" + upgrade_stat + " Lvl " + str(level + 1) + " (" + str(cost) + " Coins)"
		btn.disabled = false

func handle_skin_button(skin_name: String, price: int):
	if skin_name == "regular" or skin_name == "default":
		SaveData.equip_skin("regular")
	elif SaveData.get_equipped_skin() == skin_name:
		return 
	elif SaveData.is_skin_owned(skin_name):
		SaveData.equip_skin(skin_name)
	else:
		if SaveData.spend_coins(price):
			SaveData.unlock_skin(skin_name)
			SaveData.equip_skin(skin_name)
		else:
			print("Not enough coins for " + skin_name + "!")
			
	refresh_shop_ui()
	update_menu_hotdog_skin()

func handle_ability_button(ability_name: String):
	var current_level = SaveData.get_ingredient_level(ability_name)
	if current_level >= MAX_ABILITY_LEVEL:
		return
		
	# Calculate custom cost using the Dictionary here as well!
	var item_data = ABILITY_PRICES.get(ability_name, {"base": 50, "multiplier": 25})
	var cost = item_data["base"] + (current_level * item_data["multiplier"])
	
	if SaveData.spend_coins(cost):
		SaveData.upgrade_ingredient(ability_name)
		print(ability_name + " upgraded to level ", SaveData.get_ingredient_level(ability_name))
	else:
		print("Not enough coins for " + ability_name + " upgrade!")
		
	refresh_shop_ui()

func _on_regular_skin_pressed():
	handle_skin_button("regular", 0)

func _on_silver_skin_pressed():
	handle_skin_button("silver", SILVER_PRICE)

func _on_india_skin_pressed():
	handle_skin_button("india", INDIA_PRICE)

func _on_iceman_skin_pressed(): 
	handle_skin_button("iceman", ICEMAN_PRICE)

# ==========================================
# APPLY SKIN TO MENU 3D MODEL
# ==========================================

func update_menu_hotdog_skin():
	if not menu_hotdog_mesh:
		return 
		
	var current_skin = SaveData.get_equipped_skin()
	
	match current_skin:
		"silver":
			var silver_mat = preload("res://Materials/silver_surfer.tres")
			menu_hotdog_mesh.set_surface_override_material(0, silver_mat)
		"india": 
			var india_mat = preload("res://Materials/india.tres")
			menu_hotdog_mesh.set_surface_override_material(0, india_mat)
		"iceman": 
			var iceman_mat = preload("res://Materials/ice.tres")
			menu_hotdog_mesh.set_surface_override_material(0, iceman_mat)
		_: 
			var classic_mat = preload("res://Materials/classic.tres")
			menu_hotdog_mesh.set_surface_override_material(0, classic_mat)

func _on_quit():
	get_tree().quit()
