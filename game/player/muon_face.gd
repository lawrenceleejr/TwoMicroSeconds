extends Node2D
## The muon's face, such as it is: two minimal ink dashes that blink and
## lean into the direction of travel. No blush, no grin — the character
## lives in the motion, not the makeup.

var _blink := 1.0
var _blink_timer := 2.5


func _process(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = randf_range(2.6, 5.0)
		var tw := create_tween()
		tw.tween_property(self, "_blink", 0.08, 0.06)
		tw.tween_property(self, "_blink", 1.0, 0.09)
	queue_redraw()


func _draw() -> void:
	var muon_node := get_parent()
	var look := Vector2.ZERO
	var vel := Vector2.ZERO
	if muon_node != null:
		var v = muon_node.get("velocity")
		if v != null:
			vel = v
		if vel.length() > 20.0:
			look = vel.normalized() * 3.0
	# Eyes narrow slightly with speed — reads as focus, not glee.
	var narrow := 1.0 - 0.35 * clampf(vel.length() / 2600.0, 0.0, 1.0)
	for side: float in [-1.0, 1.0]:
		var eye_pos := Vector2(side * 6.0, -2.0) + look
		draw_set_transform(eye_pos, 0.0, Vector2(1.0, _blink * narrow))
		draw_rect(Rect2(-1.4, -3.2, 2.8, 6.4), Juice.INK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
