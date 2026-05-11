extends CanvasLayer

@onready var timer_label = $TimerLabel
@onready var popup = $LevelCompletePopup
@onready var medal_label = $LevelCompletePopup/MedalLabel
@onready var new_best_label = $LevelCompletePopup/NewBestLabel
@onready var best_time_label = $LevelCompletePopup/BestTimeLabel
@onready var play_again = $LevelCompletePopup/PlayAgainButton
@onready var main_menu_button = $LevelCompletePopup/MainMenuButton
@onready var pause_menu = $PauseMenu
@onready var stamina_bar = $StaminaBar
@onready var burn_bar = $BurnBar
@onready var burn_overlay = $BurnOverlay
@onready var cutscene_layer = $CutsceneLayer
@onready var flash = $CutsceneLayer/Flash
@onready var fade_overlay = $CutsceneLayer/FadeOverlay
@onready var cutscene_text = $CutsceneLayer/CutsceneText
@onready var ingredient_label = $CutsceneLayer/IngredientLabel
@onready var interact_prompt = $InteractPrompt

var player = null
var on_complete_callback = null
var float_tween = null
var spin_tween = null

func _ready():
	popup.visible = false
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false
	cutscene_layer.visible = false
	play_again.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	pause_menu.resumed.connect(_on_resumed)
	pause_menu.paused.connect(_on_paused)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _input(event):
	if event.is_action_pressed("ui_cancel") and not popup.visible and not cutscene_layer.visible:
		if pause_menu.visible:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()

func _process(_delta):
	if player and not popup.visible and not cutscene_layer.visible:
		stamina_bar.value = player.get_stamina_percent() * 100
		stamina_bar.visible = player.is_sprinting or player.stamina < player.MAX_STAMINA
		if player.stamina < 25.0:
			stamina_bar.modulate = Color(1, 0.2, 0.2)
		else:
			stamina_bar.modulate = Color(0.2, 1, 0.4)

		var burn = player.get_burn_percent()
		if burn > 0:
			burn_bar.visible = true
			burn_bar.value = burn * 100
			burn_overlay.visible = true
			burn_overlay.color = Color(1, 0, 0, burn * 0.6)
			if burn > 0.75:
				burn_bar.modulate = Color(1, 0.1, 0.1)
			elif burn > 0.5:
				burn_bar.modulate = Color(1, 0.5, 0.0)
			else:
				burn_bar.modulate = Color(1, 1, 0.0)
		else:
			burn_bar.visible = false
			burn_overlay.visible = false
			burn_overlay.color = Color(1, 0, 0, 0)

func show_interact_prompt(show: bool):
	interact_prompt.visible = show

func play_ingredient_cutscene(emoji: String, display_name: String, on_complete: Callable):
	on_complete_callback = on_complete

	# Hide all HUD elements
	timer_label.visible = false
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false
	burn_overlay.color = Color(1, 0, 0, 0)

	# Show cutscene layer
	cutscene_layer.visible = true
	cutscene_text.text = ""
	ingredient_label.text = ""
	flash.color = Color(1, 1, 1, 0)
	fade_overlay.color = Color(0, 0, 0, 0)

	# Make hotdog float and spin
	if player:
		float_tween = create_tween().set_loops()
		float_tween.tween_property(player, "position:y", player.global_position.y + 0.5, 0.8)
		float_tween.tween_property(player, "position:y", player.global_position.y, 0.8)
		spin_tween = create_tween().set_loops()
		spin_tween.tween_property(player.get_node("Sausage"), "rotation:y", TAU, 1.5)

	var tween = create_tween()

	# Phase 1 — fade to dark (0-0.5s)
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0.85), 0.5)

	# Phase 2 — energy buildup, screen shakes (0.5-2.5s)
	tween.tween_callback(func():
		start_energy_buildup()
	)
	tween.tween_interval(2.0)

	# Phase 3 — white flash (2.5-3s)
	tween.tween_property(flash, "color", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(flash, "color", Color(1, 1, 1, 0), 0.3)

	# Phase 4 — dramatic text appears letter by letter (3-5.5s)
	tween.tween_callback(func():
		var full_text = "THE HOTDOG HAS OBTAINED..."
		type_text(cutscene_text, full_text, 0.06)
	)
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		type_text(ingredient_label, emoji + " " + display_name + " " + emoji, 0.08)
	)
	tween.tween_interval(2.0)

	# Phase 5 — fade out (5.5-6s)
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.5)
	tween.tween_callback(func():
		# Stop floating and spinning
		if float_tween:
			float_tween.kill()
		if spin_tween:
			spin_tween.kill()
		if player:
			player.get_node("Sausage").rotation.y = 0.0
		cutscene_layer.visible = false
		timer_label.visible = true
		if on_complete_callback:
			on_complete_callback.call()
	)

func start_energy_buildup():
	# Shake the camera rapidly to simulate energy buildup
	if player:
		var shake_tween = create_tween().set_loops(20)
		shake_tween.tween_property(player.get_node("CameraPivot"), "rotation:z", 0.03, 0.05)
		shake_tween.tween_property(player.get_node("CameraPivot"), "rotation:z", -0.03, 0.05)

func type_text(label: Label, full_text: String, speed: float):
	label.text = ""
	var tween = create_tween()
	for i in range(full_text.length()):
		tween.tween_callback(func():
			if label.text.length() < full_text.length():
				label.text += full_text[label.text.length()]
		)
		tween.tween_interval(speed)

func _on_paused():
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false

func _on_resumed():
	pass

func update_timer(time_string: String):
	timer_label.text = time_string

func show_complete(medal: String, time_string: String, is_new_best: bool, best_time: String):
	popup.visible = true
	timer_label.visible = false
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false
	burn_overlay.color = Color(1, 0, 0, 0)
	medal_label.text = "You got " + medal + "!\nTime: " + time_string
	new_best_label.visible = is_new_best
	new_best_label.text = "NEW BEST!"
	best_time_label.text = "Best: " + best_time
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	match medal:
		"GOLD":
			medal_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
		"SILVER":
			medal_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		"BRONZE":
			medal_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))

func _on_play_again():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func _on_main_menu():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")
