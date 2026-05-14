shader_type canvas_item;

uniform float progress : hint_range(0.0, 2.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.9, 0.85, 0.3, 0.4);

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	float ripple = smoothstep(progress - 0.05, progress, dist);
	vec4 original = texture(TEXTURE, UV);
	COLOR = mix(original, tint_color, ripple * tint_color.a);
}
