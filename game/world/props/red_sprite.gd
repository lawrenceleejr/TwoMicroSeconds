extends "res://game/world/props/prop_base.gd"
## A red sprite — the huge, ghostly lightning that dances above storms.
## It flickers in and out of existence; catch it while it's lit and its
## field hurls you downward.

const BOOST := 65.0

var _t := 0.0
var _boost_cd := 0.0
var _lit := 1.0
var _phase_offset := 0.0


func _setup() -> void:
	_phase_offset = randf() * 20.0
	z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	_boost_cd = maxf(_boost_cd - delta, 0.0)
	# Breathes: ~2.4 s on, ~1.4 s dim.
	var cycle := fmod(_t + _phase_offset, 3.8)
	_lit = clampf((2.4 - cycle) * 4.0 + 1.0, 0.15, 1.0) if cycle > 2.4 else \
		clampf(cycle * 4.0, 0.15, 1.0)
	var m := muon()
	if m != null and _lit > 0.6 and _boost_cd <= 0.0 and muon_dist() < 90.0:
		_boost_cd = 2.5
		m.boost(BOOST, "red sprite")
		Sfx.play("chirp", -6.0, 0.12)
	queue_redraw()


func zapped(_source: Node2D) -> void:
	# Zapping startles it fully lit for a moment.
	_t = ceilf(_t)
	Sfx.play("pop", -8.0)


func _draw() -> void:
	var a := _lit
	# Diffuse halo top.
	for r in [70.0, 46.0, 26.0]:
		draw_circle(Vector2(0, -60), r, Color(1.0, 0.3, 0.42, 0.05 * a * (80.0 / r)))
	# Hanging tendrils.
	for i in 7:
		var x := (i - 3) * 16.0 + sin(_t * 1.7 + i * 2.0) * 4.0
		var tendril_len := 60.0 + absi(hash(i * 31)) % 50
		var col := Color(1.0, 0.36, 0.5, (0.28 + 0.1 * sin(_t * 6.0 + i)) * a)
		draw_line(Vector2(x, -50), Vector2(x * 1.25, -50 + tendril_len), col, 5.0, true)
		draw_line(Vector2(x, -50), Vector2(x * 1.25, -50 + tendril_len * 0.7), Color(1, 0.6, 0.65, 0.3 * a), 2.0, true)
	# Bright core band.
	draw_rect(Rect2(-56, -66, 112, 14), Color(1.0, 0.42, 0.52, 0.35 * a))
	draw_rect(Rect2(-40, -62, 80, 7), Color(1.0, 0.7, 0.72, 0.4 * a))