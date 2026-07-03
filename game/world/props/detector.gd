extends "res://game/world/props/prop_base.gd"
## The Muon Observatory: a friendly little lab whose scintillator pads
## span the whole valley floor. It has been waiting for you all day.

const TaskPop := preload("res://game/fx/task_pop.gd")

var _t := 0.0
var _celebrate := 0.0
var _prebeep := 0.0


func _setup() -> void:
	z_index = 3


func _process(delta: float) -> void:
	_t += delta
	_prebeep = maxf(_prebeep - delta, 0.0)
	if _celebrate > 0.0:
		_celebrate -= delta
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_prebeep = 1.5
	Sfx.play("tick", -4.0)


func count() -> void:
	_celebrate = 5.0
	TaskPop.confetti(get_parent(), global_position + Vector2(0, -90), 40)


func _draw() -> void:
	# Scintillator pads across the ground.
	for i in range(-7, 8):
		var glow := 0.35 + 0.15 * sin(_t * 2.0 + i * 0.9)
		if _celebrate > 0.0:
			glow = 0.8 + 0.2 * sin(_t * 10.0 + i)
		draw_rect(Rect2(i * 170.0 - 70.0, 26.0, 140.0, 16.0), Color(Juice.MINT, glow))
	# The lab building.
	draw_rect(Rect2(-190, -110, 380, 136), Juice.CREAM)
	draw_rect(Rect2(-190, -110, 380, 136), Color(Juice.INK, 0.6), false, 2.5)
	draw_rect(Rect2(-190, -132, 380, 24), Color("ff9aa8"))
	# Door.
	draw_rect(Rect2(-28, -44, 56, 70), Juice.PERIWINKLE)
	draw_circle(Vector2(16, -8), 3.0, Juice.SUN)
	# Radar dish.
	draw_line(Vector2(120, -132), Vector2(120, -160), Color(Juice.INK, 0.7), 3.0, true)
	draw_arc(Vector2(120, -170), 16.0, PI * 0.15, PI * 0.85, 12, Color(Juice.INK, 0.8), 3.0, true)
	# Status LED: blinks amber, goes green when we get counted.
	var led := Color("74e08c") if _celebrate > 0.0 else (Juice.SUN if int(_t * 2.0) % 2 == 0 else Color("d0d0d0"))
	if _prebeep > 0.0:
		led = Color("74e08c") if int(_t * 8.0) % 2 == 0 else Juice.SUN
	draw_circle(Vector2(-150, -92), 7.0, led)
	# Sign.
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-120, -66), "MUON OBSERVATORY", HORIZONTAL_ALIGNMENT_LEFT, 260, 20, Juice.INK)
	if _celebrate > 0.0:
		draw_string(font, Vector2(-64, -20), "+1 muon!!", HORIZONTAL_ALIGNMENT_LEFT, 200, 18, Color("2e8b57"))
