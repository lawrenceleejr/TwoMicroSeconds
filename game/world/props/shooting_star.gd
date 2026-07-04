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
		# Camera flash: a hard four-point glint for the photo.
		for ang: float in [0.0, PI * 0.5]:
			var dir2 := Vector2.from_angle(ang)
			draw_line(-dir2 * 13.0, dir2 * 13.0, Color(Juice.CREAM, 0.95), 1.6, true)
		draw_circle(Vector2.ZERO, 3.0, Juice.PINK)
