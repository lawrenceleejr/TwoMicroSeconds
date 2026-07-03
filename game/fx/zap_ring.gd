extends Node2D
## The "honk": an expanding pastel ring.

const DUR := 0.3

var _t := 0.0


func _ready() -> void:
	z_index = 8


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DUR, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - k, 3.0)
	var r := lerpf(14.0, 190.0, eased)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.85 * (1.0 - k)), lerpf(7.0, 1.0, k), true)
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 40, Color(Juice.MINT, 0.5 * (1.0 - k)), lerpf(4.0, 1.0, k), true)
