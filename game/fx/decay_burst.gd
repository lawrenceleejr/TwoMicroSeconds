extends Node2D
## The game-over, drawn like a bubble-chamber photograph: a vertex flash,
## a misregistered ring, and three straight tracks ruled away from the
## decay point — electron bright, neutrinos barely there.

const DUR := 2.4

## Final momentum of the muon — the decay products inherit it, boosted
## forward like the real e⁻ ν ν̄ would be.
var motion := Vector2(0, 220)

var _t := 0.0
var _parts := []


func _ready() -> void:
	z_index = 9
	if motion.length() < 60.0:
		motion = Vector2(0, 220)
	_parts = [
		{"pos": Vector2.ZERO, "vel": motion * 0.9 + motion.orthogonal().normalized() * randf_range(-70, 70),
			"r": 9.0, "color": Juice.MINT, "ghost": false},
		{"pos": Vector2.ZERO, "vel": motion * 0.7 + motion.orthogonal().normalized() * randf_range(30, 110),
			"r": 5.5, "color": Color(1, 1, 1, 0.7), "ghost": true},
		{"pos": Vector2.ZERO, "vel": motion * 0.55 + motion.orthogonal().normalized() * randf_range(-110, -30),
			"r": 5.0, "color": Color(1, 1, 1, 0.7), "ghost": true},
	]


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	for p in _parts:
		# Ballistic: no gravity, no drag — they inherit their momentum
		# at production and simply keep going.
		p["pos"] += p["vel"] * delta
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DUR, 0.0, 1.0)
	var alpha := 1.0 - k * k
	# Vertex flash.
	if _t < 0.3:
		var fk := _t / 0.3
		draw_circle(Vector2.ZERO, lerpf(8.0, 74.0, 1.0 - pow(1.0 - fk, 3.0)),
			Color(1.0, 1.0, 0.95, 0.75 * (1.0 - fk)))
	# Expanding misregistered ring — the print flinches.
	var ring_k := clampf(_t / 0.7, 0.0, 1.0)
	if ring_k < 1.0:
		var rr := lerpf(12.0, 150.0, 1.0 - pow(1.0 - ring_k, 2.0))
		draw_arc(Vector2.ZERO, rr, 0, TAU, 48, Color(Juice.PINK, 0.7 * (1.0 - ring_k)), 2.5, true)
		draw_arc(Vector2(4, -3), rr * 1.05, 0, TAU, 48, Color(Juice.MINT, 0.4 * (1.0 - ring_k)), 1.5, true)
	for i in _parts.size():
		var p: Dictionary = _parts[i]
		var pos: Vector2 = p["pos"]
		var col: Color = p["color"]
		col.a *= alpha
		# The ruled track from the vertex — bubble-chamber language.
		draw_line(Vector2.ZERO, pos, Color(col, col.a * 0.35), 1.4, true)
		if p["ghost"]:
			# Neutrino: an empty ring, hardly deigning to interact.
			draw_arc(pos, p["r"] + 1.5, 0.0, TAU, 20, col, 1.6, true)
		else:
			# Electron: a bright comet carrying the momentum.
			var vel: Vector2 = p["vel"]
			var tail := vel.normalized() * -26.0
			draw_line(pos + tail, pos, Color(Juice.MINT, col.a * 0.6), 4.0, true)
			draw_circle(pos, p["r"], col)
			draw_circle(pos, p["r"] * 0.45, Color(1, 1, 1, col.a))
