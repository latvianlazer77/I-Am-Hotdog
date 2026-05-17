extends Control

@onready var title_label = $CanvasLayer/TitleLabel
@onready var play_button = $CanvasLayer/VBoxContainer/PlayButton
@onready var options_button = $CanvasLayer/VBoxContainer/OptionsButton
@onready var quit_button = $CanvasLayer/VBoxContainer/QuitButton
@onready var options_popup = $CanvasLayer/OptionsPopup
@onready var menu_hotdog = $SubViewportContainer/SubViewport/MenuHotdog
@onready var buttons = $CanvasLayer/VBoxContainer

var hotdog_speed = 5.0
var hotdog_start_x = -5.0
var hotdog_end_x = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	options_popup.visible = false
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)
	$CanvasLayer/OptionsPopup/CloseButton.pressed.connect(func(): options_popup.visible = false)

	# Hide everything initially
	title_label.modulate = Color(1, 1, 1, 0)
	title_label.scale = Vector2(0.1, 0.1)
	buttons.modulate = Color(1, 1, 1, 0)

	# Start hotdog off screen
	menu_hotdog.position.x = hotdog_start_x

	# Play title animation then buttons
	await get_tree().create_timer(0.3).timeout
	play_title_animation()

func play_title_animation():
	# Title slams in with bounce
	var tween = create_tween()
	tween.tween_property(title_label, "scale", Vector2(1.3, 1.3), 0.3).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.parallel().tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(title_label, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(title_label, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.08)
	# Buttons fade in after title
	tween.tween_interval(0.2)
	tween.tween_property(buttons, "modulate", Color(1, 1, 1, 1), 0.5)

func _process(delta):
	if not menu_hotdog:
		return
	menu_hotdog.position.z -= hotdog_speed * delta
	menu_hotdog.get_child(0).rotate_x(-hotdog_speed * delta * 0.5)
	if menu_hotdog.position.z < -hotdog_end_x:
		menu_hotdog.position.z = hotdog_start_x

func _on_play():
	get_tree().change_scene_to_file("res://Scenes/Menus/level_select.tscn")

func _on_options():
	options_popup.visible = true

func _on_quit():
	get_tree().quit()
