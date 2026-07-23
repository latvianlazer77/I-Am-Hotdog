shader_type spatial;
render_mode cull_back;

// The overall tint of the metal. Keep this a very light silvery-blue.
uniform vec3 silver_tint : source_color = vec3(0.9, 0.95, 1.0);

// Set this back to 1.0 to start. If it turns into a white blob again, TURN THIS DOWN.
uniform float brightness : hint_range(0.1, 5.0) = 1.0;

void fragment() {
    // 1. Base metal settings
    ALBEDO = vec3(0.0);
    METALLIC = 1.0;
    ROUGHNESS = 0.05; // Tiny bit of blur so the horizon isn't perfectly jagged

    // 2. Get the Reflection direction in World Space
    vec3 view_dir = (INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz;
    vec3 normal_dir = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
    vec3 ref_dir = reflect(-view_dir, normal_dir);

    // ref_dir.y tells us if the reflection is looking up (sky) or down (ground)
    float y = ref_dir.y;

    // 3. Fake Sky (Bright top)
    vec3 sky = mix(vec3(0.3, 0.35, 0.4), vec3(1.0, 1.0, 1.0), smoothstep(0.0, 1.0, y));

    // 4. Fake Ground (Dark bottom) - THIS IS WHAT MAKES IT LOOK LIKE METAL
    vec3 ground = mix(vec3(0.05, 0.05, 0.05), vec3(0.15, 0.15, 0.15), smoothstep(-1.0, 0.0, y));

    // 5. Mix the sky and ground together with a sharp horizon line
    float horizon = smoothstep(-0.02, 0.02, y);
    vec3 fake_chrome = mix(ground, sky, horizon);

    // 6. Add a fake bright "ceiling light" hitting the curves
    vec3 light_dir = normalize(vec3(0.5, 1.0, -0.5));
    float light_source = pow(max(dot(ref_dir, light_dir), 0.0), 30.0);

    // 7. Output to EMISSION so it ignores the room's darkness
    EMISSION = (fake_chrome * silver_tint + vec3(light_source)) * brightness;
}