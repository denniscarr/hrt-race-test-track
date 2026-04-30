shader_type canvas_item;
/*
This shader is used individual horses. You can tint them. Maybe other stuff one day.
*/

uniform vec4 tint_color: source_color = vec4(1.0, 1.0, 1.0, 1.0); // Additive tint.
uniform float tint_strength: hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	if (tint_strength > 0.0) {
		COLOR.rgb += (tint_color.rgb * tint_color.a * tint_strength);
	}
}