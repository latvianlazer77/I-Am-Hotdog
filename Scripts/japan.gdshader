shader_type spatial;
// Keeps the cool cel-shaded toon lighting!
render_mode blend_mix, depth_draw_opaque, diffuse_toon, specular_toon;

// One single color picker in your Inspector
uniform vec4 solid_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Defaults to pure white

void fragment() {
    // Slaps that single color over the entire hotdog perfectly
    ALBEDO = solid_color.rgb;
    
    // Keeps it looking matte instead of like shiny plastic
    ROUGHNESS = 0.9;
    METALLIC = 0.0;
}