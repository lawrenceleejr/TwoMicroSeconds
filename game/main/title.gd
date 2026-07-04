extends Node2D
## Title screen: a bobbing muon, a soft gradient, and one instruction.

var _t := 0.0
var _started := false

var _press_label: Label
var _origin_label: Label
var _shop  # untyped: exposes script members (`active`)


func _ready() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	_add_label(root, "two microseconds", 64, Juice.CREAM, 0.30)
	_add_label(root, "the (brief) life of a muon", 22, Color(Juice.CREAM, 0.85), 0.42)
	_origin_label = _add_label(root, "", 15, Juice.MINT, 0.52)
	_press_label = _add_label(root, "press any key to be born", 19, Juice.SUN, 0.68)
	_add_label(root, "U — origin shop", 15, Color(Juice.CREAM, 0.8), 0.76)
	_add_label(root, "WASD / stick — move      SPACE — zip      Z — zap      TAB — to-do list", 15, Color(Juice.CREAM, 0.7), 0.88)
	_add_label(root, "F — fullscreen · M — mute", 12, Color(Juice.CREAM, 0.45), 0.94)

	_shop = preload("res://game/ui/origin_shop.gd").new()
	root.add_child(_shop)


func _add_label(parent: Control, text: String, font_size: int, color: Color, y_frac: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Juice.INK)
	l.add_theme_constant_override("outline_size", 6)
	l.set_meta("y_frac", y_frac)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _process(delta: float) -> void:
	_t += delta
	# Keep labels centered at their fractions (handles resize).
	for ui in get_children():
		if ui is CanvasLayer:
			for root in ui.get_children():
				var vp: Vector2 = root.get_viewport_rect().size
				for l in root.get_children():
					if l is Label and l.has_meta("y_frac"):
						l.position = Vector2(vp.x * 0.5 - l.size.x * 0.5, vp.y * l.get_meta("y_frac"))
	if _press_label != null:
		_press_label.modulate.a = 0.6 + 0.4 * sin(_t * 3.0)
	if _origin_label != null:
		var o := Meta.origin()
		_origin_label.text = "origin: %s · E ≈ %s · γ +%.1f      sparks: %d" % [
			o["name"], o["energy"], float(o["gamma"]), Meta.sparks
		]
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	# Sky gradient.
	var steps := 24
	for i in steps:
		var f := float(i) / steps
		var col := Color("14142e").lerp(Color("5b5f97"), clampf(f * 1.6, 0.0, 1.0))
		col = col.lerp(Color("ffc2d1"), clampf((f - 0.62) * 2.6, 0.0, 1.0))
		draw_rect(Rect2(0, vp.y * f, vp.x, vp.y / steps + 1.0), col)
	# Stars.
	for i in 40:
		var h := absi(hash(i * 7919))
		var pos := Vector2(float(h % 1280) / 1280.0 * vp.x, float((h / 1280) % 500) / 500.0 * vp.y * 0.55)
		var tw := 0.5 + 0.5 * sin(_t * 1.5 + float(h % 100))
		draw_circle(pos, 1.4 + float(h % 3), Color(1, 1, 0.95, 0.6 * tw))
	# The muon, bobbing happily.
	var center := Vector2(vp.x * 0.5, vp.y * 0.55 + sin(_t * 1.6) * 10.0)
	draw_circle(center, 62.0, Color(0.27, 0.25, 0.39, 0.15))
	draw_circle(center, 58.0, Juice.PAPER)
	var look := Vector2(sin(_t * 0.7) * 6.0, 0.0)
	draw_circle(center + Vector2(-20, -10) + look, 9.0, Juice.INK)
	draw_circle(center + Vector2(20, -10) + look, 9.0, Juice.INK)
	draw_circle(center + Vector2(-34, 12), 12.0, Color(Juice.BLUSH, 0.85))
	draw_circle(center + Vector2(34, 12), 12.0, Color(Juice.BLUSH, 0.85))
	draw_arc(center + Vector2(0, 10) + look * 0.5, 15.0, 0.5, PI - 0.5, 12, Juice.INK, 4.0, true)
	draw_circle(center + Vector2(0, 74), 20.0, Juice.MINT)
	draw_line(center + Vector2(-10, 74), center + Vector2(10, 74), Juice.INK, 5.0)
	# A tiny orbiting neutrino friend.
	var orbit := center + Vector2(cos(_t * 1.2), sin(_t * 1.2) * 0.5) * 110.0
	draw_arc(orbit, 8.0, 0, TAU, 16, Color(1, 1, 1, 0.5), 1.5, true)
	draw_circle(orbit + Vector2(-2.5, -1), 1.2, Color(Juice.INK, 0.6))
	draw_circle(orbit + Vector2(2.5, -1), 1.2, Color(Juice.INK, 0.6))


func _unhandled_input(event: InputEvent) -> void:
	if _started or (_shop != null and _shop.active):
		return
	# Keys with their own jobs shouldn't also start the game.
	var key := event as InputEventKey
	if key != null and key.physical_keycode in [KEY_U, KEY_F, KEY_M, KEY_BACKSPACE, KEY_ESCAPE]:
		return
	var wanted := event is InputEventKey or event is InputEventJoypadButton \
		or event is InputEventMouseButton
	if wanted and event.is_pressed() and not event.is_echo():
		_started = true
		Sfx.play("task_done", -6.0, 0.0)
		# A tiny beat so the sound lands before the scene swaps.
		get_tree().create_timer(0.25).timeout.connect(Game.start_run)
