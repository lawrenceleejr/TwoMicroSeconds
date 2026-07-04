extends "res://game/world/props/prop_base.gd"
## A friendly commuter plane puttering across the troposphere.
## Fly straight through it (nobody notices; you are very small).

var _dir := 1.0
var _speed := 130.0
var _t := 0.0
var _flicker := 0.0
var _waggle := 0.0
var _thread_cd := 0.0
var _sprite: Sprite2D
var _overlay: Node2D


func _setup() -> void:
	_dir = 1.0 if randf() < 0.5 else -1.0
	_speed = randf_range(110.0, 160.0)
	_t = randf() * 5.0
	# Art faces right (nose at +x); flipping the node handles direction.
	_sprite = make_sprite("res://assets/sprites/airplane.svg", 0.52, Vector2(0, 0))
	_overlay = make_overlay(_draw_extras)


func _process(delta: float) -> void:
	_t += delta
	_flicker = maxf(_flicker - delta, 0.0)
	_thread_cd = maxf(_thread_cd - delta, 0.0)
	position.x += _dir * _speed * delta
	position.y += sin(_t * 1.2) * 6.0 * delta
	if position.x > Atmos.X_LIMIT + 500.0:
		_dir = -1.0
	elif position.x < -Atmos.X_LIMIT - 500.0:
		_dir = 1.0
	scale.x = _dir
	rotation = _waggle * sin(_t * 18.0) * 0.12
	var m := muon()
	if m != null and _thread_cd <= 0.0 and m.get("alive"):
		var d := m.global_position - global_position
		if absf(d.y) < 34.0 and absf(d.x) < 95.0:
			_thread_cd = 3.0
			_waggle = 1.0
			Sfx.play("boing", -6.0)
			Tasks.complete("thread_airplane")
			var tw := create_tween()
			tw.tween_property(self, "_waggle", 0.0, 1.2) \
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_overlay.queue_redraw()


func zapped(_source: Node2D) -> void:
	_flicker = 1.2
	Sfx.play("tick", -8.0)


func _draw_extras(c: Node2D) -> void:
	# Cabin lights flicker when zapped (window positions match the art:
	# 380x150 doc, windows at x=110..260 step 30, y=72, scale 0.52).
	if _flicker > 0.0 and int(_t * 14.0) % 2 == 0:
		for i in 6:
			var wx := (110.0 + i * 30.0 - 190.0) * 0.52
			c.draw_circle(Vector2(wx, (72.0 - 75.0) * 0.52), 4.2, Color(Juice.SUN, 0.9))
	# A tiny smile on the nose.
	c.draw_arc(Vector2(78.0, 4.0), 4.5, 0.4, PI - 0.6, 8, Juice.INK, 1.6, true)
	c.draw_circle(Vector2(72.0, -4.0), 1.9, Juice.INK)
