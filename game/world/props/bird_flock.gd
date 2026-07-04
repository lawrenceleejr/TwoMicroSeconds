extends "res://game/world/props/prop_base.gd"
## A little flock circling lazily until something with a lightning bolt shows up.

var _t := 0.0
var _scattered := false
var _birds := []


func _setup() -> void:
	_t = randf() * 7.0
	for i in 5:
		_birds.append({
			"angle": TAU * i / 5.0,
			"radius": randf_range(28.0, 58.0),
			"phase": randf() * TAU,
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
		})


func _process(delta: float) -> void:
	_t += delta
	if _scattered:
		var all_gone := true
		for b in _birds:
			b["pos"] += b["vel"] * delta
			if b["pos"].length() < 900.0:
				all_gone = false
		if all_gone:
			queue_free()
			return
	else:
		var m := muon()
		if m != null and muon_dist() < 80.0 and float(m.get("speed")) > 600.0:
			_scatter()
		for b in _birds:
			b["angle"] += delta * 0.5
			b["pos"] = Vector2(cos(b["angle"]), sin(b["angle"]) * 0.5) * b["radius"]
	queue_redraw()


func zapped(_source: Node2D) -> void:
	_scatter()


func _scatter() -> void:
	if _scattered:
		return
	_scattered = true
	Sfx.play("chirp", -3.0)
	Tasks.complete("scatter_birds")
	for b in _birds:
		var dir := (b["pos"] as Vector2).normalized()
		if dir.length() < 0.5:
			dir = Vector2.RIGHT.rotated(randf() * TAU)
		b["vel"] = dir * randf_range(320.0, 520.0) + Vector2(0, -160)


func _draw() -> void:
	for i in _birds.size():
		var b: Dictionary = _birds[i]
		var pos: Vector2 = b["pos"]
		var flap := sin(_t * (10.0 if _scattered else 5.0) + b["phase"]) * 3.5
		var col := Color(Juice.INK, 0.85)
		# An "m" glyph of two arcs, wings flapping.
		draw_polyline(PackedVector2Array([
			pos + Vector2(-7.0, flap * 0.4),
			pos + Vector2(-3.5, -4.0 - flap),
			pos + Vector2(0.0, 0.0),
			pos + Vector2(3.5, -4.0 - flap),
			pos + Vector2(7.0, flap * 0.4),
		]), col, 2.0, true)
