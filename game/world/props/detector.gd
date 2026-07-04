extends "res://game/world/props/prop_base.gd"
## The Muon Observatory: a friendly little lab whose scintillator pads
## span the whole valley floor. It has been waiting for you all day.

const TaskPop := preload("res://game/fx/task_pop.gd")

var _t := 0.0
var _celebrate := 0.0
var _prebeep := 0.0
var _overlay: Node2D


func _setup() -> void:
	z_index = 3
	# 540x320 doc; building base sits at doc y=282, so lift the sprite so
	# the base lands on the node origin (which sits on the grass line).
	make_sprite("res://assets/sprites/detector.svg", 0.6, Vector2(0, -73))
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


func count() -> void:
	_celebrate = 5.0
	TaskPop.confetti(get_parent(), global_position + Vector2(0, -90), 40)


func _draw() -> void:
	# Scintillator pads across the ground (drawn beneath the building art).
	for i in range(-7, 8):
		var glow := 0.35 + 0.15 * sin(_t * 2.0 + i * 0.9)
		if _celebrate > 0.0:
			glow = 0.8 + 0.2 * sin(_t * 10.0 + i)
		draw_rect(Rect2(i * 170.0 - 70.0, 26.0, 140.0, 16.0), Color(Juice.MINT, glow))


func _draw_dynamic(c: Node2D) -> void:
	var font := ThemeDB.fallback_font
	# Sign text on the white plate (plate center: doc (270,152) -> local).
	var sign_text := "MUON OBSERVATORY"
	var w := font.get_string_size(sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	c.draw_string(font, Vector2(-w * 0.5, -73.0 + (152.0 - 160.0) * 0.6 + 5.0),
		sign_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Juice.INK)
	# Status LED (doc (110,150) -> local): blinks amber, green when counted.
	var led := Color("74e08c") if _celebrate > 0.0 \
		else (Juice.SUN if int(_t * 2.0) % 2 == 0 else Color("d0d0d0"))
	if _prebeep > 0.0:
		led = Color("74e08c") if int(_t * 8.0) % 2 == 0 else Juice.SUN
	c.draw_circle(Vector2((110.0 - 270.0) * 0.6, -73.0 + (150.0 - 160.0) * 0.6), 5.5, led)
	if _celebrate > 0.0:
		c.draw_string(Juice.hand_font, Vector2(-34.0, -16.0), "+1 muon!!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("2e8b57"))
