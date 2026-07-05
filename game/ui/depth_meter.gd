extends Control
## Ridiculous Fishing-style descent gauge: the entire journey — 100 km of
## sky down to the CMS cavern — as a slim color strip with a marker
## riding it. The bottom of the bar is the whole point of the trip.

var muon: Node2D = null

# [world_y, label] anchors shown as ticks.
const TICKS := [
	[0.0, "100"],
	[12000.0, "85"],
	[28500.0, "50"],
	[48000.0, "12"],
	[69000.0, "0"],
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(52, 100)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var h := size.y
	var bar_x := 10.0
	# The strip itself: the sky's actual inks, sampled down the descent.
	var steps := 44
	for i in steps:
		var f := float(i) / float(steps)
		var wy := f * Atmos.CMS_Y
		draw_rect(Rect2(bar_x, f * h, 5.0, h / steps + 1.0), Atmos.sky_color_at(wy))
	draw_rect(Rect2(bar_x, 0, 5.0, h), Color(Juice.INK, 0.65), false, 1.0)
	var font := ThemeDB.fallback_font
	# Altitude ticks.
	for t in TICKS:
		var ty: float = float(t[0]) / Atmos.CMS_Y * h
		draw_line(Vector2(bar_x - 3.0, ty), Vector2(bar_x + 8.0, ty), Color(Juice.CREAM, 0.55), 1.0)
		draw_string(font, Vector2(bar_x + 12.0, ty + 4.0), str(t[1]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.CREAM, 0.6))
	# CMS at the very bottom: a tiny coral wheel — the destination.
	var cy := h - 1.0
	draw_circle(Vector2(bar_x + 2.5, cy), 5.5, Juice.PINK)
	draw_circle(Vector2(bar_x + 2.5, cy), 2.4, Juice.PAPER)
	draw_string(font, Vector2(bar_x + 12.0, cy + 4.0), "CMS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.PINK, 0.9))
	# You, riding the strip.
	if muon != null and is_instance_valid(muon):
		var f_m := clampf(muon.global_position.y / Atmos.CMS_Y, 0.0, 1.0)
		var my := f_m * h
		draw_colored_polygon(PackedVector2Array([
			Vector2(bar_x - 2.0, my), Vector2(bar_x - 9.0, my - 5.0), Vector2(bar_x - 9.0, my + 5.0),
		]), Juice.SUN)
		draw_circle(Vector2(bar_x - 12.0, my), 3.4, Color(0.98, 0.95, 0.88))
