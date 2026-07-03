extends "res://game/world/props/prop_base.gd"
## Streaks across the mesosphere. Get close while it's passing to photobomb it.

var vel := Vector2(700, 350)

var _life := 3.4
var _bombed := false


func _process(delta: float) -> void:
	position += vel * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if not _bombed and muon_dist() < 95.0:
		_bombed = true
		Tasks.complete("photobomb_star")
	queue_redraw()


func _draw() -> void:
	var dir := vel.normalized()
	var points := PackedVector2Array()
	for i in 10:
		points.append(-dir * i * 14.0)
	draw_polyline(points, Color(Juice.SUN, 0.5), 3.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(1.0, 1.0, 0.9))
	if _bombed:
		# A happy wink for the photo.
		draw_circle(Vector2(-2.5, -1.5), 1.2, Juice.INK)
		draw_line(Vector2(1.3, -2.3), Vector2(3.8, -1.0), Juice.INK, 1.2)
		draw_arc(Vector2(0.5, 1.5), 2.2, 0.4, PI - 0.4, 8, Juice.INK, 1.0, true)
