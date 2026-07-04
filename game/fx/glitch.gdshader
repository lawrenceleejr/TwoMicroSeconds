shader_type canvas_item;
// Full-screen digital-artifact glitch. `intensity` 1 -> 0 over ~0.5 s.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float tick = floor(TIME * 24.0);

	// Horizontal slice displacement on a few random bands.
	float band = floor(uv.y * 22.0);
	float gate = step(0.55, hash(vec2(band, tick + 7.0)));
	float jitter = (hash(vec2(band, tick)) - 0.5) * 0.3 * intensity * gate;
	uv.x = fract(uv.x + jitter);

	// RGB channel split.
	float split = 0.007 * intensity;
	vec3 col;
	col.r = texture(screen_tex, vec2(fract(uv.x + split), uv.y)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, vec2(fract(uv.x - split), uv.y)).b;

	// Block dropouts: corrupted rectangles get channel-swapped and inverted.
	vec2 block = floor(uv * vec2(26.0, 15.0));
	float drop = step(0.94 - intensity * 0.22, hash(block + tick));
	col = mix(col, vec3(1.0) - col.bgr, drop * intensity * 0.85);

	// Scanlines.
	col *= 1.0 - 0.13 * intensity * (0.5 + 0.5 * sin(uv.y * 460.0));

	COLOR = vec4(col, 1.0);
}
