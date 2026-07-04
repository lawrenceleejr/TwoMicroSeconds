extends "res://game/world/props/prop_base.gd"
## A drowsy little satellite in a decaying orbit. Bump into it and it
## coughs up sparks (the meta-currency) — with a full-screen glitch,
## because you just rebooted its flight computer.

const FloatText := preload("res://game/fx/float_text.gd")

var collected := false

var _t := 0.0
var _spin := 0.0
var _blink := 0.0


func _setup() -> void:
	_t = randf() * 8.0
	_spin = randf_range(-0.15, 0.15)


func _process(delta: float) -> void:
	_t += delta
	_blink = maxf(_blink - delta, 0.0)
	rotation += _spin * delta * (6.0 if collected else 1.0)
	position.y += sin(_t * 0.6) * 4.0 * delta
	if not collected:
		var m := muon()
		if m != null and m.get("alive") and not m.get("finished"):
			var d := muon_dist()
			var dashing: bool = m.get("dashing")
			if d < 48.0 or (dashing and d < 70.0):
				_collect(m, dashing)
	queue_redraw()


func _collect(m, clean_hit: bool) -> void:
	collected = true
	var pts := 2 if clean_hit else 1
	Meta.add_sparks(pts)
	m.refund_time(0.15)
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


func _draw() -> void:
	var ink := Color(Juice.INK, 0.75)
	# Solar panels.
	for side: float in [-1.0, 1.0]:
		var panel := Rect2(22.0 * side - (14.0 if side < 0.0 else 0.0), -10.0, 14.0, 20.0)
		draw_rect(panel, Color("9bb8e8"))
		draw_rect(panel, ink, false, 1.5)
		var mid_x := panel.position.x + panel.size.x * 0.5
		draw_line(Vector2(mid_x, -10), Vector2(mid_x, 10), Color(Juice.INK, 0.3), 1.0)
		draw_line(Vector2(panel.position.x, 0), Vector2(panel.end.x, 0), Color(Juice.INK, 0.3), 1.0)
	# Body.
	draw_rect(Rect2(-17, -12, 34, 24), Juice.CREAM)
	draw_rect(Rect2(-17, -12, 34, 24), ink, false, 2.0)
	# Antenna with a blinking light.
	draw_line(Vector2(0, -12), Vector2(0, -24), ink, 2.0)
	var light_on := (_blink > 0.0 and int(_t * 10.0) % 2 == 0) or (int(_t * 1.5) % 3 == 0 and _blink <= 0.0)
	draw_circle(Vector2(0, -26), 3.0, Color("ff8fa3") if light_on else Color("d0d0d0"))
	# Face: asleep on duty, dizzy X-eyes once bonked.
	if collected:
		for side: float in [-1.0, 1.0]:
			var ex := side * 6.0
			draw_line(Vector2(ex - 2.5, -4.5), Vector2(ex + 2.5, 0.5), Juice.INK, 1.8)
			draw_line(Vector2(ex - 2.5, 0.5), Vector2(ex + 2.5, -4.5), Juice.INK, 1.8)
		draw_arc(Vector2(0, 5), 3.0, PI + 0.5, TAU - 0.5, 8, Juice.INK, 1.6, true)
	else:
		draw_arc(Vector2(-6, -2), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.6, true)
		draw_arc(Vector2(6, -2), 3.0, PI + 0.4, TAU - 0.4, 8, Juice.INK, 1.6, true)
		draw_arc(Vector2(0, 4), 3.5, 0.5, PI - 0.5, 8, Juice.INK, 1.4, true)
