extends Control

@onready var title_label = $CanvasLayer/MainMenuUI/TitleLabel
@onready var play_button = $CanvasLayer/MainMenuUI/VBoxContainer/PlayButton
@onready var options_button = $CanvasLayer/MainMenuUI/VBoxContainer/OptionsButton
@onready var shop_button = $CanvasLayer/MainMenuUI/VBoxContainer/ShopButton
@onready var quit_button = $CanvasLayer/MainMenuUI/VBoxContainer/QuitButton

@onready var options_popup = $CanvasLayer/MainMenuUI/OptionsPopup
@onready var shop_popup = $CanvasLayer/MainMenuUI/ShopPopup
@onready var coin_text = $CanvasLayer/MainMenuUI/ShopPopup/CoinText
@onready var btn_regular = $CanvasLayer/MainMenuUI/ShopPopup/BtnRegular
@onready var btn_silver = $CanvasLayer/MainMenuUI/ShopPopup/BtnSilver
@onready var close_shop_button = $CanvasLayer/MainMenuUI/ShopPopup/CloseShopButton

@onready var menu_hotdog = $SubViewportContainer/SubViewport/MenuHotdog
# --- YOUR EXACT MESH PATH ---
@onready var menu_hotdog_mesh = $SubViewportContainer/SubViewport/MenuHotdog/Sausage

@onready var buttons = $CanvasLayer/MainMenuUI/VBoxContainer
@onready var main_menu_ui = $CanvasLayer/MainMenuUI
@onready var level_select_ui = $CanvasLayer/LevelSelectUI
@onready var back_button = $CanvasLayer/LevelSelectUI/BackButton

var hotdog_speed = 4.5
var hotdog_rest_z = 0.0
var transitioning = false

# Prices for the shop
const SILVER_PRICE = 100

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	options_popup.visible = false
	level_select_ui.visible = false
	shop_popup.visible = false
	
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	shop_button.pressed.connect(_on_shop) 
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_back)
	
	$CanvasLayer/MainMenuUI/OptionsPopup/CloseButton.pressed.connect(
		func(): options_popup.visible = false
	)
	
	close_shop_button.pressed.connect(func(): shop_popup.visible = false)
	btn_regular.pressed.connect(_on_regular_skin_pressed)
	btn_silver.pressed.connect(_on_silver_skin_pressed)
	
	# --- LOAD THE SHOP AND 3D SKIN ON STARTUP ---
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

func _process(delta):
	pass

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
	
	# Fade the UI out fast
	tween.tween_property(main_menu_ui, "modulate:a", 0.0, 0.2)
	
	# Force everything below this line to happen AT THE SAME TIME
	tween.set_parallel(true) 
	
	var rolling_part = menu_hotdog.get_child(0)
	tween.tween_property(menu_hotdog, "position:z", -8.0, 3.0)
	tween.tween_property(rolling_part, "rotation:x", rolling_part.rotation.x + (PI * 2), 3.0)
	
	# Turn parallel off for the next step
	tween.set_parallel(false) 
	
	await tween.finished

	level_select_ui.visible = true
	level_select_ui.modulate.a = 0.0
	
	# We use a different name here (tween2) so Godot doesn't get confused!
	var tween2 = create_tween()
	tween2.tween_property(level_select_ui, "modulate:a", 1.0, 0.2)


func _on_back():
	level_select_ui.visible = false
	transitioning = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade the UI back in
	tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.3)
	
	# Force the movement and rotation to link up perfectly
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
	refresh_shop_ui()
	shop_popup.visible = true

func _on_quit():
	get_tree().quit()

# ==========================================
# SCALABLE SHOP SYSTEM
# ==========================================

func refresh_shop_ui():
	coin_text.text = "Coins: " + str(SaveData.get_coins())
	var equipped = SaveData.get_equipped_skin()
	
	# Regular Skin Check
	if equipped == "regular" or equipped == "default":
		btn_regular.text = "EQUIPPED"
		btn_regular.disabled = true
	else:
		btn_regular.text = "EQUIP REGULAR"
		btn_regular.disabled = false
		
	# Silver Skin Check
	if equipped == "silver":
		btn_silver.text = "EQUIPPED"
		btn_silver.disabled = true
	elif SaveData.is_skin_owned("silver"):
		btn_silver.text = "EQUIP SILVER"
		btn_silver.disabled = false
	else:
		btn_silver.text = "BUY SILVER (" + str(SILVER_PRICE) + " Coins)"
		btn_silver.disabled = false

# This ONE function handles the buying/equipping for every single skin!
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

func _on_regular_skin_pressed():
	handle_skin_button("regular", 0)

func _on_silver_skin_pressed():
	handle_skin_button("silver", SILVER_PRICE)

# ==========================================
# APPLY SKIN TO MENU 3D MODEL
# ==========================================

func update_menu_hotdog_skin():
	if not menu_hotdog_mesh:
		return 
		
	var current_skin = SaveData.get_equipped_skin()
	
	match current_skin:
		"silver":
			# Ensure this path matches where you saved your silver material!
			var silver_mat = preload("res://materials/silver_surfer.tres")
			menu_hotdog_mesh.set_surface_override_material(0, silver_mat)
		_: 
			# This underscore "_" is the default catch-all that loads the classic skin
			# Ensure this path matches where you saved your normal hotdog material!
			var classic_mat = preload("res://materials/classic.tres")
			menu_hotdog_mesh.set_surface_override_material(0, classic_mat)
