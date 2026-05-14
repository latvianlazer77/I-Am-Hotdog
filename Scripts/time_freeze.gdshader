shader_type canvas_item;

uniform float progress : hint_range(0.0, 2.0) = 0.0;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.6, 0.6, 0.5, 0.3);

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float radius = progress * 0.7;
	float circle = step(dist, radius);

	// Swirling effect using angle
	vec2 dir = UV - center;
	float angle = atan(dir.y, dir.x);
	float swirl = sin(angle * 6.0 + time * 3.0) * 0.5 + 0.5;

	// Edge glow
	float edge_width = 0.04;
	float edge = smoothstep(radius - edge_width, radius, dist) * smoothstep(radius + edge_width, radius, dist);

	// Purple swirl colour on the edge
	vec3 purple = vec3(0.6 + swirl * 0.3, 0.0, 0.8 + swirl * 0.2);
	vec3 bright_purple = vec3(0.8, 0.2, 1.0);
	vec3 glow_col = mix(purple, bright_purple, swirl);

	vec4 tint = vec4(tint_color.rgb, tint_color.a * circle);
	vec4 glow = vec4(glow_col, edge * 1.0);

	COLOR = mix(tint, glow, edge);
}