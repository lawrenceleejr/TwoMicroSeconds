extends "res://game/world/props/prop_base.gd"
## A sleepy tropospheric cloud. Zap it and its charge lets go: it blushes,
## rains, and the thunderstorm field gives you a push (thunderclouds really
## do accelerate charged particles).

const Lightning := preload("res://game/fx/lightning.gd")
const BOOST := 55.0

var _t := 0.0
var _blush := 0.0
var _boost_cd := 0.0
var _rain: CPUParticles2D
var _sprite: Sprite2D
var _overlay: Node2D


func _setup() -> void:
	_t = randf() * 6.0
	_sprite = make_sprite("res://assets/sprites/cloud.svg", 0.62)
	shadow_size = 140.0
	shadow_drop = 52.0
	_rain = CPUParticles2D.new()
	_rain.position = Vector2(0, 40)
	_rain.amount = 36
	_rain.lifetime = 1.5
	_rain.emitting = false
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(70, 4)
	_rain.direction = Vector2(0, 1)
	_rain.spread = 6.0
	_rain.gravity = Vector2(0, 460)
	_rain.initial_velocity_min = 70.0
	_rain.initial_velocity_max = 130.0
	_rain.scale_amount_min = 1.6
	_rain.scale_amount_max = 2.4
	_rain.color = Color(Juice.RAIN, 0.8)
	add_child(_rain)
	_overlay = make_overlay(_draw_face)


func _process(delta: float) -> void:
	_t += delta
	_blush = maxf(_blush - delta * 0.4, 0.0)
	_boost_cd = maxf(_boost_cd - delta, 0.0)
	position.x += sin(_t * 0.23) * 3.0 * delta
	_sprite.scale = Vector2.ONE * 0.62 * (1.0 + 0.02 * sin(_t * 1.4))
	_overlay.queue_redraw()


func zapped(source: Node2D) -> void:
	_blush = 2.0
	_rain.emitting = true
	Sfx.play("pop", -7.0)
	if not Tasks.is_done("make_rain"):
		Tasks.complete("make_rain")
	if _boost_cd <= 0.0 and source != null and source.is_in_group("muon"):
		_boost_cd = 3.0
		var bolt: Node2D = Lightning.new()
		bolt.from = global_position + Vector2(0, 20)
		bolt.to = source.global_position
		get_parent().add_child(bolt)
		source.boost(BOOST, "thunderstorm field")
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(_rain):
			_rain.emitting = false
	)


func _draw_face(c: Node2D) -> void:
	if _blush > 0.0:
		var a := clampf(_blush, 0.0, 1.0)
		c.draw_circle(Vector2(-16, 2), 4.5, Color(Juice.BLUSH, a))
		c.draw_circle(Vector2(16, 2), 4.5, Color(Juice.BLUSH, a))
		c.draw_circle(Vector2(-7, -5), 2.6, Juice.INK)
		c.draw_circle(Vector2(7, -5), 2.6, Juice.INK)
		c.draw_circle(Vector2(0, 3), 2.8, Juice.INK)
	else:
		c.draw_arc(Vector2(-7, -4), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.65), 1.6, true)
		c.draw_arc(Vector2(7, -4), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.65), 1.6, true)
