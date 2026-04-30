extends CanvasLayer

signal resumed
signal paused

@onready var options_popup = $ColorRect/OptionsPopup

func _ready():
	visible = false
	options_popup.visible = false
	$ColorRect/VBoxContainer/ResumeButton.pressed.connect(_on_resume)
	$ColorRect/VBoxContainer/OptionsButton.pressed.connect(_on_options)
	$ColorRect/VBoxContainer/QuitButton.pressed.connect(_on_quit)
	$ColorRect/OptionsPopup/CloseButton.pressed.connect(func(): options_popup.visible = false)

func _on_resume():
	hide_pause()

func _on_options():
	options_popup.visible = true

func _on_quit():
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
