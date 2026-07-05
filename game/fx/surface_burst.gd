extends Node2D
## The punch-through: the muon hits the meadow and blows a hole in it.
## Turf clods and dust fly UP and outward (you came from above), a shock
## ring expands, and a white flash sells the impact. Ridiculous Fishing's
## "smash through the surface" beat, in the print language.

const DUR := 1.1

## The muon's velocity at impact — clods spray back against it, dust with it.
var motion := Vector2(0, 600)

var _t := 0.0
var _clods := []


func _ready() -> void:
	z_index = 8
	var rng := RandomNumberGenerator.new()
	rng.seed = 20081992
	var back := -motion.normalized()  # up-and-out, against travel
	for i in 16:
		var ang := back.angle() + rng.randf_range(-1.5, 1.5)
		var spd := rng.randf_range(240.0, 780.0)
		_clods.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(ang) * spd,
			"spin": rng.randf_range(-12.0, 12.0),
			"rot": rng.randf() * TAU,
			"r": rng.randf_range(4.0, 11.0),
			"grass": rng.randf() < 0.6,
		})


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	for c in _clods:
		# Ballistic with a little gravity so the clods arc — debris, not
		# particles bound by the muon's own no-gravity rule.
		c["vel"] += Vector2(0, 900.0) * delta
		c["pos"] += c["vel"] * delta
		c["rot"] += c["spin"] * delta
	queue_redraw()


func _draw() -> void:
	var k := clampf(_t / DUR, 0.0, 1.0)
	# Impact flash.
	if _t < 0.16:
		var fk := _t / 0.16
		draw_circle(Vector2.ZERO, lerpf(20.0, 150.0, fk), Color(1, 1, 0.96, 0.8 * (1.0 - fk)))
	# Shock ring, misregistered.
	var rk := clampf(_t / 0.5, 0.0, 1.0)
	if rk < 1.0:
		var rr := lerpf(20.0, 260.0, 1.0 - pow(1.0 - rk, 2.0))
		draw_arc(Vector2.ZERO, rr, 0, TAU, 48, Color(Juice.PINK, 0.7 * (1.0 - rk)), 3.5, true)
		draw_arc(Vector2(5, -4), rr * 1.05, 0, TAU, 48, Color(Juice.CREAM, 0.4 * (1.0 - rk)), 2.0, true)
	# Torn turf hole rim (a dark gash where the surface broke).
	if k < 0.8:
		draw_arc(Vector2.ZERO, 30.0, 0, TAU, 20, Color(Juice.INK, 0.5 * (1.0 - k / 0.8)), 6.0)
	# Flying clods: grass-green tops, ink-dark soil, tumbling.
	var alpha := 1.0 - k * k
	for c in _clods:
		var col: Color = Atmos.GRASS if c["grass"] else Color("5a4632")
		var rr: float = c["r"]
		var pos: Vector2 = c["pos"]
		draw_set_transform(pos, c["rot"], Vector2.ONE)
		draw_rect(Rect2(-rr, -rr * 0.8, rr * 2.0, rr * 1.6), Color(col, alpha))
		draw_rect(Rect2(-rr, -rr * 0.8, rr * 2.0, rr * 1.6), Color(Juice.INK, alpha * 0.6), false, 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
