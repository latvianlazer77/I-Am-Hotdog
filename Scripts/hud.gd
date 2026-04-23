extends CanvasLayer

@onready var timer_label = $Control/TimerLabel

func update_timer(time_string: String):
	timer_label.text = time_string
