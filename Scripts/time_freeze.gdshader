shader_type canvas_item;

uniform float progress : hint_range(0.0, 2.0) = 0.0;
uniform vec2 origin = vec2(0.5, 0.5);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 aspect_uv = vec2(uv.x, uv.y * (9.0 / 16.0));
	vec2 aspect_origin = vec2(origin.x, origin.y * (9.0 / 16.0));
	float dist = distance(aspect_uv, aspect_origin);
	float radius = progress * 0.8;

	vec4 screen_color = texture(SCREEN_TEXTURE, uv);

	float grey = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	vec4 grey_color = vec4(grey * 0.95, grey * 0.95, grey * 0.85, 1.0);

	float edge_width = 0.04;
	float inner = smoothstep(radius - edge_width, radius, dist);
	float outer = smoothstep(radius, radius + edge_width, dist);
	float edge = inner * (1.0 - outer);

	float swirl = sin(dist * 20.0 - progress * 10.0) * 0.5 + 0.5;
	vec3 glow_col = mix(vec3(0.5, 0.0, 0.9), vec3(0.9, 0.3, 1.0), swirl);

	vec4 result = mix(screen_color, grey_color, step(dist, radius));
	result.rgb = mix(result.rgb, glow_col, edge * 0.9);

	COLOR = result;
}