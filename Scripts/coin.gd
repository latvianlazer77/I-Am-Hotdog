extends Area3D

const BOB_HEIGHT = 0.2
const BOB_SPEED = 2.0
const SPIN_SPEED = 2.0
const MAGNET_SPEED = 100.0

var base_y = 0.0
var collected = false
var time = 0.0
var being_attracted = false

func _ready():
	base_y = global_position.y
	body_entered.connect(_on_body_entered)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.84, 0)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.7, 0)
	mat.emission_energy_multiplier = 2.0
	$MeshInstance3D.set_surface_override_material(0, mat)

func _process(delta):
	if collected:
		return

	if being_attracted:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var dir = (player.global_position - global_position).normalized()
			global_position += dir * MAGNET_SPEED * delta
			rotate_y(SPIN_SPEED * 3.0 * delta)
			if global_position.distance_to(player.global_position) < 0.5:
				collect()
		return

	time += delta
	position.y = base_y + sin(time * BOB_SPEED) * BOB_HEIGHT
	rotate_y(SPIN_SPEED * delta)

func start_attraction():
	being_attracted = true

func _on_body_entered(body):
	if body is CharacterBody3D and not collected:
		collect()

func collect():
	collected = true
	SaveData.add_coins(1)
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_coin_label()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(2.0, 2.0, 2.0), 0.1)
	tween.tween_property(self, "scale", Vector3(0.0, 0.0, 0.0), 0.1)
	tween.tween_callback(func(): queue_free())
