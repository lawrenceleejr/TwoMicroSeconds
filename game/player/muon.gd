extends Node2D
## The muon. You cannot throttle a muon — nothing accelerates a charged
## particle but an electric field. You steer; the atmosphere slowly bleeds
## your energy away (ionization drag); auroral electrojets, thundercloud
## fields, and rebooted satellites give it back. Speed is your clock:
## proper time drains at delta / gamma.

signal decayed
signal circle_drawn
signal boosted(amount: float, source: String)

const BASE_BIRTH_SPEED := 430.0
const TIER_SPEED := 26.0
const SPEED_FLOOR := 230.0
const SPEED_CAP := 1250.0
const REF_SPEED := 470.0
const TURN_RATE_SLOW := 4.2
const TURN_RATE_FAST := 2.4
const DOWN_BIAS := 0.5
const GAMMA_K := 9.0
const LIFETIME := 2.2
const REAL_SECONDS_PER_US := 10.0
const ZAP_RADIUS := 175.0
const ZAP_COOLDOWN := 0.35
# Ionization drag per layer (px/s^2): thin air up high, soup down low.
const DRAG := [9.0, 12.0, 16.0, 24.0, 24.0]

const GhostFx := preload("res://game/fx/ghost.gd")
const ZapRingFx := preload("res://game/fx/zap_ring.gd")
const SpeedLines := preload("res://game/fx/speed_lines.gd")
const FloatText := preload("res://game/fx/float_text.gd")

var velocity := Vector2.ZERO
var speed := 0.0
var heading := Vector2.DOWN
var birth_speed := 0.0
var alive := true
var finished := false
var proper_time := LIFETIME
var gamma := 1.0
var speed_frac := 0.0
## Scripted steering for the screenshot/demo director; zero = player input.
var autopilot := Vector2.ZERO

var _zap_cd := 0.0
var _ghost_timer := 0.0
var _clock := 0.0
var _turn_acc := 0.0
var _prev_dir := 0.0
var _last_tick_bucket := -1
var _speed_fx := 0.0

# Untyped: these carry script-defined members the analyzer can't see on Node2D.
var _body
var _face
var _speed_lines
var _trail: Line2D
var _trail_halo: Line2D
var _sparkles: CPUParticles2D
var _wind: CPUParticles2D
var _camera: Camera2D


func _ready() -> void:
	add_to_group("muon")
	z_index = 5
	birth_speed = BASE_BIRTH_SPEED + Meta.tier * TIER_SPEED
	speed = birth_speed
	_build_visuals()
	_build_camera()


func _build_visuals() -> void:
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_trail_halo = _make_trail(30.0, Color(1.0, 1.0, 0.97, 0.16), add_mat)
	_trail = _make_trail(15.0, Color(1.0, 1.0, 0.97, 0.6), add_mat)

	_sparkles = CPUParticles2D.new()
	_sparkles.texture = load("res://assets/sprites/sparkle.svg")
	_sparkles.amount = 30
	_sparkles.lifetime = 0.85
	_sparkles.local_coords = false
	_sparkles.spread = 180.0
	_sparkles.gravity = Vector2.ZERO
	_sparkles.initial_velocity_min = 6.0
	_sparkles.initial_velocity_max = 40.0
	_sparkles.angular_velocity_min = -180.0
	_sparkles.angular_velocity_max = 180.0
	_sparkles.scale_amount_min = 0.14
	_sparkles.scale_amount_max = 0.34
	var twinkle := Curve.new()
	twinkle.add_point(Vector2(0.0, 0.0))
	twinkle.add_point(Vector2(0.25, 1.0))
	twinkle.add_point(Vector2(1.0, 0.0))
	_sparkles.scale_amount_curve = twinkle
	_sparkles.material = add_mat
	add_child(_sparkles)

	_body = preload("res://game/player/muon_body.gd").new()
	add_child(_body)
	_face = preload("res://game/player/muon_face.gd").new()
	add_child(_face)

	# Higher-energy origins glow warmer; the Oh-My-God muon is golden.
	var tier_f := float(Meta.tier) / float(Meta.TIERS.size() - 1)
	_body.body_color = Color.WHITE.lerp(Color("ffdf9e"), tier_f * 0.8)
	if Meta.is_max_tier():
		_trail.gradient.set_color(1, Color(1.0, 0.88, 0.5, 0.7))
		_sparkles.modulate = Color(Juice.SUN, 1.0)


func _make_trail(width: float, tip_color: Color, mat: CanvasItemMaterial) -> Line2D:
	var line := Line2D.new()
	line.top_level = true
	line.z_as_relative = false
	line.z_index = 4
	line.width = width
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.05))
	curve.add_point(Vector2(1.0, 1.0))
	line.width_curve = curve
	var grad := Gradient.new()
	grad.set_color(0, Color(tip_color, 0.0))
	grad.set_color(1, tip_color)
	line.gradient = grad
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.material = mat
	add_child(line)
	return line


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

	_speed_lines = SpeedLines.new()
	_camera.add_child(_speed_lines)

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_wind = CPUParticles2D.new()
	_wind.texture = load("res://assets/sprites/streak.svg")
	_wind.amount = 26
	_wind.lifetime = 0.5
	_wind.emitting = false
	_wind.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_wind.emission_rect_extents = Vector2(760, 440)
	_wind.spread = 6.0
	_wind.gravity = Vector2.ZERO
	_wind.initial_velocity_min = 520.0
	_wind.initial_velocity_max = 820.0
	_wind.scale_amount_min = 0.7
	_wind.scale_amount_max = 1.6
	_wind.particle_flag_align_y = true
	_wind.modulate = Color(1, 1, 1, 0.5)
	_wind.material = add_mat
	_camera.add_child(_wind)


func _process(delta: float) -> void:
	_clock += delta
	if not alive or finished:
		_update_trail()
		Juice.set_relativity(Vector2.DOWN, 0.0)
		return

	_zap_cd = maxf(_zap_cd - delta, 0.0)

	# Steering only: rotate the heading toward the input direction.
	var steer := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if autopilot != Vector2.ZERO:
		steer = autopilot
	speed_frac = clampf(speed / REF_SPEED, 0.0, 1.5)
	var turn_rate := lerpf(TURN_RATE_SLOW, TURN_RATE_FAST, clampf(speed / SPEED_CAP, 0.0, 1.0))
	if steer.length() > 0.2:
		var ang := heading.angle_to(steer.normalized())
		heading = heading.rotated(clampf(ang, -turn_rate * delta, turn_rate * delta))
	else:
		var ang_down := heading.angle_to(Vector2.DOWN)
		heading = heading.rotated(clampf(ang_down, -DOWN_BIAS * delta, DOWN_BIAS * delta))

	# Ionization drag: the atmosphere is always taxing you.
	var layer := Atmos.layer_index_at(global_position.y)
	speed = maxf(speed - DRAG[layer] * delta, SPEED_FLOOR)
	velocity = heading * speed
	position += velocity * delta
	_apply_bounds()

	# Time dilation: the whole game in three lines. A hotter origin story
	# (Meta tier) means more energy at birth, so a permanently higher gamma.
	gamma = 1.0 + GAMMA_K * speed_frac * speed_frac + Meta.gamma_bonus()
	proper_time -= delta / (gamma * REAL_SECONDS_PER_US)

	if speed > birth_speed * 1.15:
		Tasks.complete("overclock")

	if Input.is_action_just_pressed("zap") and _zap_cd <= 0.0:
		_zap()

	_track_circle(delta)
	_update_trail()
	_update_squash()
	_update_speed_fx(delta)
	_update_camera_lookahead(delta)
	_heartbeat()

	if proper_time <= 0.0:
		proper_time = 0.0
		_die()


## The only way to gain speed: an electric field did work on you.
func boost(amount: float, source: String) -> void:
	if not alive or finished:
		return
	speed = minf(speed + amount, SPEED_CAP)
	boosted.emit(amount, source)
	Sfx.play("dash", -3.0)
	Juice.shake(0.14)
	_pop_scale(Vector2(1.45, 0.62))
	for i in 3:
		get_tree().create_timer(0.05 * i).timeout.connect(_spawn_ghost)
	FloatText.spawn(get_parent(), global_position + Vector2(0, -46),
		"+E field · %s" % source, Juice.SUN)


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
	if not is_inside_tree():
		return
	var g: Node2D = GhostFx.new()
	g.position = global_position
	get_parent().add_child(g)


func _apply_bounds() -> void:
	if position.x > Atmos.X_LIMIT:
		position.x = Atmos.X_LIMIT
		if heading.x > 0.0:
			heading.x = -heading.x
			_pop_scale(Vector2(0.7, 1.25))
	elif position.x < -Atmos.X_LIMIT:
		position.x = -Atmos.X_LIMIT
		if heading.x < 0.0:
			heading.x = -heading.x
			_pop_scale(Vector2(0.7, 1.25))
	position.y = maxf(position.y, -350.0)


func _track_circle(delta: float) -> void:
	if speed > 180.0:
		var dir := heading.angle()
		var dd := wrapf(dir - _prev_dir, -PI, PI)
		_prev_dir = dir
		if absf(dd) < 0.5:
			_turn_acc = clampf(_turn_acc + dd, -TAU * 1.5, TAU * 1.5)
	_turn_acc = move_toward(_turn_acc, 0.0, delta * 0.9)
	if absf(_turn_acc) > TAU * 0.92:
		_turn_acc = 0.0
		circle_drawn.emit()


func _update_trail() -> void:
	# A teleport (director, restart) would otherwise smear a bogus streak.
	if _trail.get_point_count() > 0:
		var last := _trail.get_point_position(_trail.get_point_count() - 1)
		if last.distance_to(global_position) > 260.0:
			_trail.clear_points()
	_trail.add_point(global_position)
	while _trail.get_point_count() > 34:
		_trail.remove_point(0)
	_trail_halo.points = _trail.points


func _update_squash() -> void:
	var stretch := clampf(speed / SPEED_CAP, 0.0, 1.0)
	_body.rotation = heading.angle()
	_body.applied_squash = Vector2(1.0 + 0.26 * stretch, 1.0 - 0.18 * stretch)


func _update_speed_fx(delta: float) -> void:
	var target := clampf((speed - 420.0) / 500.0, 0.0, 1.0)
	_speed_fx = lerpf(_speed_fx, target, 1.0 - exp(-6.0 * delta))
	_speed_lines.intensity = _speed_fx
	_speed_lines.dir = heading
	_wind.emitting = _speed_fx > 0.45
	_wind.direction = -heading
	_sparkles.modulate.a = clampf(0.35 + speed / SPEED_CAP, 0.0, 1.0)
	var zoom := lerpf(1.0, 0.84, _speed_fx)
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * zoom, 1.0 - exp(-4.0 * delta))
	Juice.set_relativity(heading, clampf((speed - 330.0) / 750.0, 0.0, 1.0))
	_ghost_timer -= delta
	if speed > 880.0 and _ghost_timer <= 0.0:
		_spawn_ghost()
		_ghost_timer = 0.04


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
	_wind.emitting = false
	_speed_lines.intensity = 0.0
	var tw := create_tween()
	tw.tween_property(_trail, "modulate:a", 0.0, 0.8)
	tw.parallel().tween_property(_trail_halo, "modulate:a", 0.0, 0.8)
	decayed.emit()


## Called by main when the detector catches us: glide onto the pad and beam.
func absorb(target: Vector2) -> void:
	finished = true
	velocity = Vector2.ZERO
	speed = 0.0
	_sparkles.emitting = false
	_wind.emitting = false
	_speed_lines.intensity = 0.0
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, 0.55) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_body, "scale", Vector2(1.2, 0.8), 0.55) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_body.rotation = 0.0
