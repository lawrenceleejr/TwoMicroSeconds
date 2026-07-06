extends "res://game/world/props/prop_base.gd"
## A buried curiosity you can discover on the long fall underground: an
## ancient tomb, a pocket of oil, a secret tunnel. Brushing past (or
## zapping) one logs the find — and, rarely, a muon slipping through dense
## matter triggers a MUON-CATALYZED FUSION EVENT.

const FUSION_CHANCE := 0.14
const FloatText := preload("res://game/fx/float_text.gd")

var kind := "tomb"
var _t := 0.0
var _found := false
var _flash := 0.0


static func new_kind(k: String) -> Node2D:
	var d = load("res://game/world/props/discovery.gd").new()
	d.kind = k
	return d


func _setup() -> void:
	add_to_group("discovery")
	z_index = 2
	_t = randf() * 5.0


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta * 1.5, 0.0)
	var m := muon()
	if m != null and m.get("alive") and not _found and muon_dist() < 92.0:
		_discover()
	queue_redraw()


func zapped(_source: Node2D) -> void:
	if not _found:
		_discover()


func _discover() -> void:
	_found = true
	_flash = 1.0
	Sfx.play("pop", -3.0)
	var label := ""
	match kind:
		"tomb":
			label = "an ancient tomb!"
			Tasks.complete("find_tomb")
		"oil":
			label = "struck oil!"
			Tasks.complete("strike_oil")
		_:
			label = "a secret tunnel!"
			Tasks.complete("find_tunnel")
	FloatText.spawn(get_parent(), global_position + Vector2(0, -48), label, Juice.SUN)
	# Rarely, the muon catalyses fusion in the dense matter it pierces.
	if randf() < FUSION_CHANCE:
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.fusion_event()
		var m := muon()
		if m != null:
			m.boost(120.0, "muon-catalyzed fusion")
		Meta.add_sparks(3)
		Juice.shake(0.6)
		Juice.glitch(0.4, 0.8)


func _draw() -> void:
	var glow := Color(Juice.SUN, 0.25 + _flash * 0.6)
	if _found:
		draw_circle(Vector2.ZERO, 40.0 + _flash * 30.0, Color(Juice.SUN, 0.10 * _flash))
	match kind:
		"tomb":
			# A stone sarcophagus with a glyph.
			draw_rect(Rect2(-26, -16, 52, 34), Color("b9a67e"))
			draw_rect(Rect2(-26, -16, 52, 34), Color(Juice.INK, 0.8), false, 2.5)
			draw_rect(Rect2(-30, -22, 60, 8), Color("cdb98d"))
			draw_rect(Rect2(-30, -22, 60, 8), Color(Juice.INK, 0.8), false, 2.0)
			draw_line(Vector2(0, -10), Vector2(0, 12), Color(Juice.INK, 0.6), 2.0)
			draw_line(Vector2(-7, -2), Vector2(7, -2), Color(Juice.INK, 0.6), 2.0)
		"oil":
			# A black pool with a little derrick.
			draw_circle(Vector2(0, 16), 30.0, Color("100c14"))
			draw_circle(Vector2(0, 16), 30.0, Color(Juice.INK, 0.7))
			draw_line(Vector2(-16, 16), Vector2(0, -26), Color(Juice.INK, 0.85), 3.0)
			draw_line(Vector2(16, 16), Vector2(0, -26), Color(Juice.INK, 0.85), 3.0)
			draw_line(Vector2(-8, -4), Vector2(8, -4), Color(Juice.INK, 0.7), 2.5)
			for i in 3:
				draw_circle(Vector2(i * 6 - 6, 4 - _t * 8.0 + i * 5), 2.5, Color(Juice.SUN, 0.6))
		_:
			# A framed tunnel mouth into the dark.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-30, 20), Vector2(-30, -6), Vector2(0, -24),
				Vector2(30, -6), Vector2(30, 20),
			]), Color("0a0810"))
			draw_polyline(PackedVector2Array([
				Vector2(-30, 20), Vector2(-30, -6), Vector2(0, -24),
				Vector2(30, -6), Vector2(30, 20),
			]), Color("9a8f77"), 3.0, true)
			draw_line(Vector2(-18, 20), Vector2(-18, 2), Color(Juice.PAPER, 0.3), 2.0)
			draw_line(Vector2(18, 20), Vector2(18, 2), Color(Juice.PAPER, 0.3), 2.0)
	if not _found:
		draw_arc(Vector2.ZERO, 44.0, 0, TAU, 24, glow, 1.5, true)
