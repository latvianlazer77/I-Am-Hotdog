shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Baseline configuration
uniform float vignette_intensity = 0.25;
uniform float vignette_opacity = 0.7;
uniform float scanline_count = 250.0;
uniform float scanline_opacity = 0.12;

uniform float aberration_setting = 0.015;
uniform float noise_setting = 0.25;
uniform float glitch_setting = 0.5;

// Master controller (0.0 = completely clean screen, 1.0 = maximum glitch)
uniform float proximity_strength : hint_range(0.0, 1.0) = 0.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Create the clean, untouched base image first
    vec3 clean_color = texture(SCREEN_TEXTURE, uv).rgb;
    
    // --- Generate the full glitch version inside separate variables ---
    vec2 glitch_uv = uv;
    float glitch_time = TIME * 3.0;
    float glitch_wave = sin(uv.y * 20.0 + glitch_time) * cos(uv.y * 100.0 - glitch_time);
    
    // Apply tearing line offsets
    if (random(vec2(floor(uv.y * 40.0), glitch_time)) < 0.15 * glitch_setting) {
        glitch_uv.x += random(vec2(glitch_time)) * 0.04 * glitch_setting;
    }
    
    // 1. Chromatic Aberration
    float r = texture(SCREEN_TEXTURE, vec2(glitch_uv.x + aberration_setting * (1.0 + glitch_wave), glitch_uv.y)).r;
    float g = texture(SCREEN_TEXTURE, glitch_uv).g;
    float b = texture(SCREEN_TEXTURE, vec2(glitch_uv.x - aberration_setting * (1.0 + glitch_wave), glitch_uv.y)).b;
    vec3 horror_color = vec3(r, g, b);
    
    // 2. Static Noise
    float noise = random(uv * TIME) * noise_setting;
    horror_color += vec3(noise);
    
    // 3. Vignette
    float dist = distance(uv, vec2(0.5, 0.5));
    float vignette = smoothstep(0.0, vignette_intensity, dist);
    horror_color = mix(horror_color, vec3(0.0), vignette * vignette_opacity);
    
    // 4. Moving Scanlines
    float scanline = sin((uv.y + TIME * 0.05) * scanline_count * PI) * scanline_opacity;
    horror_color -= vec3(scanline);
    
    // --- THE REAL FIX ---
    // Smoothly blend between clean and horror using our power curve strength.
    // If proximity_strength is 0.01, it is basically unnoticeable.
    vec3 final_color = mix(clean_color, horror_color, proximity_strength);
    
    COLOR = vec4(final_color, 1.0);
}