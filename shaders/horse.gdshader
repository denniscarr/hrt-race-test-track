shader_type canvas_item;
/*
This shader is used individual horses. You can tint them. Maybe other stuff one day.
*/

uniform vec4 tint_color: source_color = vec4(1.0, 1.0, 1.0, 1.0); // Additive tint.
uniform float tint_strength: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 black_replacement: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Fuzzy color match to prevent floating point issues
bool fuzzy_color_match(vec3 c1, vec3 c2) {
	float maxDiff = 0.002;
    return (
        abs(c1.r - c2.r) < maxDiff
        && abs(c1.g - c2.g) < maxDiff
        && abs(c1.b - c2.b) < maxDiff
    );
}

void fragment() {
    // Blake's Clickteam black is slightly blue
	if (COLOR.a > 0.0 && fuzzy_color_match(COLOR.rgb, vec3(0.0, 0.0, 0.03125))) {
		COLOR = black_replacement;
	}
	if (tint_strength > 0.0) {
		COLOR.rgb += (tint_color.rgb * tint_color.a * tint_strength);
	}
}