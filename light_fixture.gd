extends Node3D

@onready var omni = $OmniLight3D
@onready var mesh = $MeshInstance3D

var base_energy := 1.5        # normal brightness
var flicker_speed := 8.0
var stutter_chance := 0.03    # 3% chance per frame of a stutter

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0

	# Slow drift (matches shader's slow_flicker)
	var slow = sin(t * flicker_speed * 0.3 + randf()) * 0.1

	# Occasional stutter — snap to near-black briefly
	var stutter := 0.0
	if randf() < stutter_chance:
		stutter = randf_range(0.4, 0.9)

	var energy = clamp(base_energy - slow - stutter, 0.05, base_energy * 1.1)
	omni.light_energy = energy
	
