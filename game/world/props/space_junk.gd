extends "res://game/world/props/prop_base.gd"
## A tumbling chunk of derelict hardware in the thermosphere. Rare, and to
## be AVOIDED — clip it and it scrubs your speed like a meteor does.

const SLOW := 90.0

var _t := 0.0
var _spin := 0.0
var _drift := Vector2.ZERO
var _hit_cd := 0.0
var _poly: PackedVector2Array


func _setup() -> void:
	add_to_group("hazard")
	_t = randf() * 6.0
	_spin = randf_range(-1.2, 1.2)
	_drift = Vector2(randf_range(-30, 30), randf_range(-8, 8))
	z_index = 2
	# A jagged debris silhouette.
	_poly = PackedVector2Array()
	var n := 8
	for i in n:
		var a := float(i) / n * TAU
		var r := randf_range(14.0, 26.0)
		_poly.append(Vector2.from_angle(a) * r)


func _process(delta: float) -> void:
	_t += delta
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	position += _drift * delta
	var m := muon()
	if m != null and m.get("alive") and _hit_cd <= 0.0 and muon_dist() < 46.0:
		_hit_cd = 1.0
		m.slow(SLOW, "space junk")
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _t * _spin, Vector2.ONE)
	draw_colored_polygon(_poly, Color("6b6f7a"))
	draw_polyline(_poly + PackedVector2Array([_poly[0]]), Color(Juice.INK, 0.8), 2.0, true)
	# A couple of glinty panel bits and a warning stripe.
	draw_line(Vector2(-8, -4), Vector2(9, 3), Color(Juice.PAPER, 0.5), 2.0)
	draw_rect(Rect2(-10, 6, 20, 3), Color(Juice.SUN, 0.7))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
