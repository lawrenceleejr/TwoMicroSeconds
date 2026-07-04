extends Node2D
## The opening seconds of every run, told properly:
## a cosmic-ray PROTON slams into the atmosphere, showers into a spray of
## particles, the camera follows one PION, and half a second later the pion
## decays — muon plus a neutrino that wanders off. Then you're flying.
##
## The muon node exists the whole time (it carries the camera); this
## sequence hides it, drives its position, and hands over control at the end.

const PROTON_T := 0.75
const PION_T := 0.55
const FADE_T := 1.0
# Muon handover speed of a tier-0 birth; the reference the cinematic
# speed scale is measured against.
const BASE_HANDOVER_V := 610.0

var muon  # untyped: script members

var _t := 0.0
var _speed_scale := 1.0
var _spawn := Vector2.ZERO
var _proton_from := Vector2.ZERO
var _pion_pos := Vector2.ZERO
var _pion_vel := Vector2.ZERO
var _shower := []
var _neutrino_pos := Vector2.ZERO
var _neutrino_vel := Vector2.ZERO
var _phase := 0
var _done_at := 0.0


func _ready() -> void:
	z_index = 9
	_spawn = position
	# A hotter origin means a faster parent: the proton and pion move at
	# a speed matched to the muon they'll hand over (softened, so the
	# Oh-My-God intro is emphatic rather than instantaneous).
	if muon != null:
		var bs: float = muon.birth_speed
		var sf: float = clampf(bs / muon.REF_SPEED, 0.0, 1.5)
		var gam: float = 1.0 + muon.GAMMA_K * sf * sf + Meta.gamma_bonus()
		var handover_v: float = bs * minf(gam * muon.CONTRACT, 7.0)
		_speed_scale = clampf(0.55 + 0.45 * (handover_v / BASE_HANDOVER_V), 1.0, 4.5)
	# Same flight time, longer approach: speed reads as distance covered.
	_proton_from = _spawn + Vector2(-260.0, -640.0) * _speed_scale
	_pion_pos = _spawn
	_pion_vel = Vector2(0.3, 1.0).normalized() * 560.0 * _speed_scale


func _process(delta: float) -> void:
	_t += delta
	if _phase == 0 and _t >= PROTON_T:
		_phase = 1
		_burst()
	elif _phase == 1 and _t >= PROTON_T + PION_T:
		_phase = 2
		_decay_to_muon()
	elif _phase == 2 and _t >= _done_at:
		queue_free()
		return

	if _phase == 0 and muon != null:
		# The camera rides the proton in.
		muon.set("global_position", _proton_from.lerp(_spawn, _t / PROTON_T))
	elif _phase == 1:
		_pion_pos += _pion_vel * delta
		for p in _shower:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 1.0 - 0.8 * delta
		if muon != null:
			muon.set("global_position", _pion_pos)
	elif _phase == 2:
		_neutrino_pos += _neutrino_vel * delta
	queue_redraw()


func _burst() -> void:
	Sfx.play("zap", -1.0, 0.0)
	Juice.shake(0.35)
	Juice.hitstop(0.05, 0.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 9:
		var ang := PI * 0.5 + rng.randf_range(-0.9, 0.9)  # downward cone
		_shower.append({
			"pos": _spawn,
			"vel": Vector2.from_angle(ang) * rng.randf_range(260.0, 620.0) * _speed_scale,
			"color": Juice.CONFETTI_COLORS[i % Juice.CONFETTI_COLORS.size()],
			"r": rng.randf_range(3.0, 6.0),
		})


func _decay_to_muon() -> void:
	Sfx.play("pop", -3.0, 0.0)
	Juice.shake(0.15)
	_neutrino_pos = _pion_pos
	_neutrino_vel = _pion_vel.rotated(-0.9) * 0.55
	_done_at = _t + FADE_T
	if muon == null:
		return
	muon.set("global_position", _pion_pos)
	muon.set("heading", _pion_vel.normalized())
	muon.set("intro_mode", false)
	muon.set("visible", true)
	muon.call("_pop_scale", Vector2(1.5, 0.6))


func _draw() -> void:
	if _phase == 0:
		# The proton: heavier, angrier, trailing fire.
		var pos := _proton_from.lerp(_spawn, _t / PROTON_T) - position
		var dir := (_spawn - _proton_from).normalized()
		var trail := 190.0 * minf(_speed_scale, 2.2)
		draw_line(pos - dir * trail, pos, Color(Juice.SUN, 0.75), 7.0, true)
		draw_line(pos - dir * trail * 0.47, pos, Color(1, 1, 1, 0.85), 3.5, true)
		draw_circle(pos, 13.0, Color("ff9d8a"))
		draw_circle(pos - Vector2(4, 3), 4.0, Color(1, 1, 1, 0.85))
		draw_circle(pos + Vector2(-4, 1), 2.2, Juice.INK)
		draw_circle(pos + Vector2(4, 1), 2.2, Juice.INK)
	elif _phase >= 1:
		var k := clampf((_t - PROTON_T) / 1.2, 0.0, 1.0)
		# Impact flash.
		if _t - PROTON_T < 0.3:
			var fk := (_t - PROTON_T) / 0.3
			draw_circle(_spawn - position, lerpf(10.0, 110.0, 1.0 - pow(1.0 - fk, 3.0)),
				Color(1, 1, 0.95, 0.7 * (1.0 - fk)))
		# The rest of the shower spraying away.
		for p in _shower:
			var col: Color = p["color"]
			col.a = 0.9 * (1.0 - k)
			draw_circle(p["pos"] - position, p["r"], col)
			draw_line(p["pos"] - position - (p["vel"] as Vector2) * 0.06,
				p["pos"] - position, Color(col, col.a * 0.5), 2.0, true)
		if _phase == 1:
			# Our pion, camera's darling.
			var pp := _pion_pos - position
			draw_line(pp - _pion_vel * 0.09, pp, Color(Juice.LILAC, 0.6), 4.0, true)
			draw_circle(pp, 10.0, Color("d9b8f0"))
			draw_circle(pp + Vector2(-3.5, -1), 2.0, Juice.INK)
			draw_circle(pp + Vector2(3.5, -1), 2.0, Juice.INK)
		else:
			# The neutrino, leaving without saying much.
			var fade := clampf(1.0 - (_t - (PROTON_T + PION_T)) / FADE_T, 0.0, 1.0)
			var np := _neutrino_pos - position
			draw_arc(np, 7.0, 0.0, TAU, 16, Color(1, 1, 1, 0.5 * fade), 1.5, true)
			draw_circle(np + Vector2(-2.5, -1), 1.2, Color(Juice.INK, 0.6 * fade))
			draw_circle(np + Vector2(2.5, -1), 1.2, Color(Juice.INK, 0.6 * fade))
