@tool
extends Node

@export var material: Material
@export var apply_now: bool = false:
	set(value):
		if value and Engine.is_editor_hint() and material:
			apply_to_all(get_tree().edited_scene_root)
			apply_now = false

func apply_to_all(node: Node):
	if node is MeshInstance3D and not node.name.ends_with("Outline"):
		node.set_surface_override_material(0, material)
		print("Applied to: ", node.name)
	for child in node.get_children():
		apply_to_all(child)
