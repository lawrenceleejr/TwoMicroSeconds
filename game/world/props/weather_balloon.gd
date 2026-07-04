extends "res://game/world/props/prop_base.gd"
## A drowsy weather balloon with an instrument box. Easily startled.

var _t := 0.0
var _startled := 0.0
var _jump := 0.0
var _sprite: Sprite2D
var _overlay: Node2D


func _setup() -> void:
	_t = randf() * 8.0
	# Art is balloon + string + box; the balloon center sits ~78 px into a
	# 240-tall document, so offset the sprite to hang below the node origin.
	_sprite = make_sprite("res://assets/sprites/balloon.svg", 0.55, Vector2(0, 8))
	_overlay = make_overlay(_draw_face)


func _process(delta: float) -> void:
	_t += delta
	_startled = maxf(_startled - delta, 0.0)
	var m := muon()
	if m != null and _startled <= 0.0 and muon_dist() < 60.0:
		if float(m.get("speed")) > 520.0:
			_startle()
	var sway := sin(_t * 0.9) * 6.0
	var wobble := _startled * sin(_t * 30.0) * 0.05
	_sprite.position = Vector2(sway, 8.0 + _jump)
	_sprite.rotation = wobble
	_overlay.position = Vector2(sway, -22.0 + _jump)
	_overlay.queue_redraw()


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


func _draw_face(c: Node2D) -> void:
	if _startled > 0.0:
		c.draw_circle(Vector2(-6, 0), 2.6, Juice.INK)
		c.draw_circle(Vector2(6, 0), 2.6, Juice.INK)
		c.draw_circle(Vector2(0, 8), 3.0, Juice.INK)
	else:
		c.draw_arc(Vector2(-6, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.5, true)
		c.draw_arc(Vector2(6, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.5, true)
