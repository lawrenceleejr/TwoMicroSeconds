extends Node2D
## Birth of the muon: a cosmic ray streaks in and pops.

const DUR := 0.8

var _t := 0.0


func _ready() -> void:
	z_index = 9
	Sfx.play("dash", -2.0, 0.0)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DUR, 0.0, 1.0)
	var from := Vector2(-620.0, -760.0)
	if k < 0.4:
		var hk := k / 0.4
		var head := from.lerp(Vector2.ZERO, hk)
		var tail := from.lerp(Vector2.ZERO, maxf(hk - 0.35, 0.0))
		draw_line(tail, head, Color(Juice.SUN, 0.9), 5.0, true)
	else:
		var fk := (k - 0.4) / 0.6
		draw_circle(Vector2.ZERO, lerpf(4.0, 70.0, 1.0 - pow(1.0 - fk, 3.0)), Color(1, 1, 0.95, 0.6 * (1.0 - fk)))
