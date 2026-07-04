shader_type canvas_item;
// The sky, done properly: a smooth altitude gradient with film-grain dither
// (no banding), drifting nebula wisps up high, and a warm sun glow low in
// the stratosphere. World position is reconstructed from camera uniforms.

uniform float cam_top = 0.0;
uniform float cam_left = 0.0;
uniform float cam_h = 900.0;
uniform float cam_w = 1600.0;
uniform float t = 0.0;

const int STOPS = 7;

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

vec3 sky_color(float y) {
	float ys[STOPS] = {-7500.0, 0.0, 12000.0, 28500.0, 48000.0, 61500.0, 69000.0};
	vec3 cs[STOPS] = {
		vec3(0.051, 0.051, 0.125), vec3(0.078, 0.078, 0.180),
		vec3(0.184, 0.188, 0.380), vec3(0.357, 0.373, 0.592),
		vec3(0.718, 0.557, 0.788), vec3(1.0, 0.812, 0.761),
		vec3(1.0, 0.961, 0.882)
	};
	if (y <= ys[0]) { return cs[0]; }
	for (int i = 0; i < STOPS - 1; i++) {
		if (y < ys[i + 1]) {
			float f = (y - ys[i]) / (ys[i + 1] - ys[i]);
			return mix(cs[i], cs[i + 1], f);
		}
	}
	return cs[STOPS - 1];
}

void fragment() {
	float wy = cam_top + SCREEN_UV.y * cam_h;
	float wx = cam_left + SCREEN_UV.x * cam_w;
	vec3 col = sky_color(wy);

	// Nebula wisps in the thin air up high, drifting slowly.
	if (wy < 33000.0) {
		float fade = 1.0 - smoothstep(18000.0, 33000.0, wy);
		vec2 np = vec2(wx * 0.0011 + t * 0.008, wy * 0.0016);
		float n = vnoise(np) * 0.65 + vnoise(np * 2.3 + 7.7) * 0.35;
		n = smoothstep(0.55, 0.95, n);
		col += vec3(0.22, 0.18, 0.34) * n * 0.35 * fade;
	}

	// A warm sun, resting low over the troposphere.
	float sd = length(vec2(wx - 620.0, (wy - 50000.0) * 1.35));
	col += vec3(1.0, 0.85, 0.55) * exp(-sd / 750.0) * 0.5;
	col += vec3(1.0, 0.95, 0.8) * exp(-sd / 220.0) * 0.6;

	// Grain dither: kills gradient banding dead.
	col += (hash12(SCREEN_UV * vec2(1721.0, 977.0) + fract(t) * 13.7) - 0.5) * 0.012;

	COLOR = vec4(col, 1.0);
}
