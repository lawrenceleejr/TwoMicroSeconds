extends "res://game/world/props/prop_base.gd"
## The Compact Muon Solenoid, waiting in its cavern 100 m down at LHC
## Point 5. It has been counting muons all day; yours is still special.

const TaskPop := preload("res://game/fx/task_pop.gd")
const S := 0.62  # sprite scale (480x480 art, wheel center at 240,240)

var _t := 0.0
var _celebrate := 0.0
var _prebeep := 0.0
var _overlay: Node2D


func _setup() -> void:
	z_index = 3
	# Node origin is the wheel center; the art's stand reaches ~212 below.
	make_sprite("res://assets/sprites/cms.svg", S, Vector2.ZERO)
	_overlay = make_overlay(_draw_dynamic)


func _process(delta: float) -> void:
	_t += delta
	_prebeep = maxf(_prebeep - delta, 0.0)
	if _celebrate > 0.0:
		_celebrate -= delta
	queue_redraw()
	_overlay.queue_redraw()


func zapped(_source: Node2D) -> void:
	_prebeep = 1.5
	Sfx.play("tick", -4.0)


func _draw() -> void:
	# The cavern: a great arch of dark behind the wheel, string lights.
	var arch := Color("0f0b0a")
	draw_rect(Rect2(-560.0, -320.0, 1120.0, 640.0), Color(arch, 0.55))
	draw_arc(Vector2(0, 40), 330.0, PI, TAU, 40, Color(Juice.PAPER, 0.20), 3.0, true)
	draw_arc(Vector2(-6, 44), 330.0, PI, TAU, 40, Color(Juice.PINK, 0.12), 2.0, true)
	# Work lights strung along the arch.
	for i in 7:
		var ang := PI + (float(i) + 0.5) / 7.0 * PI
		var lp := Vector2(0, 40) + Vector2.from_angle(ang) * 318.0
		var on := int(_t * 1.4 + float(i)) % 5 != 0
		draw_circle(lp, 4.0, Color(Juice.SUN, 0.9) if on else Color(Juice.PAPER, 0.3))
	# Guide rails on the cavern floor.
	draw_line(Vector2(-520, 285), Vector2(520, 285), Color(Juice.INK, 0.6), 3.0)
	draw_line(Vector2(-520, 296), Vector2(520, 296), Color(Juice.PINK, 0.25), 2.0)
	# Scintillator strip pulsing across the floor; surges when it counts.
	for i in range(-3, 4):
		var glow := 0.16 + 0.07 * sin(_t * 2.0 + i * 0.9)
		if _celebrate > 0.0:
			glow = 0.55 + 0.25 * sin(_t * 10.0 + i)
		draw_rect(Rect2(i * 150.0 - 60.0, 306.0, 120.0, 8.0), Color(Juice.MINT, glow))


func count() -> void:
	_celebrate = 5.0
	TaskPop.confetti(get_parent(), global_position + Vector2(0, -160), 40)


func _draw_dynamic(c: Node2D) -> void:
	var font := ThemeDB.fallback_font
	# Stencilled on the cavern wall above the wheel.
	var sign_text := "CMS · LHC POINT 5"
	var w := font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	c.draw_string(font, Vector2(-w * 0.5, -196.0), sign_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(Juice.PAPER, 0.9))
	var sub := "100 m below · counting since 2008"
	var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	c.draw_string(font, Vector2(-sw * 0.5, -178.0), sub,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(Juice.PAPER, 0.5))
	# Status LED on the beam spot: amber heartbeat, mint when counted.
	var led := Color("74e08c") if _celebrate > 0.0 \
		else (Juice.SUN if int(_t * 2.0) % 2 == 0 else Color(Juice.PAPER, 0.5))
	if _prebeep > 0.0:
		led = Color("74e08c") if int(_t * 8.0) % 2 == 0 else Juice.SUN
	c.draw_circle(Vector2(96.0, -120.0), 6.0, led)
	if _celebrate > 0.0:
		c.draw_string(Juice.hand_font, Vector2(-46.0, -216.0), "+1 muon!!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("74e08c"))
