shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	// Proper neutral grayscale
	float grey = dot(screen_color, vec3(0.299, 0.587, 0.114));
	vec3 grey_color = vec3(grey);

	// Edge mask
	float edge = 1.0 - abs(dot(NORMAL, VIEW));
	float rim = pow(edge, 4.0);

	// Purple edge only
	vec3 rim_color = vec3(0.85, 0.2, 1.0);

	// Grey interior + purple edge
	ALBEDO = mix(grey_color, rim_color, rim);

	ALPHA = 1.0;
}