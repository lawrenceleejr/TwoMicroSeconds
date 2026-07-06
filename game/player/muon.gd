extends Node2D
## The muon. You cannot throttle a muon — nothing accelerates a charged
## particle but an electric field. You steer; you coast without losing
## speed; auroral electrojets, thunderclouds, and rebooted
## satellites are the only way to gain it. Speed is your clock.

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
const GAMMA_K := 2.2
const LIFETIME := 2.2                # mean proper lifetime, µs
const REAL_SECONDS_PER_US := 12.0    # game seconds per proper µs
# We play in the muon's rest frame: energy never buys proper time — it
# length-contracts the atmosphere, so ground-distance is covered gamma
# times faster. This is the entire progression mechanic.
const CONTRACT := 0.5
const ZAP_RADIUS := 175.0
const ZAP_COOLDOWN := 0.35
# The muon is pinned to this fraction of the screen height (top third), so
# you always see what's rushing up from below. It's enforced by a feedback
# controller (see _process) reading the muon's real post-projection screen
# position, so fov breathing, the stage dolly, speed and orientation can't
# drift it off the line. FRAME_AIM_DOWN is just the starting guess.
const FRAME_FRACTION := 1.0 / 3.0
const FRAME_AIM_DOWN := 260.0   # constant feed-forward; the controller trims
var _aim_correction := 0.0
var _last_gy := 0.0
var _frame_settle := 0.0
var _lamp: Node2D
# No coasting drag: a minimum-ionizing particle barely notices the air,
# and a drifting muon keeps its momentum. The early game stays unwinnable
# anyway — a fresh solar-flare muon's clock runs out long before the
# ground unless field events keep raising gamma.

const GhostFx := preload("res://game/fx/ghost.gd")
const ZapRingFx := preload("res://game/fx/zap_ring.gd")
const SpeedLines := preload("res://game/fx/speed_lines.gd")
const FloatText := preload("res://game/fx/float_text.gd")
const BremBurst := preload("res://game/fx/brem_burst.gd")
## Above this gamma, radiative losses kick in: forward bremsstrahlung
## sparks and continuous mini-showers ahead of you.
const BREM_GAMMA := 9.0

var velocity := Vector2.ZERO
var speed := 0.0
var heading := Vector2.DOWN
var birth_speed := 0.0
var alive := true
var finished := false
## Proper time lived so far (µs). Counts UP; there is no fixed budget —
## decay is a memoryless roll against the dilated hazard rate, like the
## real particle.
var age_us := 0.0
## Lab-frame time lived so far (µs): Earth's clocks run gamma times fast.
var lab_us := 0.0
## Cumulative probability of having decayed by now: 1 - exp(-τ/2.2).
var decay_p := 0.0
var gamma := 1.0
## Scripted birth sequence owns the muon while true.
var intro_mode := false

var _hazard_integral := 0.0
var speed_frac := 0.0
## Scripted steering for the screenshot/demo director; zero = player input.
var autopilot := Vector2.ZERO

var _zap_cd := 0.0
var _autozap_cd := 0.0
var _ghost_timer := 0.0
var _brem_timer := 0.0
var _cam_lead := 0.0
var _depth_f := 0.0
var _shower_timer := 0.0
var _turn_pop_cd := 0.0
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

	# Headlamp: a forward cone of yellow light, lit only once you're grinding
	# through rock. Sits behind the body, additively blended over the dark.
	_lamp = Node2D.new()
	_lamp.z_index = 3
	_lamp.z_as_relative = false
	_lamp.material = add_mat
	_lamp.draw.connect(_draw_lamp)
	add_child(_lamp)

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
	# Top reaches into space so the discovery finale can pan back up;
	# bottom reaches the LZ cavern, 1.5 km down.
	_camera.limit_top = -7200
	_camera.limit_bottom = int(Atmos.LZ_Y + 900.0)
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
	if intro_mode:
		return
	if not alive or finished:
		_update_trail()
		Juice.set_relativity(Vector2.DOWN, 0.0, 0.0)
		return

	_zap_cd = maxf(_zap_cd - delta, 0.0)

	# LEFT/RIGHT steering only — you can never aim up. Input just angles
	# the ever-downward fall to the side; released, it settles to straight
	# down. (The screenshot director may still fly free via autopilot.)
	var target_dir := Vector2.DOWN
	if autopilot != Vector2.ZERO:
		target_dir = autopilot.normalized()
	else:
		var steer_x := Input.get_axis("move_left", "move_right")
		if Game.touch_steer_x != 0.0:
			steer_x = Game.touch_steer_x
		# Full steer angles the descent ~66° off vertical, never upward.
		target_dir = Vector2(steer_x * 2.2, 1.0).normalized()
	speed_frac = clampf(speed / REF_SPEED, 0.0, 1.5)
	var turn_rate := lerpf(TURN_RATE_SLOW, TURN_RATE_FAST, clampf(speed / SPEED_CAP, 0.0, 1.0))
	_turn_pop_cd = maxf(_turn_pop_cd - delta, 0.0)
	var ang := heading.angle_to(target_dir)
	var applied := clampf(ang, -turn_rate * delta, turn_rate * delta)
	heading = heading.rotated(applied)
	# A hard bank gets a little anticipation squash — goose rules.
	if absf(applied) > 3.4 * delta and absf(ang) > 1.1 and _turn_pop_cd <= 0.0:
		_turn_pop_cd = 0.45
		_pop_scale(Vector2(0.82, 1.2))

	# On touch there's no zap button, so auto-zap nearby reactables.
	if Game.is_touch():
		_autozap_cd = maxf(_autozap_cd - delta, 0.0)
		if _autozap_cd <= 0.0 and _zappable_near():
			_autozap_cd = 0.85
			_zap()

	# No drag while coasting: a drifting particle keeps its momentum.
	# Speed only ever changes through field events (boosts).

	# This is the muon's rest frame. Your clock just ticks; energy can't
	# stretch it. What energy DOES is length-contract the sky: the world
	# rushes past gamma times faster, so the ground can arrive before the
	# dice do. Earth's clocks, meanwhile, run gamma times fast.
	# The multiplier is soft-capped so the top origins stay readable —
	# the Oh-My-God run should feel inevitable, not frantic.
	gamma = 1.0 + GAMMA_K * speed_frac * speed_frac + Meta.gamma_bonus()
	velocity = heading * speed * minf(gamma * CONTRACT, 7.0)
	position += velocity * delta
	_apply_bounds()

	# Dense-earth drag: below the surface the rock bleeds a little speed,
	# more the deeper you go — you feel yourself starting to bog down.
	if global_position.y > Atmos.GROUND_Y:
		_depth_f = clampf(Atmos.depth_m_at(global_position.y) / 260.0, 0.0, 1.0)
		speed = maxf(speed - (6.0 + 26.0 * _depth_f) * delta, SPEED_FLOOR)
	else:
		_depth_f = 0.0

	# Camera framing: ENFORCE the muon on the 1/3 line. A feed-forward aim
	# (scaling gently with fall speed) does the coarse work; a small bounded
	# correction — driven by the muon's real, post-projection screen position
	# published by the 3D stage — pins it exactly on the third. The
	# correction is frozen for a beat after any large positional jump so a
	# teleport or big boost (which the camera smoothing lags on) can't wind
	# it up. This is the single authority for _camera.position.
	var gy: float = global_position.y
	if absf(gy - _last_gy) > 2500.0:
		_frame_settle = 0.45
	_last_gy = gy
	_frame_settle = maxf(_frame_settle - delta, 0.0)
	var root_h: float = get_tree().root.get_visible_rect().size.y
	if _frame_settle <= 0.0 and Game.muon_screen_pos.y > -1.0e5 and root_h > 1.0:
		var err: float = Game.muon_screen_pos.y - root_h * FRAME_FRACTION
		# +err = muon too low → aim further down (which lifts it toward 1/3).
		_aim_correction = clampf(_aim_correction + clampf(err * 0.22, -50.0, 50.0), -150.0, 150.0)
	# The vertical aim is set directly (constant feed-forward + trim) so the
	# only remaining smoothing is the Camera2D's — no speed-driven bob, no
	# stacked lag. The result holds the muon on the 1/3 line.
	_camera.position.x = lerpf(_camera.position.x, velocity.x * 0.12, 1.0 - exp(-3.5 * delta))
	_camera.position.y = FRAME_AIM_DOWN + _aim_correction

	age_us += delta / REAL_SECONDS_PER_US
	lab_us += gamma * delta / REAL_SECONDS_PER_US

	# Decay is memoryless in proper time, and gamma can't touch it.
	var mean_real_life := LIFETIME * REAL_SECONDS_PER_US
	_hazard_integral += delta / mean_real_life
	decay_p = 1.0 - exp(-_hazard_integral)
	if not Game.shoot_mode and randf() < delta / mean_real_life:
		_die()
		return

	if speed > birth_speed * 1.15:
		Tasks.complete("overclock")

	if Input.is_action_just_pressed("zap") and _zap_cd <= 0.0:
		_zap()

	_track_circle(delta)
	_update_trail()
	_update_squash()
	_update_speed_fx(delta)
	_update_tail_intensity(delta)
	_lamp.queue_redraw()
	_heartbeat()


## The muon's headlamp: a forward cone of warm light, lit only underground
## where it's grinding through dirt and rock. Points along travel; brightens
## with depth. Additive over the dark earth (see the _lamp node's material).
func _draw_lamp() -> void:
	var ug := clampf((global_position.y - Atmos.GROUND_Y) / 500.0, 0.0, 1.0)
	if ug <= 0.01:
		return
	var dir := velocity
	if dir.length() < 1.0:
		dir = heading
	dir = dir.normalized()
	var perp := dir.orthogonal()
	var flick := 0.9 + 0.1 * sin(_clock * 24.0)
	var beam := Color(1.0, 0.82, 0.32)
	var near := dir * 10.0
	var far := dir * (230.0 + 90.0 * ug)
	var pts := PackedVector2Array([
		near + perp * 12.0, far + perp * (120.0 + 40.0 * ug),
		far - perp * (120.0 + 40.0 * ug), near - perp * 12.0,
	])
	var a := 0.5 * ug * flick
	var cols := PackedColorArray([
		Color(beam, a), Color(beam, 0.0), Color(beam, 0.0), Color(beam, a),
	])
	_lamp.draw_polygon(pts, cols)
	# The lamp itself, a hot little bulb on the leading edge.
	_lamp.draw_circle(near, 8.0, Color(1.0, 0.95, 0.7, 0.85 * ug))
	_lamp.draw_circle(near, 4.0, Color(1.0, 1.0, 0.92, ug))


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
		"+ %s" % source, Juice.SUN)


## Ploughing into debris (meteors, space junk) scrubs your speed.
func slow(amount: float, source: String) -> void:
	if not alive or finished:
		return
	speed = maxf(speed - amount, SPEED_FLOOR)
	Sfx.play("deny", -4.0)
	Juice.shake(0.22)
	Juice.glitch(0.12, 0.3)
	_pop_scale(Vector2(0.62, 1.45))
	FloatText.spawn(get_parent(), global_position + Vector2(0, -46),
		"− %s" % source, Juice.PINK)


## Any reactable within zap range right now? (drives touch auto-zap.)
func _zappable_near() -> bool:
	for node in get_tree().get_nodes_in_group("zappable"):
		if node is Node2D and node.global_position.distance_to(global_position) < ZAP_RADIUS:
			return true
	return false


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
	# Always breathing, a little more visibly when drifting slow.
	var breath := 1.0 + (0.025 - 0.015 * stretch) * sin(_clock * 2.7)
	_body.rotation = heading.angle()
	_body.applied_squash = Vector2(1.0 + 0.26 * stretch, (1.0 - 0.18 * stretch) * breath)


func _update_speed_fx(delta: float) -> void:
	# Keyed to apparent (contracted) velocity — what the view actually does.
	var target := clampf((velocity.length() - 600.0) / 2600.0, 0.0, 1.0)
	_speed_fx = lerpf(_speed_fx, target, 1.0 - exp(-6.0 * delta))
	_speed_lines.intensity = _speed_fx
	_speed_lines.dir = heading
	_wind.emitting = _speed_fx > 0.45
	_wind.direction = -heading
	_sparkles.modulate.a = clampf(0.35 + speed / SPEED_CAP, 0.0, 1.0)
	var zoom := lerpf(1.0, 0.84, _speed_fx)
	_camera.zoom = _camera.zoom.lerp(Vector2.ONE * zoom, 1.0 - exp(-4.0 * delta))
	Juice.set_relativity(heading, clampf((speed - 330.0) / 750.0, 0.0, 1.0),
		clampf((gamma - 1.0) / 14.0, 0.0, 1.0))
	_ghost_timer -= delta
	if velocity.length() > 1500.0 and _ghost_timer <= 0.0:
		_spawn_ghost()
		_ghost_timer = 0.04
	# Radiative regime: brem sparks and continuous forward showers.
	if gamma > BREM_GAMMA:
		_brem_timer -= delta
		if _brem_timer <= 0.0:
			_brem_timer = randf_range(0.4, 0.75)
			var burst: Node2D = BremBurst.new()
			burst.position = global_position + heading * randf_range(120.0, 260.0)
			burst.dir = heading
			get_parent().add_child(burst)
			Sfx.play("tick", -14.0, 0.25)


## The tail escalates with depth: wider, hotter, and increasingly a
## continuous forward shower as the muon rams through ever-denser earth.
func _update_tail_intensity(delta: float) -> void:
	var d := _depth_f
	_trail.width = 15.0 * (1.0 + d * 1.9)
	_trail_halo.width = 30.0 * (1.0 + d * 1.7)
	var hot := Color(1.0, 1.0, 0.97).lerp(Color(1.0, 0.46, 0.30), d)
	_trail.gradient.set_color(1, Color(hot, 0.6 + 0.3 * d))
	_trail_halo.gradient.set_color(1, Color(hot, 0.16 + 0.22 * d))
	_sparkles.scale_amount_min = 0.14 + 0.4 * d
	_sparkles.scale_amount_max = 0.34 + 0.9 * d
	# Underground, brem showers fire faster and faster — showering like
	# crazy by the time you're deep.
	if d > 0.04:
		_shower_timer -= delta
		if _shower_timer <= 0.0:
			_shower_timer = lerpf(0.5, 0.07, d)
			var burst: Node2D = BremBurst.new()
			burst.position = global_position + heading * randf_range(70.0, 220.0)
			burst.dir = heading
			get_parent().add_child(burst)
			if d > 0.5 and randf() < 0.3:
				Sfx.play("tick", -16.0, 0.3)


func _heartbeat() -> void:
	# Past the mean lifetime you're on borrowed time; the heart knows.
	if age_us > LIFETIME * 0.8:
		var bucket := int(age_us / 0.1)
		if bucket != _last_tick_bucket:
			_last_tick_bucket = bucket
			Sfx.play("tick", -6.0)


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
