extends Node2D
## A quick jagged discharge between two points. Bright, brief, gone.

const DUR := 0.22

var from := Vector2.ZERO
var to := Vector2.ZERO

var _t := 0.0
var _points := PackedVector2Array()


func _ready() -> void:
	z_index = 9
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	var segs := 7
	for i in segs + 1:
		var f := float(i) / segs
		var p := from.lerp(to, f)
		if i != 0 and i != segs:
			p += Vector2(randf_range(-18, 18), randf_range(-10, 10))
		_points.append(p - global_position)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DUR
	var alpha := (1.0 - k) * (0.6 + 0.4 * float(int(_t * 40.0) % 2))
	draw_polyline(_points, Color(1.0, 1.0, 0.85, alpha), lerpf(4.0, 1.0, k), true)
	draw_polyline(_points, Color(Juice.SUN, alpha * 0.5), lerpf(9.0, 2.0, k), true)
