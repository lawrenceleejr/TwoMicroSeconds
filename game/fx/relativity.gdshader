shader_type canvas_item;
// Relativistic view effects, in the spirit of MIT's "A Slower Speed of Light":
//  - length contraction along the direction of motion (screen-space squeeze)
//  - Doppler shift: blueshift ahead, redshift behind, headlight brightening
//  - subtle directional motion blur scaled with speed
// Applied to the world only (UI lives on a higher CanvasLayer).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 motion_dir = vec2(0.0, 1.0);
uniform float contraction : hint_range(0.0, 0.5) = 0.0;
uniform float doppler : hint_range(0.0, 1.0) = 0.0;
uniform float blur_amount : hint_range(0.0, 0.03) = 0.0;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	vec2 p = SCREEN_UV - center;
	vec2 d = normalize(motion_dir + vec2(1e-6, 0.0));
	float along = dot(p, d);
	vec2 perp = p - along * d;

	// Length contraction: sample from stretched coordinates so the world
	// appears squeezed along the motion axis (pivot at screen center).
	vec2 base = center + perp + d * (along * (1.0 + contraction));

	// Motion blur: a few taps along the motion axis.
	vec3 col = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		float o = (float(i) / 4.0 - 0.5) * 2.0;
		vec2 uv = clamp(base + d * o * blur_amount, vec2(0.001), vec2(0.999));
		col += texture(screen_tex, uv).rgb;
	}
	col /= 5.0;

	// Doppler: forward hemisphere shifts blue and brightens (headlight
	// effect), rear hemisphere shifts red.
	float fwd = dot(normalize(p + vec2(1e-5, 0.0)), d);
	float s = doppler * fwd;
	col.r *= 1.0 - 0.30 * s;
	col.g *= 1.0 - 0.10 * s;
	col.b *= 1.0 + 0.35 * s;
	col *= 1.0 + 0.16 * doppler * max(fwd, 0.0);

	COLOR = vec4(col, 1.0);
}
