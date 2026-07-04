extends Node2D
## Anime-style speed streaks, parented to the camera. `intensity` 0..1.

var intensity := 0.0
var dir := Vector2.DOWN

var _t := 0.0


func _ready() -> void:
	z_index = 50


func _process(delta: float) -> void:
	_t += delta
	visible = intensity > 0.04
	if visible:
		queue_redraw()


func _draw() -> void:
	if intensity <= 0.04:
		return
	var vp := get_viewport_rect().size
	var perp := dir.orthogonal()
	for i in 20:
		var h := absi(hash(i * 733 + int(_t * 16.0)))
		var off := (float(h % 1000) / 1000.0 - 0.5) * vp.y * 1.25
		var along := (float((h / 1000) % 1000) / 1000.0 - 0.5) * vp.x * 1.1
		var base := perp * off + dir * along
		var streak_len := (70.0 + float(h % 150)) * intensity
		draw_line(base - dir * streak_len * 0.5, base + dir * streak_len * 0.5,
			Color(1.0, 1.0, 1.0, 0.15 * intensity), 2.5, true)
