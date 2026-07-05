shader_type spatial;
// Relativity applied to a depth-plane quad's own material, sampling the
// plane's viewport texture EXACTLY ONCE. (An in-viewport overlay would
// re-draw the world shifted, and with a transparent plane the original
// showed through underneath — two muons. This displaces in place.)
//
//  - length contraction along the direction of motion
//  - Doppler shift: blueshift ahead, redshift behind, headlight glow
//  - subtle directional motion blur scaled with speed
// Unshaded, alpha preserved so transparent planes composite over the sky.
render_mode unshaded, cull_disabled, shadows_disabled, specular_disabled;

uniform sampler2D world_tex : source_color, filter_linear;
uniform vec2 motion_dir = vec2(0.0, 1.0);
uniform float contraction : hint_range(0.0, 0.5) = 0.0;
uniform float doppler : hint_range(0.0, 1.0) = 0.0;
uniform float blur_amount : hint_range(0.0, 0.05) = 0.0;

void fragment() {
	vec2 center = vec2(0.5);
	vec2 p = UV - center;
	vec2 dir = normalize(motion_dir + vec2(1e-6, 0.0));
	float along = dot(p, dir);
	vec2 perp = p - along * dir;

	// Length contraction: sample from stretched coords (pivot at center).
	vec2 base = center + perp + dir * (along * (1.0 + contraction));

	// Motion blur: nine taps along the motion axis, radially masked so the
	// muon near screen center stays crisp while the periphery streaks.
	float mask = smoothstep(0.05, 0.32, length(p));
	float b = blur_amount * mask;
	vec4 acc = vec4(0.0);
	for (int i = 0; i < 9; i++) {
		float o = (float(i) / 8.0 - 0.5) * 2.0;
		vec2 uv = clamp(base + dir * o * b, vec2(0.001), vec2(0.999));
		acc += texture(world_tex, uv);
	}
	acc /= 9.0;
	vec3 col = acc.rgb;

	// Doppler: forward hemisphere shifts blue and brightens.
	float fwd = dot(normalize(p + vec2(1e-5, 0.0)), dir);
	float s = doppler * fwd;
	col.r *= 1.0 - 0.38 * s;
	col.g *= 1.0 - 0.13 * s;
	col.b *= 1.0 + 0.44 * s;
	col *= 1.0 + 0.20 * doppler * max(fwd, 0.0);

	ALBEDO = col;
	ALPHA = acc.a;
}
