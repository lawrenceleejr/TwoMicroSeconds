extends "res://game/world/props/prop_base.gd"
## A silvery night-shining cloud, fast asleep until zapped.

var _t := 0.0
var _awake := 0.0


func _setup() -> void:
	_t = randf() * 6.0


func _process(delta: float) -> void:
	_t += delta
	_awake = maxf(_awake - delta * 0.5, 0.0)
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_awake = 2.0
	Sfx.play("pop", -6.0)
	if not Tasks.is_done("zap_noctilucent"):
		Tasks.complete("zap_noctilucent")


func _draw() -> void:
	var shimmer := 0.3 + 0.1 * sin(_t * 1.1) + _awake * 0.25
	var col := Color(0.82, 0.89, 1.0, clampf(shimmer, 0.1, 0.8))
	for blob in [[Vector2(-40, 6), 30.0], [Vector2(0, -6), 40.0], [Vector2(44, 8), 26.0]]:
		var center: Vector2 = blob[0]
		var r: float = blob[1]
		draw_set_transform(center, 0.0, Vector2(1.5, 0.7))
		draw_circle(Vector2.ZERO, r, col)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Face: asleep normally, surprised when zapped.
	if _awake > 0.0:
		draw_circle(Vector2(-8, -4), 2.4, Juice.INK)
		draw_circle(Vector2(8, -4), 2.4, Juice.INK)
		draw_circle(Vector2(0, 4), 2.6, Juice.INK)
	else:
		draw_arc(Vector2(-8, -3), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.7), 1.5, true)
		draw_arc(Vector2(8, -3), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.7), 1.5, true)
