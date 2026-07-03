extends "res://game/world/props/prop_base.gd"
## A drowsy weather balloon with an instrument box. Easily startled.

var _t := 0.0
var _startled := 0.0
var _jump := 0.0


func _setup() -> void:
	_t = randf() * 8.0


func _process(delta: float) -> void:
	_t += delta
	_startled = maxf(_startled - delta, 0.0)
	var m := muon()
	if m != null and _startled <= 0.0 and muon_dist() < 60.0:
		var vel: Vector2 = m.get("velocity")
		if vel.length() > 480.0:
			_startle()
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_startle()


func _startle() -> void:
	if _startled > 0.0:
		return
	_startled = 2.5
	Sfx.play("boing", -4.0)
	if not Tasks.is_done("startle_balloon"):
		Tasks.complete("startle_balloon")
	var tw := create_tween()
	tw.tween_property(self, "_jump", -26.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_jump", 0.0, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var sway := sin(_t * 0.9) * 6.0
	var balloon := Vector2(sway, -30.0 + _jump)
	var wobble := _startled * sin(_t * 30.0) * 3.0
	# String and instrument box.
	draw_line(balloon + Vector2(0, 24), Vector2(sway * 0.5, 34.0), Color(Juice.INK, 0.6), 1.5, true)
	draw_rect(Rect2(sway * 0.5 - 9.0 + wobble * 0.4, 34.0, 18.0, 14.0), Juice.CREAM)
	draw_rect(Rect2(sway * 0.5 - 9.0 + wobble * 0.4, 34.0, 18.0, 14.0), Color(Juice.INK, 0.5), false, 1.5)
	# Balloon.
	draw_set_transform(balloon, wobble * 0.02, Vector2(1.0, 1.1))
	draw_circle(Vector2.ZERO, 24.0, Color("ff9aa8"))
	draw_circle(Vector2(-7, -8), 7.0, Color(1, 1, 1, 0.35))
	# Face.
	if _startled > 0.0:
		draw_circle(Vector2(-6, 0), 2.6, Juice.INK)
		draw_circle(Vector2(6, 0), 2.6, Juice.INK)
		draw_circle(Vector2(0, 8), 3.0, Juice.INK)
	else:
		draw_arc(Vector2(-6, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.5, true)
		draw_arc(Vector2(6, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.5, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
