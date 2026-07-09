extends Control
## Cumulative decay probability vs lab time. Quantitative on purpose:
## a solid curve traces P(decayed) so far, a dashed projection continues
## it at the current γ, and a "now" line walks right as the clock runs.
## Boosting stretches the mean life, so the x-axis smoothly zooms out —
## tick marks compress past you as the window rescales.

const PLOT_W := 250.0
const PLOT_H := 92.0
const PAD := 14.0
const TITLE_H := 16.0

var muon: Node2D = null

var _xmax := 12.0
var _hist := PackedVector2Array()  # (lab_t, P) samples
var _sample_accum := 1.0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(PLOT_W + PAD * 2.0, PLOT_H + PAD * 2.0 + TITLE_H)


func _process(delta: float) -> void:
	_t += delta
	if muon != null and is_instance_valid(muon):
		var lab: float = muon.get("lab_us")
		var p: float = muon.get("decay_p")
		_sample_accum += delta
		if _sample_accum >= 0.2:
			_sample_accum = 0.0
			_hist.append(Vector2(lab, p))
			# Bound the history: a long deep run would grow it (and the
			# per-frame polyline rebuilt from it) without limit. Old samples
			# compress against the left edge anyway.
			if _hist.size() > 240:
				_hist = _hist.slice(_hist.size() - 220)
		var gamma: float = muon.get("gamma")
		var mean_life: float = gamma * 2.2  # lab-frame mean life, µs
		# Window covers the past plus ~2 mean lives of future; boosting
		# raises the target and the lerp animates the zoom-out.
		var target_x := maxf(lab * 1.25 + 3.0, mean_life * 2.1)
		_xmax = lerpf(_xmax, target_x, 1.0 - exp(-2.2 * delta))
	queue_redraw()


func _x(t: float, origin: Vector2) -> float:
	return origin.x + clampf(t / _xmax, 0.0, 1.0) * PLOT_W


func _y(p: float, origin: Vector2) -> float:
	return origin.y - clampf(p, 0.0, 1.0) * PLOT_H


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Juice.INK, 0.55)
	sb.set_corner_radius_all(12)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

	var origin := Vector2(PAD, PAD + TITLE_H + PLOT_H)
	var font := ThemeDB.fallback_font
	var lab := 0.0
	var p_now := 0.0
	var gamma := 1.0
	if muon != null and is_instance_valid(muon):
		lab = muon.get("lab_us")
		p_now = muon.get("decay_p")
		gamma = muon.get("gamma")
	var mean_life: float = gamma * 2.2
	var danger := p_now > 0.9

	# Time ticks (they compress and stream by as the window rescales).
	var tick_dt := 1.0
	for candidate in [1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0]:
		tick_dt = candidate
		if _xmax / candidate <= 8.0:
			break
	var tick_t := tick_dt
	var tick_i := 1
	while tick_t < _xmax:
		var x := _x(tick_t, origin)
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y - PLOT_H), Color(Juice.CREAM, 0.10), 1.0, true)
		if tick_i % 2 == 0:
			draw_string(font, Vector2(x - 10.0, origin.y + 11.0), "%dµs" % int(tick_t),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Juice.CREAM, 0.45))
		tick_t += tick_dt
		tick_i += 1

	# Probability gridlines: 50% quiet, 90% loud.
	draw_line(Vector2(origin.x, _y(0.5, origin)), Vector2(origin.x + PLOT_W, _y(0.5, origin)),
		Color(Juice.CREAM, 0.14), 1.0, true)
	var y90 := _y(0.9, origin)
	draw_line(Vector2(origin.x, y90), Vector2(origin.x + PLOT_W, y90),
		Color(1.0, 0.35, 0.42, 0.55), 1.2, true)
	draw_string(font, Vector2(origin.x + PLOT_W - 26.0, y90 - 3.0), "90%",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 0.45, 0.5, 0.8))
	draw_line(origin, origin + Vector2(PLOT_W, 0), Color(Juice.CREAM, 0.35), 1.4, true)

	# History: the path P has actually taken.
	if _hist.size() >= 2:
		var pts := PackedVector2Array()
		for s in _hist:
			pts.append(Vector2(_x(s.x, origin), _y(s.y, origin)))
		pts.append(Vector2(_x(lab, origin), _y(p_now, origin)))
		draw_polyline(pts, Color(Juice.CREAM, 0.95), 2.2, true)

	# Projection: dashed continuation at the current gamma.
	var seg_on := true
	var prev := Vector2(_x(lab, origin), _y(p_now, origin))
	for i in range(1, 25):
		var tf := lab + (_xmax - lab) * float(i) / 24.0
		var pf := 1.0 - (1.0 - p_now) * exp(-(tf - lab) / mean_life)
		var pt := Vector2(_x(tf, origin), _y(pf, origin))
		if seg_on:
			draw_line(prev, pt, Color(Juice.SUN, 0.7), 1.6, true)
		seg_on = not seg_on
		prev = pt

	# Two "now" lines on the same µs axis: your proper clock (mint) and the
	# lab clock (sun). Born together; γ pries them apart.
	var age := 0.0
	if muon != null and is_instance_valid(muon):
		age = muon.get("age_us")
	var tau_x := _x(age, origin)
	var y_dash := 0.0
	while y_dash < PLOT_H:
		draw_line(Vector2(tau_x, origin.y - y_dash),
			Vector2(tau_x, origin.y - minf(y_dash + 5.0, PLOT_H)), Color(Juice.MINT, 0.85), 1.8, true)
		y_dash += 9.0
	var tau_label := "τ %.1f" % age
	draw_string(font, Vector2(tau_x + 3.0, origin.y - PLOT_H + 10.0), tau_label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(Juice.MINT, 0.95))

	var now_x := _x(lab, origin)
	var now_col := Color(1.0, 0.35, 0.42, 0.95) if danger else Color(Juice.SUN, 0.95)
	draw_line(Vector2(now_x, origin.y), Vector2(now_x, origin.y - PLOT_H), now_col, 2.0, true)
	draw_circle(Vector2(now_x, _y(p_now, origin)), 3.4, now_col)
	draw_string(font, Vector2(now_x + 3.0, origin.y - PLOT_H + 22.0), "lab %.1f" % lab,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, now_col)

	# Readouts.
	draw_string(Juice.hand_font, Vector2(PAD, PAD + 8.0), "P(decay)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.CREAM, 0.75))
	var pct := "%d%%" % int(round(p_now * 100.0))
	var pw := font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(font, Vector2(PAD + PLOT_W - pw, PAD + 9.0), pct,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, now_col)
	var tau_text := "γτ = %.1f µs" % mean_life
	draw_string(font, Vector2(PAD + 78.0, PAD + 8.0), tau_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.CREAM, 0.5))

	if danger:
		var flash := 0.4 + 0.4 * absf(sin(_t * 8.0))
		var border := StyleBoxFlat.new()
		border.bg_color = Color(0, 0, 0, 0)
		border.set_border_width_all(2)
		border.border_color = Color(1.0, 0.3, 0.38, flash)
		border.set_corner_radius_all(12)
		border.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
