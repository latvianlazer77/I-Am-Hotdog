shader_type spatial;
render_mode unshaded;

uniform vec3 light_color : source_color = vec3(1.0, 0.95, 0.7);
uniform float flicker_speed = 8.0;
uniform float flicker_intensity = 0.15;
uniform float base_brightness = 1.2;
uniform float buzz_frequency = 60.0; // simulates 60Hz fluorescent buzz

float rand(float n) {
	return fract(sin(n) * 43758.5453123);
}

float noise(float t) {
	float i = floor(t);
	float f = fract(t);
	return mix(rand(i), rand(i + 1.0), smoothstep(0.0, 1.0, f));
}

void fragment() {
	float t = TIME;

	// Slow drift flicker
	float slow_flicker = noise(t * flicker_speed * 0.3);

	// Fast buzz (fluorescent hum)
	float buzz = sin(t * buzz_frequency * 3.14159) * 0.5 + 0.5;

	// Occasional stutter — random spikes of darkness
	float stutter = step(0.97, rand(floor(t * 12.0))) * rand(t * 100.0);

	float brightness = base_brightness
		- slow_flicker * flicker_intensity
		- stutter * 0.4
		+ buzz * 0.02;

	brightness = clamp(brightness, 0.0, 1.5);

	ALBEDO = light_color * brightness;
	EMISSION = light_color * brightness;
}
