extends "res://game/world/props/prop_base.gd"
## A drowsy little satellite in a decaying orbit. Bump into it and its
## capacitor bank discharges through you: sparks, a proper speed boost,
## and a half-second of digital glitch while its flight computer reboots.

const FloatText := preload("res://game/fx/float_text.gd")
const BOOST := 90.0

var collected := false

var _t := 0.0
var _spin := 0.0
var _blink := 0.0
var _sprite: Sprite2D
var _overlay: Node2D


func _setup() -> void:
	add_to_group("satellite")
	_t = randf() * 8.0
	_spin = randf_range(-0.15, 0.15)
	_sprite = make_sprite("res://assets/sprites/satellite.svg", 0.75, Vector2(0, 5))
	shadow_size = 108.0
	shadow_drop = 58.0
	_overlay = make_overlay(_draw_face)
	_overlay.scale = Vector2.ONE * (0.75 / 0.55)


func _process(delta: float) -> void:
	_t += delta
	_blink = maxf(_blink - delta, 0.0)
	rotation += _spin * delta * (6.0 if collected else 1.0)
	position.y += sin(_t * 0.6) * 4.0 * delta
	if not collected:
		var m := muon()
		if m != null and m.get("alive") and not m.get("finished"):
			var d := muon_dist()
			var fast: bool = float(m.get("speed")) > 750.0
			if d < 88.0 or (fast and d < 110.0):
				_collect(m, fast)
	_overlay.queue_redraw()


func _collect(m, clean_hit: bool) -> void:
	collected = true
	Meta.add_sparks(1)
	# Sparks come slow; a clean fast hit pays in speed instead.
	m.boost(BOOST * (1.35 if clean_hit else 1.0), "satellite")
	Tasks.complete("bonk_satellite")
	Juice.glitch(0.5)
	Juice.hitstop(0.05, 0.15)
	Sfx.play("glitch", -2.0)
	var suffix := "  clean hit!" if clean_hit else ""
	FloatText.spawn(get_parent(), global_position + Vector2(0, -46),
		"+1 spark%s" % suffix, Juice.MINT)


func zapped(_source: Node2D) -> void:
	# A hint: it beeps and blinks, inviting a closer look.
	if collected:
		return
	_blink = 1.6
	Sfx.play("tick", -4.0)


func _draw_face(c: Node2D) -> void:
	# Antenna beacon.
	var light_on := (_blink > 0.0 and int(_t * 10.0) % 2 == 0) \
		or (int(_t * 1.5) % 3 == 0 and _blink <= 0.0)
	c.draw_circle(Vector2(0, -29), 3.4, Color(Juice.PINK) if light_on else Color(Juice.PAPER, 0.6))
	# Once bonked, the flight computer visibly reboots: a strip of status
	# bars stutters across the gold body. Machines here glitch, not grimace.
	if collected:
		for i in 3:
			if int(_t * (9.0 + i * 3.0)) % 3 == 0:
				continue
			var bw := 6.0 + float((i * 7) % 9)
			c.draw_rect(Rect2(-11.0 + i * 8.0, -2.0 + i * 4.0, bw, 2.6),
				Juice.PINK if i % 2 == 0 else Juice.MINT)
