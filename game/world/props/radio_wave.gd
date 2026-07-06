extends "res://game/world/props/prop_base.gd"
## A stray radio wave drifting below the ionosphere — concentric ripples
## of RF. Surf it for a push, the same way you ride an aurora higher up.

const BOOST := 40.0

var _t := 0.0
var _glow := 0.0
var _boost_cd := 0.0
var _drift := 1.0


func _setup() -> void:
	add_to_group("radio")
	_t = randf() * 10.0
	_drift = 1.0 if randf() < 0.5 else -1.0
	z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	_glow = maxf(_glow - delta * 1.2, 0.0)
	_boost_cd = maxf(_boost_cd - delta, 0.0)
	position.x += _drift * 18.0 * delta
	var m := muon()
	if m != null and m.get("alive") and muon_dist() < 96.0:
		_glow = 1.0
		if _boost_cd <= 0.0:
			_boost_cd = 1.6
			m.boost(BOOST, "radio wave")
			if not Tasks.is_done("surf_radio"):
				Tasks.complete("surf_radio")
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_glow = 1.0


func _draw() -> void:
	# A transmitter dot firing expanding arcs to one side — clearly a wave,
	# not a cloud. Teal/violet RF inks.
	var base := 0.3 + _glow * 0.5
	for i in 4:
		var phase := fmod(_t * 0.9 + i * 0.25, 1.0)
		var r := 20.0 + phase * 78.0
		var a := (1.0 - phase) * base
		var col := Juice.MINT.lerp(Juice.PERIWINKLE, float(i) / 4.0)
		# Right-opening arc "))" — a broadcast.
		draw_arc(Vector2(-40, 0), r, -0.9, 0.9, 20, Color(col, a), 3.0, true)
	draw_circle(Vector2(-40, 0), 5.0, Color(Juice.MINT, 0.7 + _glow * 0.3))
	draw_circle(Vector2(-40, 0), 2.0, Color(1, 1, 1, 0.9))
	# A little mast.
	draw_line(Vector2(-40, 0), Vector2(-40, 14), Color(Juice.CREAM, 0.6), 2.0)
