extends Control

@onready var title_label = $CanvasLayer/MainMenuUI/TitleLabel
@onready var play_button = $CanvasLayer/MainMenuUI/VBoxContainer/PlayButton
@onready var options_button = $CanvasLayer/MainMenuUI/VBoxContainer/OptionsButton
# --- NEW SHOP BUTTON ---
@onready var shop_button = $CanvasLayer/MainMenuUI/VBoxContainer/ShopButton
@onready var quit_button = $CanvasLayer/MainMenuUI/VBoxContainer/QuitButton

@onready var options_popup = $CanvasLayer/MainMenuUI/OptionsPopup
# --- NEW SHOP POPUP NODES ---
@onready var shop_popup = $CanvasLayer/MainMenuUI/ShopPopup
@onready var coin_text = $CanvasLayer/MainMenuUI/ShopPopup/CoinText
@onready var btn_regular = $CanvasLayer/MainMenuUI/ShopPopup/BtnRegular
@onready var btn_silver = $CanvasLayer/MainMenuUI/ShopPopup/BtnSilver
@onready var close_shop_button = $CanvasLayer/MainMenuUI/ShopPopup/CloseShopButton

@onready var menu_hotdog = $SubViewportContainer/SubViewport/MenuHotdog
@onready var buttons = $CanvasLayer/MainMenuUI/VBoxContainer
@onready var main_menu_ui = $CanvasLayer/MainMenuUI
@onready var level_select_ui = $CanvasLayer/LevelSelectUI
@onready var back_button = $CanvasLayer/LevelSelectUI/BackButton

var hotdog_speed = 4.5
var hotdog_rest_z = 0.0
var transitioning = false
const SILVER_PRICE = 100

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	options_popup.visible = false
	level_select_ui.visible = false
	shop_popup.visible = false # Hide shop on start
	
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	shop_button.pressed.connect(_on_shop) # Connect shop button
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_back)
	
	$CanvasLayer/MainMenuUI/OptionsPopup/CloseButton.pressed.connect(
		func(): options_popup.visible = false
	)
	
	# Connect Shop Popup Buttons
	close_shop_button.pressed.connect(func(): shop_popup.visible = false)
	btn_regular.pressed.connect(_on_regular_skin_pressed)
	btn_silver.pressed.connect(_on_silver_skin_pressed)
	
	refresh_shop_ui()
	
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
	if not menu_hotdog:
		return
	if transitioning:
		menu_hotdog.get_child(0).rotate_x(-hotdog_speed * delta * 0.5)

func _on_play():
	if transitioning:
		return
	transitioning = true
	play_button.disabled = true
	options_button.disabled = true
	shop_button.disabled = true # Lock shop button
	quit_button.disabled = true

	var tween = create_tween()
	tween.tween_property(main_menu_ui, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(
		menu_hotdog,
		"position:z",
		-8.0,
		2.0
	).set_trans(Tween.TRANS_SINE)
	await tween.finished

	level_select_ui.visible = true
	level_select_ui.modulate.a = 0.0
	var tween2 = create_tween()
	tween2.tween_property(level_select_ui, "modulate:a", 1.0, 0.2)

func _on_back():
	level_select_ui.visible = false
	transitioning = false
	play_button.disabled = false
	options_button.disabled = false
	shop_button.disabled = false # Unlock shop button
	quit_button.disabled = false
	menu_hotdog.position.z = hotdog_rest_z
	var tween = create_tween()
	tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.3)

func _on_options():
	options_popup.visible = true
	
func _on_shop():
	refresh_shop_ui() # Make sure coin count is up to date
	shop_popup.visible = true

func _on_quit():
	get_tree().quit()

# ==========================================
# SHOP UI LOGIC
# ==========================================

func refresh_shop_ui():
	coin_text.text = "Coins: " + str(SaveData.get_coins())
	
	var equipped = SaveData.get_equipped_skin()
	
	# Regular Skin Check (You always own this one!)
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

func _on_regular_skin_pressed():
	SaveData.equip_skin("regular")
	refresh_shop_ui()

func _on_silver_skin_pressed():
	if SaveData.is_skin_owned("silver"):
		SaveData.equip_skin("silver")
	else:
		if SaveData.spend_coins(SILVER_PRICE):
			SaveData.unlock_skin("silver")
			SaveData.equip_skin("silver")
		else:
			print("Not enough coins!")
			
	refresh_shop_ui()
