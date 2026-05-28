shader_type spatial;
render_mode unshaded;

uniform float checker_size : hint_range(0.1, 10.0) = 1.0;
uniform vec4 color_a : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform vec4 color_b : source_color = vec4(0.9, 0.9, 0.9, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 pos = floor(world_pos.xz / checker_size);
	float checker = mod(pos.x + pos.y, 2.0);
	ALBEDO = mix(color_a.rgb, color_b.rgb, checker);
}