extends "res://game/world/props/prop_base.gd"
## A sleepy tropospheric cloud. Zap it and it blushes and rains.

var _t := 0.0
var _blush := 0.0
var _rain: CPUParticles2D


func _setup() -> void:
	_t = randf() * 6.0
	_rain = CPUParticles2D.new()
	_rain.position = Vector2(0, 26)
	_rain.amount = 36
	_rain.lifetime = 1.5
	_rain.emitting = false
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(55, 4)
	_rain.direction = Vector2(0, 1)
	_rain.spread = 6.0
	_rain.gravity = Vector2(0, 460)
	_rain.initial_velocity_min = 70.0
	_rain.initial_velocity_max = 130.0
	_rain.scale_amount_min = 1.6
	_rain.scale_amount_max = 2.4
	_rain.color = Color(Juice.RAIN, 0.8)
	add_child(_rain)


func _process(delta: float) -> void:
	_t += delta
	_blush = maxf(_blush - delta * 0.4, 0.0)
	position.x += sin(_t * 0.23) * 3.0 * delta
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_blush = 2.0
	_rain.emitting = true
	Sfx.play("pop", -7.0)
	if not Tasks.is_done("make_rain"):
		Tasks.complete("make_rain")
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(_rain):
			_rain.emitting = false
	)


func _draw() -> void:
	var puff := 1.0 + 0.03 * sin(_t * 1.4)
	for blob in [[Vector2(-38, 8), 26.0], [Vector2(0, -8), 36.0], [Vector2(38, 8), 24.0], [Vector2(0, 14), 30.0]]:
		var center: Vector2 = blob[0]
		var r: float = blob[1]
		draw_circle(center, r * puff, Color(1.0, 1.0, 1.0, 0.96))
	if _blush > 0.0:
		var a := clampf(_blush, 0.0, 1.0)
		draw_circle(Vector2(-16, 0), 4.5, Color(Juice.BLUSH, a))
		draw_circle(Vector2(16, 0), 4.5, Color(Juice.BLUSH, a))
		draw_circle(Vector2(-7, -6), 2.6, Juice.INK)
		draw_circle(Vector2(7, -6), 2.6, Juice.INK)
		draw_circle(Vector2(0, 2), 2.8, Juice.INK)
	else:
		draw_arc(Vector2(-7, -5), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.65), 1.6, true)
		draw_arc(Vector2(7, -5), 3.2, PI + 0.4, TAU - 0.4, 8, Color(Juice.INK, 0.65), 1.6, true)
