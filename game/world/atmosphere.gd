extends Node2D
## The sky. The gradient itself is a shader (smooth, dithered, nebula wisps,
## sun glow) on a child layer beneath; stars, parallax haze, and the ground
## are drawn here on top. Everything follows the camera — cheap and seamless.
##
## `mode` splits the sky across the stage's real 3D depth planes:
##   "full"  — everything in one viewport (fallback / non-stage contexts)
##   "back"  — sky gradient + far haze + plain ground (the far plane)
##   "world" — stars, mid haze, ground + flowers (the gameplay plane;
##             stars live here so the relativity pass Doppler-shifts them)
##   "front" — near haze only (the plane in front of the gameplay quad)

var mode := "full"

var _t := 0.0
var _sky: Node2D
var _sky_mat: ShaderMaterial
var _fg: Node2D


func _ready() -> void:
	z_index = -10
	if mode == "full" or mode == "back":
		_sky_mat = ShaderMaterial.new()
		_sky_mat.shader = load("res://game/fx/sky.gdshader")
		_sky = Node2D.new()
		_sky.z_index = -1  # beneath this node's own drawing
		_sky.material = _sky_mat
		_sky.draw.connect(_draw_sky_rect)
		add_child(_sky)
	if mode == "full" or mode == "front":
		# Near haze: in front of the play plane. In "full" mode the depth is
		# faked with a >1 parallax factor; on the stage the plane itself sits
		# at a real z in front of the gameplay quad.
		_fg = Node2D.new()
		_fg.z_index = 50  # relative would exceed the parent's -10; use absolute
		_fg.z_as_relative = false
		_fg.draw.connect(_draw_foreground)
		add_child(_fg)


func _draw_sky_rect() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport_rect().size
	var center := cam.get_screen_center_position()
	_sky.draw_rect(Rect2(center - vp * 0.62, vp * 1.24), Color.WHITE)


## A printed cloud band: stacked flat strata strokes with a coral under-pass
## and an ink hairline — the riso answer to "soft oval".
func _puff(c: CanvasItem, p: Vector2, rx: float, a: float, h: int) -> void:
	var sway := sin(_t * 0.07 + float(h % 31)) * rx * 0.04
	c.draw_line(p + Vector2(-rx * 0.72 + sway, rx * 0.24), p + Vector2(rx * 0.86 + sway, rx * 0.24),
		Color(Juice.PINK, a * 0.55), rx * 0.17)
	c.draw_line(p + Vector2(-rx, 0), p + Vector2(rx * 0.9, 0),
		Color(0.95, 0.92, 0.85, a), rx * 0.42)
	c.draw_line(p + Vector2(-rx * 0.5, -rx * 0.30), p + Vector2(rx * 0.55, -rx * 0.30),
		Color(0.98, 0.95, 0.90, a * 0.85), rx * 0.26)
	c.draw_line(p + Vector2(-rx * 0.86, rx * 0.42), p + Vector2(rx * 0.62, rx * 0.42),
		Color(Juice.INK, a * 0.8), 1.5)


func _process(delta: float) -> void:
	_t += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null and _sky_mat != null:
		var vp := get_viewport_rect().size
		var center := cam.get_screen_center_position()
		var zoom_inv := 1.0 / maxf(cam.zoom.y, 0.01)
		_sky_mat.set_shader_parameter("cam_top", center.y - vp.y * 0.5 * zoom_inv)
		_sky_mat.set_shader_parameter("cam_left", center.x - vp.x * 0.5 * zoom_inv)
		_sky_mat.set_shader_parameter("cam_h", vp.y * zoom_inv)
		_sky_mat.set_shader_parameter("cam_w", vp.x * zoom_inv)
		_sky_mat.set_shader_parameter("t", _t)
	if _sky != null:
		_sky.queue_redraw()
	if _fg != null:
		_fg.queue_redraw()
	queue_redraw()


func _draw_foreground() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport_rect().size
	var center := cam.get_screen_center_position()
	var top := center.y - vp.y * 0.62
	var left := center.x - vp.x * 0.62
	var width := vp.x * 1.24
	var bottom := center.y + vp.y * 0.62
	var par := 1.35
	var qtl := (Vector2(left, top) - center * (1.0 - par)) / par
	var qbr := (Vector2(left + width, bottom) - center * (1.0 - par)) / par
	var cell := 820.0
	for cx in range(int(floor(qtl.x / cell)), int(ceil(qbr.x / cell)) + 1):
		for cy in range(int(floor(qtl.y / cell)), int(ceil(qbr.y / cell)) + 1):
			var h := absi(hash(Vector2i(cx + 101, cy + 203)))
			if h % 5 != 0:
				continue
			var q := Vector2(cx * cell + float(h % 600), cy * cell + float((h / 13) % 600))
			var p := q * par + center * (1.0 - par)
			# Same rule as the other haze: none in space.
			var air := clampf((q.y - 14000.0) / 14000.0, 0.0, 1.0)
			if air <= 0.01 or q.y > Atmos.GROUND_Y - 300.0:
				continue
			var rx := 180.0 + float(h % 130)
			_puff(_fg, p, rx, 0.07 * air, h)


func _draw() -> void:
	if mode == "front":
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport_rect().size
	var center := cam.get_screen_center_position()
	var top := center.y - vp.y * 0.62
	var bottom := center.y + vp.y * 0.62
	var left := center.x - vp.x * 0.62
	var width := vp.x * 1.24

	# (The sky gradient itself is shader-drawn on the child layer below.)

	# The starfield: four-point diamond glints, never plain dots. No
	# painted streaks — speed and perspective come from the real 3D
	# camera pitch, the dolly parallax, and the relativity blur.
	if (mode == "full" or mode == "world") and top < 36000.0:
		var star_bottom := minf(bottom, 36000.0)
		var cell := 140.0
		for cx in range(int(floor(left / cell)), int(ceil((left + width) / cell)) + 1):
			for cy in range(int(floor(top / cell)), int(ceil(star_bottom / cell)) + 1):
				var h := absi(hash(Vector2i(cx, cy)))
				var fx := float(h % 997) / 997.0
				var fy := float((h / 997) % 991) / 991.0
				var pos := Vector2(cx * cell + fx * cell, cy * cell + fy * cell)
				var air_fade := clampf(1.0 - (pos.y - 15000.0) / 21000.0, 0.0, 1.0)
				if air_fade <= 0.01:
					continue
				var twinkle := 0.55 + 0.45 * sin(_t * 1.7 + float(h % 628) * 0.01)
				var size := 1.4 + float(h % 17) / 8.0
				var star_col := Color(1.0, 1.0, 0.94, 0.75 * air_fade * twinkle)
				var s2 := size * (1.0 + 0.4 * twinkle)
				draw_colored_polygon(PackedVector2Array([
					pos + Vector2(0, -s2 * 1.6), pos + Vector2(s2 * 0.7, 0),
					pos + Vector2(0, s2 * 1.6), pos + Vector2(-s2 * 0.7, 0),
				]), star_col)
				if size > 2.6:
					var g := size * 3.2 * twinkle
					draw_line(pos - Vector2(g, 0), pos + Vector2(g, 0),
						Color(star_col, star_col.a * 0.35), 1.0, true)
					draw_line(pos - Vector2(0, g), pos + Vector2(0, g),
						Color(star_col, star_col.a * 0.35), 1.0, true)

	# Ridiculous Fishing layer seams: each atmosphere boundary is a band
	# of hard diagonal stripes — the world changes in cuts, not fades.
	if mode == "full" or mode == "world":
		for by: float in [12000.0, 28500.0, 48000.0]:
			if bottom < by - 170.0 or top > by + 170.0:
				continue
			var sx2 := left - 240.0
			var si := 0
			while sx2 < left + width + 240.0:
				var stripe_col := Color(Juice.PAPER, 0.05) if si % 2 == 0 else Color(Juice.INK, 0.06)
				draw_line(Vector2(sx2, by + 150.0), Vector2(sx2 + 190.0, by - 150.0), stripe_col, 40.0)
				sx2 += 130.0
				si += 1

	# Far parallax layer: barely-there haze at 30% of camera speed.
	if mode == "full" or mode == "back":
		var par2 := 0.3
		var q2tl := (Vector2(left, top) - center * (1.0 - par2)) / par2
		var q2br := (Vector2(left + width, bottom) - center * (1.0 - par2)) / par2
		var p2cell := 940.0
		for cx in range(int(floor(q2tl.x / p2cell)), int(ceil(q2br.x / p2cell)) + 1):
			for cy in range(int(floor(q2tl.y / p2cell)), int(ceil(q2br.y / p2cell)) + 1):
				var h4 := absi(hash(Vector2i(cx + 31, cy + 47)))
				if h4 % 4 != 0:
					continue
				var q4 := Vector2(cx * p2cell + float(h4 % 700), cy * p2cell + float((h4 / 11) % 700))
				var p4 := q4 * par2 + center * (1.0 - par2)
				# No haze in space: fade in below ~50 km where there's air.
				var air4 := clampf((q4.y - 15000.0) / 15000.0, 0.0, 1.0)
				if air4 <= 0.01 or q4.y > Atmos.GROUND_Y - 300.0:
					continue
				_puff(self, p4, 150.0 + float(h4 % 120), 0.045 * air4, h4)

	# Mid parallax layer: haze puffs drifting at 55% of camera speed.
	if mode == "full" or mode == "world":
		var par := 0.55
		var qtl := (Vector2(left, top) - center * (1.0 - par)) / par
		var qbr := (Vector2(left + width, bottom) - center * (1.0 - par)) / par
		var pcell := 640.0
		for cx in range(int(floor(qtl.x / pcell)), int(ceil(qbr.x / pcell)) + 1):
			for cy in range(int(floor(qtl.y / pcell)), int(ceil(qbr.y / pcell)) + 1):
				var h3 := absi(hash(Vector2i(cx + 7, cy + 13)))
				if h3 % 3 != 0:
					continue
				var q := Vector2(cx * pcell + float(h3 % 500), cy * pcell + float((h3 / 7) % 500))
				var p := q * par + center * (1.0 - par)
				var air := clampf((q.y - 13500.0) / 13500.0, 0.0, 1.0)
				if air <= 0.01 or q.y > Atmos.GROUND_Y - 300.0:
					continue
				var rx := 90.0 + float(h3 % 90)
				_puff(self, p, rx, 0.06 * air, h3)

	# Ground: a TURF BAND, not a floor — muons punch straight through, and
	# below it the sediment gradient (the sky shader's rock stops) shows.
	# The back plane gets a plain darker band as the real horizon.
	if bottom > Atmos.GROUND_Y:
		if mode == "back":
			draw_rect(Rect2(left, Atmos.GROUND_Y - 40.0, width,
				minf(bottom - Atmos.GROUND_Y + 100.0, 220.0)), Atmos.GRASS_DARK.darkened(0.18))
		else:
			draw_rect(Rect2(left, Atmos.GROUND_Y, width,
				minf(bottom - Atmos.GROUND_Y + 60.0, 110.0)), Atmos.GRASS)
			if bottom > Atmos.GROUND_Y + 110.0:
				draw_rect(Rect2(left, Atmos.GROUND_Y + 110.0, width, 55.0), Atmos.GRASS_DARK)
				draw_line(Vector2(left, Atmos.GROUND_Y + 165.0),
					Vector2(left + width, Atmos.GROUND_Y + 165.0), Color(Juice.INK, 0.45), 2.5)
			# Sparse wildflowers in the print inks.
			var fcell := 150.0
			for cx in range(int(floor(left / fcell)), int(ceil((left + width) / fcell)) + 1):
				var h2 := absi(hash(Vector2i(cx, 77)))
				if h2 % 3 == 0:
					continue
				var fx2 := float(h2 % 89) / 89.0
				var pos2 := Vector2(cx * fcell + fx2 * fcell, Atmos.GROUND_Y + 20.0 + float(h2 % 60))
				var col := Juice.PINK if h2 % 2 == 0 else Juice.SUN
				draw_line(pos2 + Vector2(0, 6), pos2 + Vector2(0, 16), Color(Juice.INK, 0.5), 1.5)
				draw_circle(pos2, 3.4, col)

	# The bedrock: wavy sediment strata with occasional misprint echoes,
	# and till speckles — a Ridiculous-Fishing descent to the cavern.
	if (mode == "full" or mode == "world") and bottom > Atmos.GROUND_Y + 200.0:
		# A solid earth wash so underground reads as dirt and rock, not dark
		# sky — deepening as you descend so the headlamp beam has something to
		# bite into.
		var ey0 := maxf(top, Atmos.GROUND_Y)
		var deep_f := clampf((ey0 - Atmos.GROUND_Y) / 9000.0, 0.0, 1.0)
		draw_rect(Rect2(left, ey0, width, bottom - ey0 + 40.0),
			Color(0.11, 0.083, 0.055, 0.42 + 0.4 * deep_f))
		var y0 := maxf(top, Atmos.GROUND_Y + 240.0)
		var yn := minf(bottom, Atmos.WORLD_DEPTH)
		var row := 340.0
		for ri in range(int(floor(y0 / row)), int(ceil(yn / row)) + 1):
			var ry := ri * row
			if ry < Atmos.GROUND_Y + 240.0 or ry > Atmos.WORLD_DEPTH:
				continue
			var hh := absi(hash(ri * 733))
			var amp := 6.0 + float(hh % 12)
			var pts := PackedVector2Array()
			var sx := left
			while sx <= left + width + 90.0:
				pts.append(Vector2(sx, ry + sin(sx * 0.004 + float(hh % 40)) * amp))
				sx += 90.0
			draw_polyline(pts, Color(Juice.INK, 0.22), 2.0, true)
			if hh % 3 == 0:
				var pts2 := PackedVector2Array()
				for q in pts:
					pts2.append(q + Vector2(-7.0, 5.0))
				draw_polyline(pts2, Color(Juice.PINK, 0.10), 2.0, true)
		var scell := 240.0
		for cx in range(int(floor(left / scell)), int(ceil((left + width) / scell)) + 1):
			for cy in range(int(floor(y0 / scell)), int(ceil(yn / scell)) + 1):
				var h5 := absi(hash(Vector2i(cx + 913, cy + 57)))
				if h5 % 3 != 0:
					continue
				var sp := Vector2(cx * scell + float(h5 % 200), cy * scell + float((h5 / 7) % 200))
				if sp.y < Atmos.GROUND_Y + 260.0:
					continue
				draw_rect(Rect2(sp.x, sp.y, 5.0 + float(h5 % 6), 2.5),
					Color(Juice.PAPER, 0.10) if h5 % 2 == 0 else Color(Juice.INK, 0.28))
