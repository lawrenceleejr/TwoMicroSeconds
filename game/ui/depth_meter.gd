extends Control
## Ridiculous Fishing-style descent gauge: the entire journey — 100 km of
## sky down to the LZ cavern 1.5 km underground — as a slim color strip with
## a marker riding it. Every detector in the stack is ticked on the bar.

var muon: Node2D = null

# [world_y, altitude_km label] anchors shown as sky ticks. The ground and
# everything below it is marked by the detector ticks instead.
const TICKS := [
	[0.0, "100"],
	[12000.0, "85"],
	[28500.0, "50"],
	[48000.0, "12"],
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(74, 100)


func _process(_delta: float) -> void:
	queue_redraw()


func _kind_color(kind: String) -> Color:
	match kind:
		"hawc": return Juice.SUN
		"icecube": return Juice.RAIN
		"cms": return Juice.PINK
		_: return Juice.PERIWINKLE


func _draw() -> void:
	var h := size.y
	var bar_x := 10.0
	var bottom := Atmos.LZ_Y  # the strip's full range: birth → the LZ cavern
	# The strip itself: the sky's actual inks, sampled down the descent.
	var steps := 48
	for i in steps:
		var f := float(i) / float(steps)
		draw_rect(Rect2(bar_x, f * h, 5.0, h / steps + 1.0), Atmos.sky_color_at(f * bottom))
	draw_rect(Rect2(bar_x, 0, 5.0, h), Color(Juice.INK, 0.65), false, 1.0)
	var font := ThemeDB.fallback_font
	# Altitude ticks (the sky portion).
	for t in TICKS:
		var ty: float = float(t[0]) / bottom * h
		draw_line(Vector2(bar_x - 3.0, ty), Vector2(bar_x + 8.0, ty), Color(Juice.CREAM, 0.55), 1.0)
		draw_string(font, Vector2(bar_x + 12.0, ty + 4.0), str(t[1]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.CREAM, 0.6))
	# The detector stack: a labelled tick + colored bead at each true depth.
	# The three shallow ones bunch up near the surface, so labels are nudged
	# apart vertically to stay readable.
	var last_label_y := -100.0
	for det in Atmos.DETECTORS:
		var dy: float = float(det["y"]) / bottom * h
		var col := _kind_color(det["kind"])
		draw_line(Vector2(bar_x - 3.0, dy), Vector2(bar_x + 8.0, dy), Color(col, 0.9), 1.5)
		draw_circle(Vector2(bar_x + 2.5, dy), 4.0, col)
		draw_circle(Vector2(bar_x + 2.5, dy), 1.8, Juice.PAPER)
		var ly := clampf(maxf(dy + 4.0, last_label_y + 12.0), 8.0, h - 2.0)
		last_label_y = ly
		draw_string(font, Vector2(bar_x + 12.0, ly), str(det["label"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(col, 0.95))
	# You, riding the strip.
	if muon != null and is_instance_valid(muon):
		var f_m := clampf(muon.global_position.y / bottom, 0.0, 1.0)
		var my := f_m * h
		draw_colored_polygon(PackedVector2Array([
			Vector2(bar_x - 2.0, my), Vector2(bar_x - 9.0, my - 5.0), Vector2(bar_x - 9.0, my + 5.0),
		]), Juice.SUN)
		draw_circle(Vector2(bar_x - 12.0, my), 3.4, Color(0.98, 0.95, 0.88))
