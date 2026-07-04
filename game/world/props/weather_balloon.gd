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
	shadow_size = 74.0
	shadow_drop = 86.0
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
	# Static discharge: a startled balloon lets a little charge go — and
	# man-made electronics always glitch you.
	var m := muon()
	if m != null and muon_dist() < 160.0:
		m.boost(30.0, "static")
		Juice.glitch(0.35, 0.7)
		Sfx.play("glitch", -6.0)
	var tw := create_tween()
	tw.tween_property(self, "_jump", -26.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_jump", 0.0, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw_face(c: Node2D) -> void:
	# Startled: the instrument box lights up and panics, telemetry-style.
	if _startled > 0.0 and int(_startled * 12.0) % 2 == 0:
		# (Box sits ~82 px below the overlay origin at sprite scale 0.55.)
		c.draw_circle(Vector2(4.4, 82.0), 3.2, Juice.SUN)
		c.draw_rect(Rect2(-8.0, 74.0, 8.0, 3.0), Juice.PINK)
