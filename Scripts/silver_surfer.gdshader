shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 chrome_color : source_color = vec3(0.88, 0.91, 0.98);
uniform float brightness = 0.25;

void fragment() {
	ALBEDO = chrome_color;

	METALLIC = 1.0;
	ROUGHNESS = 0.02;
	SPECULAR = 1.0;

	// Keeps it visible in darker areas
	EMISSION = chrome_color * brightness;
}