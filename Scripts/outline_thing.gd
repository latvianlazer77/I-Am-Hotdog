@tool
extends Node

@export var outline_shader: Shader
@export var toon_shader: Shader
@export var outline_size: float = 0.02
@export var toon_color: Color = Color(0.8, 0.8, 0.8, 1.0)
@export var apply_now: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			apply_shaders(get_tree().root)
			apply_now = false

func apply_shaders(node: Node):
	if node is MeshInstance3D:
		if node.name.ends_with("Outline"):
			return

		# Apply toon shader to the mesh
		var toon_mat = ShaderMaterial.new()
		toon_mat.shader = toon_shader
		toon_mat.set_shader_parameter("albedo_color", toon_color)
		node.set_surface_override_material(0, toon_mat)
		print("Applied toon shader to: ", node.name)

		# Check if outline already exists
		var existing = node.get_parent().get_node_or_null(node.name + "Outline")
		if not existing:
			var outline = MeshInstance3D.new()
			outline.name = node.name + "Outline"
			outline.mesh = node.mesh
			outline.transform = node.transform
			var outline_mat = ShaderMaterial.new()
			outline_mat.shader = outline_shader
			outline_mat.set_shader_parameter("outline_size", outline_size)
			outline_mat.set_shader_parameter("outline_color", Color(0, 0, 0, 1))
			outline.set_surface_override_material(0, outline_mat)
			node.get_parent().add_child(outline)
			outline.owner = get_tree().edited_scene_root
			print("Added outline to: ", node.name)

	for child in node.get_children():
		apply_shaders(child)
