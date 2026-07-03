extends Node2D
## The muon. Speed is survival: moving fast raises a cartoon Lorentz factor,
## and proper time (2.2 µs) drains at delta / gamma. The juice IS the mechanic.

signal decayed
signal circle_drawn

const MAX_SPEED := 420.0
const STEER_RATE := 9.0
const DRIFT := 42.0
const DASH_SPEED := 1150.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.5
const DASH_BUFFER := 0.12
const GAMMA_K := 9.0
const LIFETIME := 2.2
const REAL_SECONDS_PER_US := 10.0
const ZAP_RADIUS := 175.0
const ZAP_COOLDOWN := 0.35

const GhostFx := preload("res://game/fx/ghost.gd")
const ZapRingFx := preload("res://game/fx/zap_ring.gd")

var velocity := Vector2.ZERO
var alive := true
var finished := false
var proper_time := LIFETIME
var gamma := 1.0
var dashing := false
var speed_frac := 0.0

var _dash_left := 0.0
var _dash_cd := 0.0
var _dash_buffer := 0.0
var _zap_cd := 0.0
var _dash_dir := Vector2.DOWN
var _ghost_timer := 0.0
var _dash_times: Array[float] = []
var _clock := 0.0
var _turn_acc := 0.0
var _prev_dir := 0.0
var _last_tick_bucket := -1

# Untyped: these carry script-defined members the analyzer can't see on Node2D.
var _body
var _face
var _trail: Line2D
var _sparkles: CPUParticles2D
var _camera: Camera2D


func _ready() -> void:
	add_to_group("muon")
	z_index = 5
	_build_visuals()
	_build_camera()


func _build_visuals() -> void:
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.z_as_relative = false
	_trail.z_index = 4
	_trail.width = 14.0
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.05))
	curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 0.97, 0.0))
	grad.set_color(1, Color(1.0, 1.0, 0.97, 0.55))
	_trail.gradient = grad
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_trail)

	_sparkles = CPUParticles2D.new()
	_sparkles.amount = 24
	_sparkles.lifetime = 0.7
	_sparkles.spread = 180.0
	_sparkles.gravity = Vector2.ZERO
	_sparkles.initial_velocity_min = 8.0
	_sparkles.initial_velocity_max = 34.0
	_sparkles.scale_amount_min = 1.2
	_sparkles.scale_amount_max = 2.6
	_sparkles.color = Color(1.0, 1.0, 0.95, 0.5)
	add_child(_sparkles)

	_body = preload("res://game/player/muon_body.gd").new()
	add_child(_body)
	_face = preload("res://game/player/muon_face.gd").new()
	add_child(_face)


func _build_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 6.0
	_camera.limit_left = int(-Atmos.X_LIMIT - 250.0)
	_camera.limit_right = int(Atmos.X_LIMIT + 250.0)
	_camera.limit_top = -700
	_camera.limit_bottom = int(Atmos.GROUND_Y + 500.0)
	add_child(_camera)
	_camera.make_current()
	Juice.register_camera(_camera)


func _process(delta: float) -> void:
	_clock += delta
	if not alive or finished:
		_update_trail()
		return

	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Dash timers and input buffering (the top-down cousin of coyote time).
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_zap_cd = maxf(_zap_cd - delta, 0.0)
	_dash_buffer = maxf(_dash_buffer - delta, 0.0)
	if Input.is_action_just_pressed("dash"):
		_dash_buffer = DASH_BUFFER
	if _dash_buffer > 0.0 and _dash_cd <= 0.0 and not dashing:
		_start_dash(input_vec)

	if dashing:
		_dash_left -= delta
		velocity = _dash_dir * DASH_SPEED
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_spawn_ghost()
			_ghost_timer = 0.03
		if _dash_left <= 0.0:
			_end_dash()
	else:
		var target := input_vec * MAX_SPEED + Vector2(0.0, DRIFT)
		velocity = velocity.lerp(target, 1.0 - exp(-STEER_RATE * delta))

	position += velocity * delta
	_apply_bounds()

	# Time dilation: the whole game in three lines.
	var frac := clampf(velocity.length() / MAX_SPEED, 0.0, 1.5)
	gamma = 1.0 + GAMMA_K * frac * frac
	proper_time -= delta / (gamma * REAL_SECONDS_PER_US)

	speed_frac = clampf(velocity.length() / MAX_SPEED, 0.0, 1.0)
	_sparkles.modulate.a = speed_frac * 0.9

	if Input.is_action_just_pressed("zap") and _zap_cd <= 0.0:
		_zap()

	_track_circle(delta)
	_update_trail()
	_update_squash()
	_update_camera_lookahead(delta)
	_heartbeat()

	if proper_time <= 0.0:
		proper_time = 0.0
		_die()


func _start_dash(input_vec: Vector2) -> void:
	dashing = true
	_dash_buffer = 0.0
	_dash_left = DASH_TIME
	_dash_cd = DASH_COOLDOWN
	if input_vec.length() > 0.2:
		_dash_dir = input_vec.normalized()
	elif velocity.length() > 30.0:
		_dash_dir = velocity.normalized()
	else:
		_dash_dir = Vector2.DOWN
	Sfx.play("dash", -4.0)
	Juice.shake(0.10)
	_pop_scale(Vector2(1.45, 0.62))
	# Track "outrun your own light".
	_dash_times.append(_clock)
	while _dash_times.size() > 0 and _dash_times[0] < _clock - 5.0:
		_dash_times.remove_at(0)
	if _dash_times.size() >= 3:
		Tasks.complete("triple_dash")


func _end_dash() -> void:
	dashing = false
	velocity = _dash_dir * MAX_SPEED * 0.9
	_pop_scale(Vector2(0.75, 1.3))


func _zap() -> void:
	_zap_cd = ZAP_COOLDOWN
	var ring: Node2D = ZapRingFx.new()
	ring.position = global_position
	get_parent().add_child(ring)
	Sfx.play("zap", -3.0)
	Juice.shake(0.16)
	Juice.hitstop(0.045, 0.1)
	_pop_scale(Vector2(1.3, 1.3))
	for node in get_tree().get_nodes_in_group("zappable"):
		if node is Node2D and node.global_position.distance_to(global_position) < ZAP_RADIUS:
			node.zapped(self)


func _pop_scale(to_scale: Vector2) -> void:
	_body.scale = to_scale
	var tw := create_tween()
	tw.tween_property(_body, "scale", Vector2.ONE, 0.32) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_ghost() -> void:
	var g: Node2D = GhostFx.new()
	g.position = global_position
	get_parent().add_child(g)


func _apply_bounds() -> void:
	if position.x > Atmos.X_LIMIT:
		position.x = Atmos.X_LIMIT
		if velocity.x > 0.0:
			velocity.x *= -0.4
			_pop_scale(Vector2(0.7, 1.25))
	elif position.x < -Atmos.X_LIMIT:
		position.x = -Atmos.X_LIMIT
		if velocity.x < 0.0:
			velocity.x *= -0.4
			_pop_scale(Vector2(0.7, 1.25))
	position.y = maxf(position.y, -350.0)


func _track_circle(delta: float) -> void:
	if velocity.length() > 180.0 and not dashing:
		var dir := velocity.angle()
		var dd := wrapf(dir - _prev_dir, -PI, PI)
		_prev_dir = dir
		if absf(dd) < 0.5:
			_turn_acc = clampf(_turn_acc + dd, -TAU * 1.5, TAU * 1.5)
	_turn_acc = move_toward(_turn_acc, 0.0, delta * 0.9)
	if absf(_turn_acc) > TAU * 0.92:
		_turn_acc = 0.0
		circle_drawn.emit()


func _update_trail() -> void:
	_trail.add_point(global_position)
	while _trail.get_point_count() > 26:
		_trail.remove_point(0)


func _update_squash() -> void:
	var stretch := speed_frac * (1.6 if dashing else 1.0)
	_body.rotation = velocity.angle()
	# Velocity squash goes into the draw transform; tween pops own node scale.
	_body.applied_squash = Vector2(1.0 + 0.22 * stretch, 1.0 - 0.16 * stretch)


func _update_camera_lookahead(delta: float) -> void:
	var target := velocity * 0.22
	_camera.position = _camera.position.lerp(target, 1.0 - exp(-3.0 * delta))


func _heartbeat() -> void:
	if proper_time < 0.45:
		var bucket := int(proper_time / 0.12)
		if bucket != _last_tick_bucket:
			_last_tick_bucket = bucket
			Sfx.play("tick", -6.0)


func refund_time(amount: float) -> void:
	proper_time = minf(proper_time + amount, LIFETIME)


func _die() -> void:
	if not alive:
		return
	alive = false
	_body.visible = false
	_face.visible = false
	_sparkles.emitting = false
	var tw := create_tween()
	tw.tween_property(_trail, "modulate:a", 0.0, 0.8)
	decayed.emit()


## Called by main when the detector catches us: glide onto the pad and beam.
func absorb(target: Vector2) -> void:
	finished = true
	velocity = Vector2.ZERO
	_sparkles.emitting = false
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_body, "scale", Vector2(1.2, 0.8), 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_body.rotation = 0.0
