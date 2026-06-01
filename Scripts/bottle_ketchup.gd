extends Node3D

const SPIN_SPEED = 2.0
const BOB_HEIGHT = 0.3
const BOB_SPEED = 1.5

var base_y = 0.0
var time = 0.0

func _ready():
	base_y = global_position.y

func _process(delta):
	time += delta
	rotate_y(SPIN_SPEED * delta)
	global_position.y = base_y + sin(time * BOB_SPEED) * BOB_HEIGHT
