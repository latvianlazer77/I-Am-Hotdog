shader_type spatial;
// "unshaded" is the magic word here. It ignores all Godot lights!
render_mode blend_mix, depth_draw_opaque, unshaded;

uniform vec4 ice_color : source_color = vec4(0.4, 0.7, 0.9, 0.35); 
uniform vec4 edge_color : source_color = vec4(0.8, 0.95, 1.0, 1.0); 

uniform float fresnel_power : hint_range(0.0, 8.0) = 2.0; 
uniform float edge_glow_strength : hint_range(0.0, 2.0) = 1.0; 

uniform sampler2D frost_noise; 
uniform float noise_scale : hint_range(0.1, 10.0) = 1.5; 
uniform float frost_intensity : hint_range(0.0, 1.0) = 0.8; 
uniform float bump_strength : hint_range(0.0, 5.0) = 1.5; 

// ==========================================
// NEW: BUILT-IN FAKE LIGHTING
// ==========================================
uniform vec3 fake_light_direction = vec3(0.5, 1.0, 0.5); // Where the fake sun is pointing
uniform float fake_sparkle_power : hint_range(1.0, 64.0) = 32.0; // How tight the reflections are

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

void fragment() {
    vec2 scaled_uv = UV * noise_scale;
    float noise_val = texture(frost_noise, scaled_uv).r;
    
    // Fake 3D geometry from the noise
    vec3 normal_offset = vec3(dFdx(noise_val), dFdy(noise_val), 0.0) * bump_strength;
    vec3 bumped_normal = normalize(NORMAL - normal_offset);
    
    float frost_rim = fresnel(fresnel_power, bumped_normal, VIEW);
    float combined_frost = clamp(frost_rim + (noise_val * frost_intensity), 0.0, 1.0);
    
    // --- CALCULATING THE FAKE LIGHT ---
    vec3 light_dir = normalize(fake_light_direction);
    
    // 1. Fake Diffuse (The base 3D shading)
    // We mix it so the shadows don't go completely pitch black
    float light_hit = max(dot(bumped_normal, light_dir), 0.0);
    float fake_diffuse = mix(0.5, 1.0, light_hit); 
    
    // 2. Fake Specular (The sparkly highlights)
    // This calculates where the light bounces straight into the camera
    vec3 half_vector = normalize(light_dir + VIEW);
    float fake_specular = pow(max(dot(bumped_normal, half_vector), 0.0), fake_sparkle_power);
    
    // Make it only sparkle hard on the frosty, cracked bits
    fake_specular *= (0.5 + noise_val);
    
    // --- COMBINING EVERYTHING ---
    // Multiply the base colors by our fake shadows
    vec3 base_color = mix(ice_color.rgb, edge_color.rgb, combined_frost) * fake_diffuse;
    
    // Add the fake sparkles and the edge glow directly to the Albedo
    ALBEDO = base_color + vec3(fake_specular) + (edge_color.rgb * frost_rim * edge_glow_strength);
    
    // We completely removed ROUGHNESS, METALLIC, and EMISSION because 
    // the "unshaded" render mode doesn't use them anyway!
    
    ALPHA = clamp(ice_color.a + combined_frost, 0.0, 1.0);
}