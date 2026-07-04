extends Control
## Every life you've lived, binned twice: proper time on top (the one whose
## mean hunts 2.2 µs — that's the point), lab time below, γ-stretched all
## over the place. No caption explains why; the sky keeps its rules.

const BINS := 22
const RANGE_US := 6.6
const RANGE_LAB := 150.0
const PLOT_W := 232.0
const PROPER_H := 58.0
const LAB_H := 34.0
const PAD := 14.0

var compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(PLOT_W + PAD * 2.0,
		PAD + 14.0 + PROPER_H + 22.0 + LAB_H + PAD)
	size = custom_minimum_size


func _bin_counts(values: Array, value_range: float) -> Array:
	var counts := []
	counts.resize(BINS)
	counts.fill(0)
	for v in values:
		var b := clampi(int(float(v) / value_range * BINS), 0, BINS - 1)
		counts[b] += 1
	return counts


func _draw_histo(origin: Vector2, h: float, counts: Array, bar_color: Color,
		mean_value: float, value_range: float, text_col: Color, emphasize: bool) -> void:
	var max_count := 1
	for c in counts:
		max_count = maxi(max_count, int(c))
	var bar_w := PLOT_W / BINS
	for b in BINS:
		var bh := float(counts[b]) / max_count * h
		if bh <= 0.0:
			continue
		draw_rect(Rect2(origin.x + b * bar_w + 1.0, origin.y - bh, bar_w - 2.0, bh), bar_color)
	draw_line(origin, origin + Vector2(PLOT_W, 0), Color(text_col, 0.4), 1.4, true)
	if mean_value > 0.0:
		var mean_x := origin.x + clampf(mean_value / value_range, 0.0, 1.0) * PLOT_W
		var col := Juice.SUN if emphasize else Color(text_col, 0.55)
		draw_line(Vector2(mean_x, origin.y - h), Vector2(mean_x, origin.y), col,
			2.2 if emphasize else 1.4, true)
		if emphasize:
			draw_circle(Vector2(mean_x, origin.y - h - 3.0), 3.0, Juice.SUN)


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Juice.INK, 0.5 if compact else 0.08)
	sb.set_corner_radius_all(12)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	var text_col := Juice.CREAM if compact else Juice.INK
	var n := Meta.lifetimes.size()

	# Proper time: the headline distribution.
	var top_origin := Vector2(PAD, PAD + 14.0 + PROPER_H)
	if n > 0:
		_draw_histo(top_origin, PROPER_H, _bin_counts(Meta.lifetimes, RANGE_US),
			Color(Juice.LILAC, 0.85), Meta.lifetime_mean(), RANGE_US, text_col, true)
		# The 2.2 µs tick, quietly waiting under the mean.
		var target_x := PAD + 2.2 / RANGE_US * PLOT_W
		var y := 0.0
		while y < PROPER_H:
			draw_line(Vector2(target_x, top_origin.y - PROPER_H + y),
				Vector2(target_x, top_origin.y - PROPER_H + minf(y + 4.0, PROPER_H)),
				Color(text_col, 0.35), 1.2, true)
			y += 8.0
		draw_string(Juice.hand_font, Vector2(PAD, PAD + 6.0),
			"proper · mean %.2f µs · n %d" % [Meta.lifetime_mean(), n],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(text_col, 0.85))
	else:
		draw_string(Juice.hand_font, Vector2(PAD, PAD + 6.0), "lives · none yet",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(text_col, 0.7))
		return

	# Lab time: the same deaths in the other frame.
	var lab_origin := Vector2(PAD, top_origin.y + 22.0 + LAB_H)
	_draw_histo(lab_origin, LAB_H, _bin_counts(Meta.lifetimes_lab, RANGE_LAB),
		Color(Juice.RAIN, 0.6), Meta.lab_mean(), RANGE_LAB, text_col, false)
	draw_string(Juice.hand_font, Vector2(PAD, top_origin.y + 15.0),
		"lab · mean %.0f µs" % Meta.lab_mean(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(text_col, 0.6))
