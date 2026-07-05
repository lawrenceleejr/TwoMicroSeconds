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

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 p = uv - vec2(0.5);
	float edge = smoothstep(0.12, 0.72, length(p));

	// Channel misregistration: R and B pull apart a hair at the far edges
	// only. Kept tiny — too much reads as "seeing double", not "print".
	vec2 shift = normalize(p + vec2(1e-5)) * 0.0006 * edge;
	float r = texture(screen_tex, uv + shift).r;
	vec2 gb = texture(screen_tex, uv).gb;
	float b = texture(screen_tex, uv - shift).b;
	vec3 col = vec3(r, gb.x, b);

	// Halftone: a rotated dot screen pressed into the shadows — the darker
	// the area, the fatter the dots. Pure print language.
	vec2 px = uv / SCREEN_PIXEL_SIZE;
	float ca = cos(0.55);
	float sa = sin(0.55);
	vec2 rp = mat2(vec2(ca, -sa), vec2(sa, ca)) * px;
	vec2 cell = fract(rp / 8.0) - 0.5;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	float dark = 1.0 - smoothstep(0.10, 0.50, lum);
	float dr = 0.44 * dark;
	float dot_m = 1.0 - smoothstep(dr - 0.14, dr + 0.06, length(cell));
	col *= 1.0 - 0.20 * dot_m * dark;

	// Paper stock: static fibrous mottle, stretched horizontally like laid
	// paper, strongest in the light areas (ink hides fiber; paper shows it).
	// Plus a warm cast — this frame was printed on cream, not white.
	float fib = vnoise(vec2(px.x * 0.055, px.y * 0.16)) * 0.55
		+ vnoise(vec2(px.x * 0.013, px.y * 0.045) + 31.7) * 0.45;
	float lum2 = dot(col, vec3(0.299, 0.587, 0.114));
	col *= 0.960 + 0.075 * fib * (0.35 + 0.65 * lum2);
	col = mix(col, col * vec3(1.02, 0.99, 0.945), 0.35);

	// Static paper grain + a slow animated pass so it feels alive.
	float g = hash12(uv * vec2(1721.0, 977.0)) - 0.5;
	float g2 = hash12(uv * vec2(913.0, 1531.0) + fract(TIME * 0.5) * 7.3) - 0.5;
	col += (g * 0.028 + g2 * 0.012);

	// Vignette, pressed into the ink color rather than plain black.
	float v = smoothstep(0.55, 1.05, length(p));
	col = mix(col, vec3(0.09, 0.07, 0.15), v * 0.34);

	COLOR = vec4(col, 1.0);
}
