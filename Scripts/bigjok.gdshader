shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform vec4 glitch_color : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float glitch_speed = 15.0;

// Controlled dynamically by Bigjok's script based on proximity!
uniform float proximity_intensity : hint_range(0.0, 1.0) = 0.0;

// Random function for vec3 (used in vertex shader)
float random3(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

// Random function for vec2 (used in fragment shader)
float random2(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
    // Only distort his 3D vertices if the player is getting close
    if (proximity_intensity > 0.05) {
        float time_snap = floor(TIME * glitch_speed);
        
        // Generate erratic horizontal slice offsets based on Y height
        float slice = floor(VERTEX.y * 8.0);
        float rand_offset = random3(vec3(slice, time_snap, 0.0)) - 0.5;
        
        // Trigger jagged vertex tearing chunks
        if (random3(vec3(time_snap, slice, 1.0)) < 0.3 * proximity_intensity) {
            VERTEX.x += rand_offset * 0.4 * proximity_intensity;
            VERTEX.z += (random3(vec3(slice, time_snap, 2.0)) - 0.5) * 0.4 * proximity_intensity;
        }
    }
}

void fragment() {
    vec4 base_tex = texture(albedo_texture, UV);
    
    float time_snap = floor(TIME * glitch_speed);
    float flicker = random2(vec2(time_snap, 9.13));
    
    // Default look
    vec3 final_color = base_tex.rgb;
    float final_alpha = base_tex.a;
    
    // Make his body erratically flash red/inverted colors as he gets closer
    if (proximity_intensity > 0.1 && flicker < 0.25 * proximity_intensity) {
        final_color = mix(base_tex.rgb, glitch_color.rgb, 0.6);
    }
    
    // Ghostly alpha opacity stuttering
    if (proximity_intensity > 0.3 && flicker > 1.0 - (0.2 * proximity_intensity)) {
        final_alpha *= 0.1; // Make him instantly semi-invisible for a split second
    }
    
    ALBEDO = final_color;
    ALPHA = final_alpha;
}