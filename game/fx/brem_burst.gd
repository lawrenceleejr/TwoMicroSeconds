extends Node2D
## A radiative burst: above a certain energy the muon brems photons forward,
## and each one seeds a brief mini-shower of secondaries ahead of you.

const DUR := 0.5

var dir := Vector2.DOWN

var _t := 0.0
var _rays := []


func _ready() -> void:
	z_index = 6
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	for i in 5:
		var ang := dir.angle() + randf_range(-0.55, 0.55)
		_rays.append({
			"dir": Vector2.from_angle(ang),
			"len": randf_range(45.0, 105.0),
			"w": randf_range(1.4, 2.6),
			"tint": 0.5 + randf() * 0.5,
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DUR
	var grow := 1.0 - pow(1.0 - minf(k * 2.2, 1.0), 2.0)
	var alpha := (1.0 - k) * 0.8
	draw_circle(Vector2.ZERO, 5.0 * (1.0 - k), Color(0.85, 0.95, 1.0, alpha))
	for r in _rays:
		var tip: Vector2 = (r["dir"] as Vector2) * float(r["len"]) * grow
		var col := Color(0.8, 0.9, 1.0).lerp(Color(1, 1, 1), float(r["tint"]))
		col.a = alpha * float(r["tint"])
		draw_line(tip * 0.25, tip, col, float(r["w"]), true)
		draw_circle(tip, 2.0, col)
