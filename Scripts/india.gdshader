shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 color_saffron : source_color = vec4(1.0, 0.6, 0.12, 1.0); 
uniform vec4 color_white : source_color = vec4(1.0, 1.0, 1.0, 1.0);  
uniform vec4 color_green : source_color = vec4(0.07, 0.53, 0.03, 1.0); 
uniform vec4 color_chakra : source_color = vec4(0.0, 0.0, 0.5, 1.0); 

// Because we are using physical 3D space now, these numbers depend on how 
// big your hotdog is! You can slide these around in the Inspector.
uniform float stripe_1 = 0.2;  // The line between Saffron and White
uniform float stripe_2 = -0.2; // The line between White and Green
uniform float chakra_size = 0.1;

// This variable passes the 3D position from the vertex to the fragment
varying vec3 local_pos;

void vertex() {
	// Grab the actual physical coordinates of the 3D model
	local_pos = VERTEX;
}

void fragment() {
	// IMPORTANT: If the stripes are slicing the wrong way (e.g., front-to-back),
	// change `local_pos.y` to `local_pos.x` or `local_pos.z` until it looks right!
	float pos = local_pos.y; 
	
	vec3 final_color = color_white.rgb;
	
	if (pos > stripe_1) {
		// Top section
		final_color = color_saffron.rgb;
	} else if (pos < stripe_2) {
		// Bottom section
		final_color = color_green.rgb;
	} else {
		// Middle section (White) is already set as the default above!
		
		// Draw the Ashoka Chakra (Navy Blue Circle)
		// If the circle looks squished or is on the wrong side, swap local_pos.x with local_pos.z
		float dist_to_center = length(vec2(pos, local_pos.x));
		if (dist_to_center < chakra_size) {
			final_color = color_chakra.rgb;
		}
	}
	
	ALBEDO = final_color;
	ROUGHNESS = 0.4; 
}