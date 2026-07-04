extends Control
## Both endings: "poof" (decay) and "CLICK." (counted by the detector).

var active := false

var _dim: ColorRect
var _panel: PanelContainer
var _vbox: VBoxContainer


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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Juice.PAPER
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 26
	sb.content_margin_bottom = 26
	sb.shadow_color = Color(Juice.INK, 0.3)
	sb.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(_vbox)


func show_win(run_sparks: int, omg: bool) -> void:
	_build_common()
	if omg:
		_line("C L I C K .", 44, Color("b8860b"))
		_line("the detector needed a moment.", 22, Color(Juice.INK, 0.8))
	else:
		_line("CLICK.", 44, Juice.INK)
		_line("you were counted.", 22, Color(Juice.INK, 0.8))
	_line("", 8, Juice.INK)
	_line("· MUON OBSERVATORY · visitor receipt ·", 14, Color(Juice.INK, 0.6))
	_line("proper time aboard:  2.2 µs", 16, Juice.INK)
	_line("earth time elapsed:  %.1f s" % Game.real_elapsed(), 16, Juice.INK)
	_line("mischief managed:  %d / %d" % [Tasks.optional_done_count(), Tasks.optional_total()], 16, Juice.INK)
	_line("sparks earned:  +%d  (wallet: %d)" % [run_sparks, Meta.sparks], 16, Juice.PERIWINKLE)
	if Tasks.all_optional_done():
		_line("rating:  A++ MUON. the detector is framing this.", 16, Color("e05c6e"))
	_line("", 8, Juice.INK)
	if omg:
		_line("3×10²⁰ eV. Utah saw one of you in 1991 and said 'oh my god'.", 14, Color(Juice.INK, 0.75))
		_line("you have now been every ray the sky knows how to make.", 14, Color(Juice.INK, 0.75))
		_line("thank you for playing <3", 14, Color("e05c6e"))
	else:
		_line("real muons reach the ground because time dilates.", 14, Color(Juice.INK, 0.65))
		_line("you just proved it. congratulations.", 14, Color(Juice.INK, 0.65))
	_line("", 8, Juice.INK)
	_line("R — another life        ESC — title (origin shop: U)", 16, Color(Juice.PERIWINKLE, 1.0))
	_pop_in()


func show_lose(altitude_km: float, run_sparks: int) -> void:
	_build_common()
	_line("poof.", 44, Juice.INK)
	_line("you decayed into an electron and two neutrinos.", 20, Color(Juice.INK, 0.8))
	_line("(they seem nice.)", 14, Color(Juice.INK, 0.55))
	_line("", 8, Juice.INK)
	_line("altitude reached:  %d km" % int(round(altitude_km)), 16, Juice.INK)
	_line("mischief managed:  %d / %d" % [Tasks.optional_done_count(), Tasks.optional_total()], 16, Juice.INK)
	if run_sparks > 0:
		_line("sparks kept:  +%d  (wallet: %d)" % [run_sparks, Meta.sparks], 16, Juice.PERIWINKLE)
	_line("", 8, Juice.INK)
	_line("tip: speed dilates time. a fast muon is a young muon.", 14, Color(Juice.INK, 0.65))
	_line("(a better origin story helps too — press U on the title.)", 14, Color(Juice.INK, 0.55))
	_line("", 8, Juice.INK)
	_line("R — be born again        ESC — title", 16, Color(Juice.PERIWINKLE, 1.0))
	_pop_in()


func _build_common() -> void:
	active = true
	visible = true
	for child in _vbox.get_children():
		child.queue_free()


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


func _process(_delta: float) -> void:
	if active:
		_center_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("restart"):
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.to_title()
