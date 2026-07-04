extends "res://game/world/props/prop_base.gd"
## A drowsy little satellite in a decaying orbit. Bump into it and its
## capacitor bank discharges through you: sparks, a proper speed boost,
## and a half-second of digital glitch while its flight computer reboots.

const FloatText := preload("res://game/fx/float_text.gd")
const BOOST := 170.0

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
	_sprite = make_sprite("res://assets/sprites/satellite.svg", 0.55, Vector2(0, 4))
	_overlay = make_overlay(_draw_face)


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
			if d < 52.0 or (fast and d < 72.0):
				_collect(m, fast)
	_overlay.queue_redraw()


func _collect(m, clean_hit: bool) -> void:
	collected = true
	var pts := 2 if clean_hit else 1
	Meta.add_sparks(pts)
	m.refund_time(0.15)
	m.boost(BOOST, "satellite capacitors")
	Tasks.complete("bonk_satellite")
	Juice.glitch(0.5)
	Juice.hitstop(0.05, 0.15)
	Sfx.play("glitch", -2.0)
	var suffix := " (clean hit!)" if clean_hit else ""
	FloatText.spawn(get_parent(), global_position + Vector2(0, -40),
		"+%d spark%s · +0.15 µs%s" % [pts, "s" if pts > 1 else "", suffix], Juice.MINT)


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
	c.draw_circle(Vector2(0, -29), 3.4, Color("ff8fa3") if light_on else Color("d0d0d0"))
	# Face on the gold body: asleep on duty, dizzy X-eyes once bonked.
	if collected:
		for side: float in [-1.0, 1.0]:
			var ex := side * 7.0 - 3.0
			c.draw_line(Vector2(ex - 2.5, -1.5), Vector2(ex + 2.5, 3.5), Juice.INK, 1.8, true)
			c.draw_line(Vector2(ex - 2.5, 3.5), Vector2(ex + 2.5, -1.5), Juice.INK, 1.8, true)
		c.draw_arc(Vector2(-3, 9), 3.0, PI + 0.5, TAU - 0.5, 8, Juice.INK, 1.6, true)
	else:
		c.draw_arc(Vector2(-9, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.6, true)
		c.draw_arc(Vector2(3, 1), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.6, true)
		c.draw_arc(Vector2(-3, 7), 3.5, 0.5, PI - 0.5, 8, Juice.INK, 1.4, true)
