extends "res://game/world/props/prop_base.gd"
## A silvery night-shining cloud, fast asleep until zapped.

var _t := 0.0
var _awake := 0.0
var _sprite: Sprite2D
var _overlay: Node2D


func _setup() -> void:
	_t = randf() * 6.0
	_sprite = make_sprite("res://assets/sprites/noctilucent.svg", 0.6)
	_overlay = make_overlay(_draw_face)


func _process(delta: float) -> void:
	_t += delta
	_awake = maxf(_awake - delta * 0.5, 0.0)
	var shimmer := 0.75 + 0.15 * sin(_t * 1.1) + _awake * 0.25
	_sprite.self_modulate = Color(1, 1, 1, clampf(shimmer, 0.4, 1.0))
	_overlay.queue_redraw()


func zapped(_source: Node2D) -> void:
	_awake = 2.0
	Sfx.play("pop", -6.0)
	if not Tasks.is_done("zap_noctilucent"):
		Tasks.complete("zap_noctilucent")


func _draw_face(c: Node2D) -> void:
	if _awake > 0.0:
		c.draw_circle(Vector2(-8, -6), 2.4, Juice.INK)
		c.draw_circle(Vector2(8, -6), 2.4, Juice.INK)
		c.draw_circle(Vector2(0, 2), 2.6, Juice.INK)
	else:
		c.draw_arc(Vector2(-8, -5), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.7), 1.5, true)
		c.draw_arc(Vector2(8, -5), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.7), 1.5, true)
