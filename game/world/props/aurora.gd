extends "res://game/world/props/prop_base.gd"
## A wavy ribbon of light. Fly through it and its electrojet gives you a
## push (auroral electric fields really do accelerate charged particles).

const SEGS := 22
const SEG_W := 34.0
const BOOST := 90.0

var _t := 0.0
var _glow := 0.0
var _hue_shift := 0.0
var _boost_cd := 0.0


func _setup() -> void:
	add_to_group("aurora")
	_t = randf() * 10.0
	_hue_shift = randf_range(-0.06, 0.06)
	z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	_glow = maxf(_glow - delta * 0.8, 0.0)
	_boost_cd = maxf(_boost_cd - delta, 0.0)
	var m := muon()
	if m != null and m.get("alive") and absf(m.global_position.y - global_position.y) < 140.0:
		for i in SEGS:
			if _point(i).distance_to(m.global_position) < 55.0:
				_tickle()
				if _boost_cd <= 0.0:
					_boost_cd = 1.6
					m.boost(BOOST, "auroral electrojet")
				break
	queue_redraw()


func _point(i: int) -> Vector2:
	return global_position + Vector2(i * SEG_W - SEGS * SEG_W * 0.5, sin(_t * 0.8 + i * 0.45) * 44.0)


func _tickle() -> void:
	_glow = 1.0
	if not Tasks.is_done("tickle_aurora"):
		Tasks.complete("tickle_aurora")
		Sfx.play("pop", -4.0)


func zapped(_source: Node2D) -> void:
	_tickle()


func _draw() -> void:
	for i in SEGS:
		var p := _point(i) - global_position
		var f := float(i) / SEGS
		var col := Juice.MINT.lerp(Juice.LILAC, f)
		col.h = wrapf(col.h + _hue_shift, 0.0, 1.0)
		var alpha := 0.24 + 0.1 * sin(_t * 1.3 + i * 0.7) + _glow * 0.3
		draw_rect(Rect2(p.x - 13.0, p.y - 95.0, 26.0, 190.0), Color(col, clampf(alpha, 0.05, 0.6)))
	var points := PackedVector2Array()
	for i in SEGS:
		points.append(_point(i) - global_position)
	draw_polyline(points, Color(1.0, 1.0, 1.0, 0.35 + _glow * 0.5), 2.5, true)
