shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float rim_width : hint_range(0.1, 5.0) = 1.5;

void fragment() {
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	float grey = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey_tinted = vec3(grey * 0.95, grey * 0.95, grey * 0.85);

	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	float rim = pow(edge, rim_width);
	float swirl = sin(edge * 20.0) * 0.5 + 0.5;
	vec3 rim_color = mix(vec3(0.5, 0.0, 0.9), vec3(0.9, 0.3, 1.0), swirl);

	ALBEDO = mix(grey_tinted, rim_color, rim);
	ALPHA = mix(0.95, 1.0, rim);
}