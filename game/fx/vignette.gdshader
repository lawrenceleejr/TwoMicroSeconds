shader_type canvas_item;
// Soft cinematic vignette, always on, very subtle.

void fragment() {
	float d = length(UV - vec2(0.5, 0.5));
	float v = smoothstep(0.58, 1.02, d);
	COLOR = vec4(0.16, 0.15, 0.25, v * 0.30);
}
