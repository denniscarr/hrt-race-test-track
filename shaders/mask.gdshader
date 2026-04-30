/*
Mutli-purpose shader with a couple of masking effects.
*/
shader_type canvas_item;

// Used with the alpha test effect. Pixels with their alpha value below this
// will be masked out.
uniform float alpha_test_cutoff : hint_range(0.0, 1.0) = 0.5;

// The texture used for the alpha test masking.
uniform sampler2D alpha_test : hint_default_transparent, filter_nearest;

// If you set a texture here, it will be superimposed on top of all
// non-transparent pixels in the main shader.
uniform sampler2D mask : hint_default_transparent, filter_nearest;

void vertex() {}

void fragment() {
	// Handle alpha test
	if (texture(alpha_test, UV).r > alpha_test_cutoff) {
		COLOR.a = 0.0;
	}
	else {
		vec4 mask_pixel = texture(mask, UV);
		vec4 tex_pixel = texture(TEXTURE, UV);
		
		// Pure green = show the original image
		if (mask_pixel.a > 0.0) {
			COLOR = mask_pixel;
			COLOR.a = tex_pixel.a;
		}
		else {
			COLOR = texture(TEXTURE, UV);
		}
	}
}
