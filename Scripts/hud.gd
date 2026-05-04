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

var player = null

func _ready():
	popup.visible = false
	stamina_bar.visible = false
	play_again.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	pause_menu.resumed.connect(_on_resumed)
	pause_menu.paused.connect(_on_paused)
	# Wait a frame so the scene is fully loaded before finding the player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _input(event):
	if event.is_action_pressed("ui_cancel") and not popup.visible:
		if pause_menu.visible:
			pause_menu.hide_pause()
		else:
			pause_menu.show_pause()

func _process(_delta):
	if player:
		stamina_bar.value = player.get_stamina_percent() * 100
		# Only show stamina bar when sprinting or stamina is not full
		stamina_bar.visible = player.is_sprinting or player.stamina < player.MAX_STAMINA
		if player.stamina < 25.0:
			stamina_bar.modulate = Color(1, 0.2, 0.2)
		else:
			stamina_bar.modulate = Color(0.2, 1, 0.4)

func _on_paused():
	stamina_bar.visible = false
	timer_label.visible = false

func _on_resumed():
	stamina_bar.visible = true
	timer_label.visible = true

func update_timer(time_string: String):
	timer_label.text = time_string

func show_complete(medal: String, time_string: String, is_new_best: bool, best_time: String):
	popup.visible = true
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
