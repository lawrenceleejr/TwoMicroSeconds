shader_type canvas_item;
// The print finish, always on: film grain, a whisper of RGB channel
// misregistration toward the edges (risograph misprint), and a soft
// vignette. This is most of what makes the frame feel "printed".

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 p = uv - vec2(0.5);
	float edge = smoothstep(0.12, 0.72, length(p));

	// Channel misregistration: R and B pull apart slightly, more at edges.
	vec2 shift = normalize(p + vec2(1e-5)) * 0.0016 * edge;
	float r = texture(screen_tex, uv + shift).r;
	vec2 gb = texture(screen_tex, uv).gb;
	float b = texture(screen_tex, uv - shift).b;
	vec3 col = vec3(r, gb.x, b);

	// Static paper grain + a slow animated pass so it feels alive.
	float g = hash12(uv * vec2(1721.0, 977.0)) - 0.5;
	float g2 = hash12(uv * vec2(913.0, 1531.0) + fract(TIME * 0.5) * 7.3) - 0.5;
	col += (g * 0.028 + g2 * 0.012);

	// Vignette, pressed into the ink color rather than plain black.
	float v = smoothstep(0.55, 1.05, length(p));
	col = mix(col, vec3(0.09, 0.07, 0.15), v * 0.34);

	COLOR = vec4(col, 1.0);
}
