extends Control
## The fate curve: probability of still existing, t seconds from now.
## A pure exponential survival curve, exp(-t / (gamma * tau)) — when you
## gain speed the whole curve visibly stretches (time dilation, unlabeled).
## No axes lectures; it just breathes in the corner and makes you nervous.

const PLOT_W := 232.0
const PLOT_H := 74.0
const PAD := 14.0
const WINDOW_S := 75.0  # seconds of lab time spanned by the x-axis

var muon: Node2D = null

var _gamma_disp := 8.0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(PLOT_W + PAD * 2.0, PLOT_H + PAD * 2.0 + 10.0)


func _process(delta: float) -> void:
	_t += delta
	if muon != null and is_instance_valid(muon):
		var target: float = muon.get("gamma")
		_gamma_disp = lerpf(_gamma_disp, target, 1.0 - exp(-3.5 * delta))
	queue_redraw()


func _draw() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Juice.INK, 0.5)
	sb.set_corner_radius_all(12)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

	var origin := Vector2(PAD, PAD + 8.0 + PLOT_H)
	var mean_life: float = _gamma_disp * 2.2 * 1.5  # gamma * tau, lab seconds

	# Filled survival curve.
	var pts := PackedVector2Array()
	var poly := PackedVector2Array()
	poly.append(origin)
	var steps := 40
	for i in steps + 1:
		var f := float(i) / steps
		var t := f * WINDOW_S
		var p := exp(-t / mean_life)
		var pt := origin + Vector2(f * PLOT_W, -p * PLOT_H)
		pts.append(pt)
		poly.append(pt)
	poly.append(origin + Vector2(PLOT_W, 0))
	draw_colored_polygon(poly, Color(Juice.PINK, 0.22))
	draw_polyline(pts, Color(Juice.CREAM, 0.95), 2.2, true)

	# Baseline.
	draw_line(origin, origin + Vector2(PLOT_W, 0), Color(Juice.CREAM, 0.35), 1.4, true)

	# Marker at the mean lifetime — it slides right as gamma grows.
	var mean_x := clampf(mean_life / WINDOW_S, 0.0, 1.0) * PLOT_W
	var dash_top := origin + Vector2(mean_x, -PLOT_H)
	var y := 0.0
	while y < PLOT_H:
		draw_line(dash_top + Vector2(0, y), dash_top + Vector2(0, minf(y + 5.0, PLOT_H)),
			Color(Juice.SUN, 0.8), 1.6, true)
		y += 10.0
	draw_circle(origin + Vector2(mean_x, 4.0), 3.0, Juice.SUN)

	# "now": a nervous little pulse at the origin.
	var pulse := 3.0 + 1.4 * sin(_t * 5.0)
	draw_circle(origin + Vector2(0, -PLOT_H), pulse, Color(Juice.MINT, 0.9))

	draw_string(Juice.hand_font, Vector2(PAD, PAD + 4.0), "fate",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.CREAM, 0.75))
