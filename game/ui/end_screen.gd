extends Control
## Both endings: "poof" (decay) and "CLICK." (counted by the detector).

var active := false

var _dim: ColorRect
var _panel: PanelContainer
var _vbox: VBoxContainer
# Small grace period so the tap that ended the run can't instantly restart.
var _tap_guard := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(Juice.INK, 0.0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	_panel = PanelContainer.new()
	var sb := Juice.ui_panel(Juice.PAPER, 1.0, 16)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(_vbox)


func show_win(run_sparks: int, omg: bool, age_us: float, lab_us: float) -> void:
	_build_common()
	if omg:
		_line("C L I C K .", 44, Color("b8860b"))
		_line("the detector needed a moment.", 22, Color(Juice.INK, 0.8))
	else:
		_line("CLICK.", 44, Juice.INK)
		_line("counted.", 22, Color(Juice.INK, 0.8))
	_line("", 8, Juice.INK)
	_line("lived %.2f µs proper · %.1f µs lab frame · mischief %d/%d" % [
		age_us, lab_us, Tasks.optional_done_count(), Tasks.optional_total()], 16, Juice.INK)
	_line("sparks +%d  ·  wallet %d" % [run_sparks, Meta.sparks], 16, Juice.PERIWINKLE)
	if Tasks.all_optional_done():
		_line("A++ MUON — the front desk is framing this.", 16, Color("e05c6e"))
	if omg:
		_line("", 8, Juice.INK)
		_line("Utah, 1991. they saw the shower you fell from and said 'oh my god'.", 14, Color(Juice.INK, 0.75))
		_line("you've been every ray the sky makes. thank you for playing <3", 14, Color("e05c6e"))
	_line("", 4, Juice.INK)
	var histo := preload("res://game/ui/lifetime_histogram.gd").new()
	_vbox.add_child(histo)
	_line("", 4, Juice.INK)
	_line(_restart_hint(), 16, Color(Juice.PERIWINKLE, 1.0))
	_pop_in()


func show_lose(altitude_km: float, run_sparks: int, age_us: float, lab_us: float) -> void:
	_build_common()
	_line("poof.", 44, Juice.INK)
	_line("an electron, a neutrino, and an antineutrino carry on.", 20, Color(Juice.INK, 0.8))
	_line("", 8, Juice.INK)
	_line("lived %.2f µs proper · %.1f µs lab frame · made it to %d km" % [
		age_us, lab_us, int(round(altitude_km))], 16, Juice.INK)
	_line("mischief %d/%d" % [Tasks.optional_done_count(), Tasks.optional_total()], 16, Juice.INK)
	if run_sparks > 0:
		_line("sparks +%d  ·  wallet %d" % [run_sparks, Meta.sparks], 16, Juice.PERIWINKLE)
	_line("", 4, Juice.INK)
	var histo := preload("res://game/ui/lifetime_histogram.gd").new()
	_vbox.add_child(histo)
	_line("", 4, Juice.INK)
	_line("find more field. come back heavier.", 14, Color(Juice.INK, 0.65))
	_line("", 8, Juice.INK)
	var hint := _restart_hint()
	if not DisplayServer.is_touchscreen_available():
		hint += "  (U — shop)"
	_line(hint, 16, Color(Juice.PERIWINKLE, 1.0))
	_pop_in()


func _build_common() -> void:
	active = true
	visible = true
	_tap_guard = 0.7
	for child in _vbox.get_children():
		child.queue_free()


func _restart_hint() -> String:
	if DisplayServer.is_touchscreen_available():
		return "tap — again"
	return "R — again        ESC — title"


func _line(text: String, font_size: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	_vbox.add_child(l)


func _pop_in() -> void:
	var tw := create_tween()
	tw.tween_property(_dim, "color:a", 0.45, 0.4)
	_center_panel()
	_panel.scale = Vector2(0.7, 0.7)
	var tw2 := create_tween()
	tw2.tween_property(_panel, "scale", Vector2.ONE, 0.5) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _center_panel() -> void:
	_panel.reset_size()
	var vp := get_viewport_rect().size
	_panel.position = (vp - _panel.size) * 0.5
	_panel.pivot_offset = _panel.size * 0.5


func _process(delta: float) -> void:
	if active:
		_tap_guard = maxf(_tap_guard - delta, 0.0)
		_center_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	# Tap / click restarts (touches arrive as emulated mouse buttons).
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _tap_guard <= 0.0:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.to_title()
