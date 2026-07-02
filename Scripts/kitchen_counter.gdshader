shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.95, 0.93, 0.88, 1.0);
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float roughness = 0.18;
uniform float metallic = 0.0;

uniform float noise_strength = 0.05;
uniform float sparkle_strength = 0.08;
uniform float rim_strength = 0.35;

float hash(vec2 p)
{
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453);
}

void fragment()
{
	vec2 uv = UV * 40.0;

	float noise = hash(floor(uv));
	float variation = (noise - 0.5) * noise_strength;

	ALBEDO = base_color.rgb + variation;

	float sparkle = step(0.995, hash(floor(UV * 180.0)));
	ALBEDO += sparkle * sparkle_strength;

	ROUGHNESS = roughness;
	METALLIC = metallic;
}

void light()
{
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);

	float toon = smoothstep(0.2,0.4,NdotL);

	vec3 diffuse = ALBEDO * toon;

	vec3 view_dir = normalize(VIEW);
	float rim = pow(1.0 - max(dot(NORMAL, view_dir),0.0),3.0);

	diffuse += highlight_color.rgb * rim * rim_strength;

	DIFFUSE_LIGHT += diffuse * ATTENUATION * LIGHT_COLOR;
}