extends Node2D
## Draws the sky gradient, twinkling stars up high, and the ground.
## Everything is redrawn each frame relative to the camera — cheap and seamless.

var _t := 0.0


func _ready() -> void:
	z_index = -10


func _process(delta: float) -> void:
	_t += delta
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

	# Sky bands.
	var step := 40.0
	var y := top
	while y < bottom:
		draw_rect(Rect2(left, y, width, step + 1.0), Atmos.sky_color_at(y + step * 0.5))
		y += step

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

	# Parallax depth layer: distant haze puffs drifting at 55% of camera
	# speed — the cheap trick that makes a flat sky read as deep.
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
			var rx := 90.0 + float(h3 % 90)
			draw_set_transform(p, 0.0, Vector2(1.0, 0.38))
			draw_circle(Vector2.ZERO, rx, Color(1.0, 1.0, 1.0, 0.05))
			draw_circle(Vector2.ZERO, rx * 0.65, Color(1.0, 1.0, 1.0, 0.05))
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
