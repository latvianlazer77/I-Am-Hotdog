extends CanvasLayer

signal resumed
signal paused

@onready var options_popup = $ColorRect/OptionsPopup
# IF IT STILL DOESN'T WORK, THIS LINE BELOW IS THE CULPRIT!
# Delete the text after the equals sign, hold CTRL, and drag the button here from the Scene Tree.
@onready var blackout_toggle = $ColorRect/OptionsPopup/BlackoutToggle

func _ready():
	visible = false
	options_popup.visible = false
	$ColorRect/VBoxContainer/ResumeButton.pressed.connect(_on_resume)
	$ColorRect/VBoxContainer/OptionsButton.pressed.connect(_on_options)
	$ColorRect/VBoxContainer/QuitButton.pressed.connect(_on_quit)
	$ColorRect/OptionsPopup/CloseButton.pressed.connect(func(): options_popup.visible = false)
	
	# We connect the signal here once
	if blackout_toggle and not blackout_toggle.toggled.is_connected(_on_blackout_toggled):
		blackout_toggle.toggled.connect(_on_blackout_toggled)

func _on_blackout_toggled(toggled_on: bool):
	SaveData.set_blackout_mode(toggled_on)
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, toggled_on)

func _on_resume():
	hide_pause()

func _on_options():
	options_popup.visible = true
	
	# THIS IS THE FIX: Check the save file EVERY TIME the options menu opens!
	if blackout_toggle:
		# Temporarily disconnect so updating the button visually doesn't trigger the audio code
		if blackout_toggle.toggled.is_connected(_on_blackout_toggled):
			blackout_toggle.toggled.disconnect(_on_blackout_toggled)
			
		# Sync the visual button to the actual save data
		blackout_toggle.button_pressed = SaveData.is_blackout_mode()
		
		# Reconnect the signal so the player can actually click it again
		blackout_toggle.toggled.connect(_on_blackout_toggled)

func _on_quit():
	AbilityManager.reset_all()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/Menus/main_menu.tscn")

func show_pause():
	visible = true
	emit_signal("paused")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_pause():
	visible = false
	emit_signal("resumed")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
