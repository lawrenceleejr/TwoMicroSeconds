extends Node2D
## The muon's soft white body. Rotated along velocity by the parent;
## squash-and-stretch is applied as a draw transform so pops can layer on top.

var applied_squash := Vector2.ONE
var body_color := Color("fffaf0")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, applied_squash)
	draw_circle(Vector2.ZERO, 17.0, Color(0.27, 0.25, 0.39, 0.18))
	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
