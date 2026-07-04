extends Node2D
## The sky. The gradient itself is a shader (smooth, dithered, nebula wisps,
## sun glow) on a child layer beneath; stars, parallax haze, and the ground
## are drawn here on top. Everything follows the camera — cheap and seamless.

var _t := 0.0
var _sky: Node2D
var _sky_mat: ShaderMaterial


func _ready() -> void:
	z_index = -10
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = load("res://game/fx/sky.gdshader")
	_sky = Node2D.new()
	_sky.z_index = -1  # beneath this node's own drawing
	_sky.material = _sky_mat
	_sky.draw.connect(_draw_sky_rect)
	add_child(_sky)


func _draw_sky_rect() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp := get_viewport_rect().size
	var center := cam.get_screen_center_position()
	_sky.draw_rect(Rect2(center - vp * 0.62, vp * 1.24), Color.WHITE)


func _process(delta: float) -> void:
	_t += delta
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var vp := get_viewport_rect().size
		var center := cam.get_screen_center_position()
		var zoom_inv := 1.0 / maxf(cam.zoom.y, 0.01)
		_sky_mat.set_shader_parameter("cam_top", center.y - vp.y * 0.5 * zoom_inv)
		_sky_mat.set_shader_parameter("cam_left", center.x - vp.x * 0.5 * zoom_inv)
		_sky_mat.set_shader_parameter("cam_h", vp.y * zoom_inv)
		_sky_mat.set_shader_parameter("cam_w", vp.x * zoom_inv)
		_sky_mat.set_shader_parameter("t", _t)
	_sky.queue_redraw()
	queue_redraw()


func _draw() -> void:
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

	# Stars fade out as the air thickens.
	if top < 12000.0:
		var star_bottom := minf(bottom, 12000.0)
		var cell := 140.0
		for cx in range(int(floor(left / cell)), int(ceil((left + width) / cell)) + 1):
			for cy in range(int(floor(top / cell)), int(ceil(star_bottom / cell)) + 1):
				var h := absi(hash(Vector2i(cx, cy)))
				var fx := float(h % 997) / 997.0
				var fy := float((h / 997) % 991) / 991.0
				var pos := Vector2(cx * cell + fx * cell, cy * cell + fy * cell)
				var air_fade := clampf(1.0 - (pos.y - 5000.0) / 7000.0, 0.0, 1.0)
				if air_fade <= 0.01:
					continue
				var twinkle := 0.55 + 0.45 * sin(_t * 1.7 + float(h % 628) * 0.01)
				var size := 1.2 + float(h % 17) / 9.0
				draw_circle(pos, size, Color(1.0, 1.0, 0.94, 0.75 * air_fade * twinkle))

	# Far parallax layer: barely-there haze at 30% of camera speed.
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
			var air4 := clampf((q4.y - 5000.0) / 5000.0, 0.0, 1.0)
			if air4 <= 0.01:
				continue
			draw_set_transform(p4, 0.0, Vector2(1.0, 0.34))
			draw_circle(Vector2.ZERO, 150.0 + float(h4 % 120), Color(1.0, 1.0, 1.0, 0.035 * air4))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Mid parallax layer: haze puffs drifting at 55% of camera speed.
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
			var air := clampf((q.y - 4500.0) / 4500.0, 0.0, 1.0)
			if air <= 0.01:
				continue
			var rx := 90.0 + float(h3 % 90)
			draw_set_transform(p, 0.0, Vector2(1.0, 0.38))
			draw_circle(Vector2.ZERO, rx, Color(1.0, 1.0, 1.0, 0.05 * air))
			draw_circle(Vector2.ZERO, rx * 0.65, Color(1.0, 1.0, 1.0, 0.05 * air))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Ground.
	if bottom > Atmos.GROUND_Y:
		draw_rect(Rect2(left, Atmos.GROUND_Y, width, bottom - Atmos.GROUND_Y + 60.0), Atmos.GRASS)
		if bottom > Atmos.GROUND_Y + 150.0:
			draw_rect(
				Rect2(left, Atmos.GROUND_Y + 150.0, width, bottom - Atmos.GROUND_Y - 90.0),
				Atmos.GRASS_DARK
			)
		# Tiny flowers.
		var fcell := 110.0
		for cx in range(int(floor(left / fcell)), int(ceil((left + width) / fcell)) + 1):
			var h2 := absi(hash(Vector2i(cx, 77)))
			var fx2 := float(h2 % 89) / 89.0
			var pos2 := Vector2(cx * fcell + fx2 * fcell, Atmos.GROUND_Y + 30.0 + float(h2 % 100))
			var col := Juice.PINK if h2 % 2 == 0 else Juice.SUN
			draw_circle(pos2, 4.0, col)
			draw_circle(pos2, 1.6, Color(1, 1, 1, 0.9))
