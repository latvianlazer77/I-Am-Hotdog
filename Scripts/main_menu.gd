extends Control

@onready var options_popup = $OptionsPopup

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$VBoxContainer/PlayButton.pressed.connect(_on_play)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)
	$OptionsPopup/CloseButton.pressed.connect(func(): options_popup.visible = false)
	options_popup.visible = false
	

func _on_play():
	get_tree().change_scene_to_file("res://Scenes/Menus/level_select.tscn")

func _on_options():
	options_popup.visible = true

func _on_quit():
	get_tree().quit()
