extends Control

@onready var title_label = $CanvasLayer/MainMenuUI/TitleLabel
@onready var play_button = $CanvasLayer/MainMenuUI/VBoxContainer/PlayButton
@onready var options_button = $CanvasLayer/MainMenuUI/VBoxContainer/OptionsButton
@onready var quit_button = $CanvasLayer/MainMenuUI/VBoxContainer/QuitButton
@onready var options_popup = $CanvasLayer/MainMenuUI/OptionsPopup
@onready var menu_hotdog = $SubViewportContainer/SubViewport/MenuHotdog
@onready var buttons = $CanvasLayer/MainMenuUI/VBoxContainer
@onready var main_menu_ui = $CanvasLayer/MainMenuUI
@onready var level_select_ui = $CanvasLayer/LevelSelectUI
@onready var back_button = $CanvasLayer/LevelSelectUI/BackButton

var hotdog_speed = 4.5
var hotdog_rest_z = 0.0
var transitioning = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	options_popup.visible = false
	level_select_ui.visible = false
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	back_button.pressed.connect(_on_back)
	$CanvasLayer/MainMenuUI/OptionsPopup/CloseButton.pressed.connect(
		func(): options_popup.visible = false
	)
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
	quit_button.disabled = false
	menu_hotdog.position.z = hotdog_rest_z
	var tween = create_tween()
	tween.tween_property(main_menu_ui, "modulate:a", 1.0, 0.3)

func _on_options():
	options_popup.visible = true

func _on_quit():
	get_tree().quit()
