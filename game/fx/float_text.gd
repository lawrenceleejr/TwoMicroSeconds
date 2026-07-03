extends Node2D
## Small floating text ("+0.2 µs") that rises and fades.

const DUR := 1.2

var text := ""
var color := Color.WHITE

var _t := 0.0


static func spawn(parent: Node, pos: Vector2, msg: String, col: Color) -> void:
	var script: GDScript = load("res://game/fx/float_text.gd")
	var ft: Node2D = script.new()
	ft.position = pos
	ft.text = msg
	ft.color = col
	ft.z_index = 10
	parent.add_child(ft)


func _process(delta: float) -> void:
	_t += delta
	if _t >= DUR:
		queue_free()
		return
	position.y -= 36.0 * delta
	queue_redraw()


func _draw() -> void:
	var k := _t / DUR
	var alpha := 1.0 - k * k
	var font := ThemeDB.fallback_font
	var size := 19
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2(-w * 0.5, 0.0)
	draw_string(font, pos + Vector2(1.5, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Juice.INK, alpha * 0.7))
	var col := color
	col.a = alpha
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
