extends Node2D
## Fading afterimage left behind while dashing.

const DUR := 0.35

var _t := 0.0


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / DUR
	draw_circle(Vector2.ZERO, 15.0 * (1.0 - k * 0.5), Color(1.0, 1.0, 0.97, 0.35 * (1.0 - k)))
