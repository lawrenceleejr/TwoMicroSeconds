extends Node2D
## The soft game-over: the muon decays into an electron and two shy neutrinos
## that drift up and away, waving goodbye.

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
		p["pos"] += p["vel"] * delta
		p["vel"] *= 1.0 - 0.5 * delta  # bleed off, wave goodbye
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DUR, 0.0, 1.0)
	var alpha := 1.0 - k * k
	# Initial flash.
	if _t < 0.25:
		var fk := _t / 0.25
		draw_circle(Vector2.ZERO, lerpf(6.0, 60.0, fk), Color(1, 1, 1, 0.7 * (1.0 - fk)))
	for i in _parts.size():
		var p: Dictionary = _parts[i]
		var pos: Vector2 = p["pos"]
		var wob := Vector2(sin(_t * 5.0 + i * 2.1) * 4.0, 0.0)
		pos += wob
		var col: Color = p["color"]
		col.a *= alpha
		if p["ghost"]:
			# Neutrino: barely-there ghost with a wavy little mouth.
			draw_arc(pos, p["r"], 0.0, TAU, 20, col, 1.6, true)
			draw_circle(pos + Vector2(-1.8, -1.0), 1.0, Color(Juice.INK, alpha * 0.8))
			draw_circle(pos + Vector2(1.8, -1.0), 1.0, Color(Juice.INK, alpha * 0.8))
		else:
			# Electron: a tiny mint sibling.
			draw_circle(pos, p["r"], col)
			draw_circle(pos + Vector2(-2.4, -1.5), 1.3, Color(Juice.INK, alpha))
			draw_circle(pos + Vector2(2.4, -1.5), 1.3, Color(Juice.INK, alpha))
			draw_arc(pos + Vector2(0, 1.5), 2.4, 0.5, PI - 0.5, 8, Color(Juice.INK, alpha), 1.2, true)
