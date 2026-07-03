extends "res://game/world/props/prop_base.gd"
## A friendly commuter plane puttering across the troposphere.
## Zip straight through it (nobody notices; you are very small).

var _dir := 1.0
var _speed := 130.0
var _t := 0.0
var _flicker := 0.0
var _waggle := 0.0
var _thread_cd := 0.0


func _setup() -> void:
	_dir = 1.0 if randf() < 0.5 else -1.0
	_speed = randf_range(110.0, 160.0)
	_t = randf() * 5.0


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
	var m := muon()
	if m != null and _thread_cd <= 0.0 and m.get("dashing"):
		var d := m.global_position - global_position
		if absf(d.y) < 36.0 and absf(d.x) < 95.0:
			_thread_cd = 2.0
			_waggle = 1.0
			Sfx.play("boing", -6.0)
			Tasks.complete("thread_airplane")
			var tw := create_tween()
			tw.tween_property(self, "_waggle", 0.0, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_flicker = 1.2
	Sfx.play("tick", -8.0)


func _draw() -> void:
	var roll := _waggle * sin(_t * 18.0) * 0.12
	draw_set_transform(Vector2.ZERO, roll, Vector2(_dir, 1.0))
	# Fuselage.
	draw_rect(Rect2(-70, -14, 140, 28), Juice.CREAM)
	draw_circle(Vector2(70, 0), 14.0, Juice.CREAM)
	draw_circle(Vector2(-70, 0), 14.0, Juice.CREAM)
	# Tail fin and wing.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-78, -12), Vector2(-58, -12), Vector2(-64, -38), Vector2(-80, -38)
	]), Color("ff9aa8"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12, 4), Vector2(34, 4), Vector2(12, 30), Vector2(-22, 30)
	]), Color("ffd3da"))
	# Windows.
	var win_col := Juice.SUN if (_flicker > 0.0 and int(_t * 14.0) % 2 == 0) else Color("bfe3ff")
	for i in 5:
		draw_circle(Vector2(-44 + i * 22, -3), 5.0, win_col)
	# Nose smile.
	draw_arc(Vector2(72, 4), 5.0, 0.4, PI - 0.6, 8, Juice.INK, 1.6, true)
	draw_circle(Vector2(66, -4), 2.0, Juice.INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
