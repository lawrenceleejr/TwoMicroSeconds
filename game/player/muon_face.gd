extends Node2D
## Eyes, blush, smile, and the little negative-charge badge.
## Stays upright while the body squashes underneath.

var _blink := 1.0
var _blink_timer := 2.5


func _process(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.2, 4.5)
		var tw := create_tween()
		tw.tween_property(self, "_blink", 0.08, 0.06)
		tw.tween_property(self, "_blink", 1.0, 0.09)
	queue_redraw()


func _draw() -> void:
	var muon_node := get_parent()
	var look := Vector2.ZERO
	var mouth_o := false
	if muon_node != null:
		var vel: Vector2 = muon_node.get("velocity") if muon_node.get("velocity") != null else Vector2.ZERO
		if vel.length() > 20.0:
			look = vel.normalized() * 3.0
		mouth_o = bool(muon_node.get("dashing"))
	# Blush.
	draw_circle(Vector2(-9.5, 3.0), 3.6, Color(Juice.BLUSH, 0.85))
	draw_circle(Vector2(9.5, 3.0), 3.6, Color(Juice.BLUSH, 0.85))
	# Eyes (blink by squashing vertically).
	for side in [-1.0, 1.0]:
		var eye_pos := Vector2(side * 5.5, -3.0) + look
		draw_set_transform(eye_pos, 0.0, Vector2(1.0, _blink))
		draw_circle(Vector2.ZERO, 2.7, Juice.INK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Mouth.
	if mouth_o:
		draw_circle(Vector2(0, 4.5) + look * 0.6, 2.4, Juice.INK)
	else:
		draw_arc(Vector2(0, 2.5) + look * 0.6, 4.5, 0.5, PI - 0.5, 10, Juice.INK, 1.8, true)
	# Charge badge.
	draw_circle(Vector2(0, 21.0), 6.0, Juice.MINT)
	draw_line(Vector2(-3.0, 21.0), Vector2(3.0, 21.0), Juice.INK, 2.0)
