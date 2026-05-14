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
@onready var ability_bar = $AbilityBar
@onready var mustard_overlay = $MustardOverlay

var player = null
var on_complete_callback = null
var float_tween = null
var spin_tween = null
var mustard_tween = null

const ABILITY_DATA = {
	"ketchup":  {"emoji": "🍅", "key": "Q",     "color": Color(1, 0.2, 0.2)},
	"mustard":  {"emoji": "🟡", "key": "Z",     "color": Color(1, 0.85, 0.0)},
	"bun":      {"emoji": "🌭", "key": "X",     "color": Color(1, 0.8, 0.4)},
	"hotsauce": {"emoji": "🌶️", "key": "R",     "color": Color(1, 0.4, 0.0)},
	"pickle":   {"emoji": "🥒", "key": "F",     "color": Color(0.2, 0.9, 0.2)},
	"relish":   {"emoji": "🧂", "key": "Space", "color": Color(1, 0.9, 0.2)},
}

const ABILITY_ORDER = ["ketchup", "mustard", "bun", "hotsauce", "pickle", "relish"]

func _ready():
	popup.visible = false
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false
	cutscene_layer.visible = false
	timer_label.visible = true
	mustard_overlay.visible = false
	mustard_overlay.material = ShaderMaterial.new()
	mustard_overlay.material.shader = load("res://Scripts/time_freeze.gdshader")
	play_again.pressed.connect(_on_play_again)
	main_menu_button.pressed.connect(_on_main_menu)
	pause_menu.resumed.connect(_on_resumed)
	pause_menu.paused.connect(_on_paused)
	AbilityManager.ability_activated.connect(_on_ability_activated)
	AbilityManager.ability_ended.connect(_on_ability_ended)
	AbilityManager.cooldown_updated.connect(_on_cooldown_updated)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	setup_ability_bar()

func _on_ability_activated(ability_name: String):
	update_slot(ability_name)
	if ability_name == "mustard":
		play_mustard_effect(true)

func _on_ability_ended(ability_name: String):
	update_slot(ability_name)
	if ability_name == "mustard":
		play_mustard_effect(false)

func play_mustard_effect(activating: bool):
	if mustard_tween:
		mustard_tween.kill()
	mustard_overlay.visible = true
	mustard_tween = create_tween()
	if activating:
		mustard_overlay.material.set_shader_parameter("progress", 0.0)
		mustard_tween.tween_method(func(v): mustard_overlay.material.set_shader_parameter("progress", v), 0.0, 1.5, 0.8)
	else:
		mustard_tween.tween_method(func(v): mustard_overlay.material.set_shader_parameter("progress", v), 1.5, 0.0, 0.5)
		mustard_tween.tween_callback(func(): mustard_overlay.visible = false)

func setup_ability_bar():
	for i in range(ABILITY_ORDER.size()):
		var ability = ABILITY_ORDER[i]
		var slot = ability_bar.get_child(i)
		var data = ABILITY_DATA[ability]
		slot.get_node("EmojiLabel").text = data["emoji"]
		slot.get_node("KeyLabel").text = data["key"]
		update_slot(ability)

func update_slot(ability_name: String):
	var i = ABILITY_ORDER.find(ability_name)
	if i == -1:
		return
	if i >= ability_bar.get_child_count():
		return
	var slot = ability_bar.get_child(i)
	if not slot:
		return
	var has_it = SaveData.has_ingredient(ability_name)

	if not has_it:
		slot.visible = false
		return

	slot.visible = true
	var is_active = AbilityManager.is_active(ability_name)
	var cooldown_pct = AbilityManager.get_cooldown_percent(ability_name)
	var overlay = slot.get_node_or_null("DarkOverlay")
	if not overlay:
		return
	var slot_height = slot.size.y

	if is_active:
		var time_pct = AbilityManager.timers[ability_name] / AbilityManager.ABILITY_DURATIONS[ability_name]
		var covered = slot_height * (1.0 - time_pct)
		overlay.position.y = 0
		overlay.size = Vector2(overlay.size.x, covered)
		overlay.color = Color(0, 0, 0, 0.8)
		slot.modulate = Color(1, 1, 1, 1)
	elif cooldown_pct > 0:
		var covered = slot_height * cooldown_pct
		overlay.position.y = 0
		overlay.size = Vector2(overlay.size.x, covered)
		overlay.color = Color(0, 0, 0, 0.8)
		slot.modulate = Color(1, 1, 1, 1)
	else:
		overlay.size = Vector2(overlay.size.x, 0)
		slot.modulate = Color(1, 1, 1, 1)

func _on_cooldown_updated(ability_name: String, _remaining: float):
	update_slot(ability_name)

func show_interact_prompt(show: bool):
	interact_prompt.visible = show

func play_ingredient_cutscene(emoji: String, display_name: String, on_complete: Callable):
	on_complete_callback = on_complete
	timer_label.visible = false
	stamina_bar.visible = false
	burn_bar.visible = false
	burn_overlay.visible = false
	burn_overlay.color = Color(1, 0, 0, 0)
	ability_bar.visible = false
	cutscene_layer.visible = true
	cutscene_text.text = ""
	ingredient_label.text = ""
	flash.color = Color(1, 1, 1, 0)
	fade_overlay.color = Color(0, 0, 0, 0)

	if player:
		float_tween = create_tween().set_loops()
		float_tween.tween_property(player, "position:y", player.global_position.y + 0.5, 0.8)
		float_tween.tween_property(player, "position:y", player.global_position.y, 0.8)
		spin_tween = create_tween().set_loops()
		spin_tween.tween_property(player.get_node("Sausage"), "rotation:y", TAU, 1.5)

	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0.85), 0.5)
	tween.tween_callback(func(): start_energy_buildup())
	tween.tween_interval(2.0)
	tween.tween_property(flash, "color", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(flash, "color", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): type_text(cutscene_text, "THE HOTDOG HAS OBTAINED...", 0.06))
	tween.tween_interval(1.5)
	tween.tween_callback(func(): type_text(ingredient_label, emoji + " " + display_name + " " + emoji, 0.08))
	tween.tween_interval(2.0)
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 0.5)
	tween.tween_callback(func():
		if float_tween:
			float_tween.kill()
		if spin_tween:
			spin_tween.kill()
		if player:
			player.get_node("Sausage").rotation.y = 0.0
		cutscene_layer.visible = false
		ability_bar.visible = true
		timer_label.visible = true
		if on_complete_callback:
			on_complete_callback.call()
	)

func start_energy_buildup():
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

		for ability in ABILITY_ORDER:
			if AbilityManager.is_active(ability) or AbilityManager.get_cooldown_percent(ability) > 0:
				update_slot(ability)

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
	ability_bar.visible = false
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
