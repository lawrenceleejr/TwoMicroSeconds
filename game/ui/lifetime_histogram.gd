extends Control
## Every life you've lived, binned. The running mean drifts toward 2.2 µs
## as the deaths pile up — no caption explains why; the sky keeps its rules.

const BINS := 22
const RANGE_US := 6.6
const PLOT_W := 232.0
const PLOT_H := 64.0
const PAD := 14.0

var compact := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(PLOT_W + PAD * 2.0, PLOT_H + PAD * 2.0 + 14.0)
	size = custom_minimum_size


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Juice.INK, 0.5 if compact else 0.08)
	sb.set_corner_radius_all(12)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	var text_col := Juice.CREAM if compact else Juice.INK

	var origin := Vector2(PAD, PAD + 12.0 + PLOT_H)
	var counts := []
	counts.resize(BINS)
	counts.fill(0)
	var max_count := 1
	for v in Meta.lifetimes:
		var b := clampi(int(float(v) / RANGE_US * BINS), 0, BINS - 1)
		counts[b] += 1
		max_count = maxi(max_count, counts[b])

	# Bars.
	var bar_w := PLOT_W / BINS
	for b in BINS:
		var h := float(counts[b]) / max_count * PLOT_H
		if h <= 0.0:
			continue
		draw_rect(Rect2(origin.x + b * bar_w + 1.0, origin.y - h, bar_w - 2.0, h),
			Color(Juice.LILAC, 0.85))
	draw_line(origin, origin + Vector2(PLOT_W, 0), Color(text_col, 0.4), 1.4, true)

	# The 2.2 µs tick, quietly waiting.
	var target_x := origin.x + 2.2 / RANGE_US * PLOT_W
	var y := 0.0
	while y < PLOT_H:
		draw_line(Vector2(target_x, origin.y - PLOT_H + y),
			Vector2(target_x, origin.y - PLOT_H + minf(y + 4.0, PLOT_H)),
			Color(text_col, 0.35), 1.2, true)
		y += 8.0

	# The running mean, hunting it.
	var n := Meta.lifetimes.size()
	if n > 0:
		var mean := Meta.lifetime_mean()
		var mean_x := origin.x + clampf(mean / RANGE_US, 0.0, 1.0) * PLOT_W
		draw_line(Vector2(mean_x, origin.y - PLOT_H), Vector2(mean_x, origin.y),
			Juice.SUN, 2.2, true)
		draw_circle(Vector2(mean_x, origin.y - PLOT_H - 3.0), 3.0, Juice.SUN)
		draw_string(Juice.hand_font, Vector2(PAD, PAD + 6.0),
			"lives · mean %.2f µs · n %d" % [mean, n],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(text_col, 0.8))
	else:
		draw_string(Juice.hand_font, Vector2(PAD, PAD + 6.0), "lives · none yet",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(text_col, 0.7))
