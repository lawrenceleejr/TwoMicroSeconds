extends Control
## Both endings: "poof" (decay) and "CLICK." (counted by the detector).

var active := false

var _dim: ColorRect
var _panel: PanelContainer
var _vbox: VBoxContainer
var _deco: Control          # receipt perforation + stamp overlay on the panel
var _deco_mode := ""        # "" or "receipt"
var _perfect := false
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

	# Perforation + inked stamp, drawn over the paper for the receipt look.
	_deco = Control.new()
	_deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_deco.draw.connect(_draw_deco)
	_panel.add_child(_deco)


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


func show_lose(altitude_km: float, depth_m: float, deepest: String,
		run_sparks: int, age_us: float, lab_us: float, peak_g: float) -> void:
	_build_common()
	_perfect = Tasks.all_optional_done()
	_line("poof.", 40, Juice.INK)
	_line("an electron, a neutrino, and an antineutrino carry on.", 15, Color(Juice.INK, 0.7))
	_gap(12)
	# The run, itemized like a printed receipt.
	_line("C O S M I C - R A Y   M U O N   ·   R E C E I P T", 10, Color(Juice.INK, 0.6))
	_dashed_rule()
	_ledger("proper lifetime", "%.2f µs" % age_us, Juice.INK)
	_ledger("lab-frame lifetime", "%.1f µs" % lab_us, Color(Juice.INK, 0.75))
	_ledger("peak γ", "%d×" % int(round(peak_g)), Juice.INK)
	if depth_m > 0.0:
		_ledger("depth reached", "%d m" % int(round(depth_m)), Juice.INK)
	else:
		_ledger("altitude reached", "%d km" % int(round(altitude_km)), Juice.INK)
	if deepest != "":
		_ledger("deepest detector", deepest.split(" · ")[0], Color("2e8b57"))
	_ledger("mischief", "%d / %d" % [Tasks.optional_done_count(), Tasks.optional_total()], Juice.INK)
	_dashed_rule()
	_ledger("sparks earned", "+%d ◆" % run_sparks, Color("ff5c4d"))
	if _perfect:
		_gap(4)
		var stamp := _line("★  A++ MUON  ★", 20, Color("ff5c4d"))
		stamp.add_theme_font_override("font", Juice.hand_font)
	_gap(8)
	_line("your death was logged →", 13, Juice.MINT)
	var histo := preload("res://game/ui/lifetime_histogram.gd").new()
	_vbox.add_child(histo)
	_gap(6)
	var hint := _restart_hint()
	if not Game.is_touch():
		hint += "        U — shop"
	_line(hint, 15, Color(Juice.PERIWINKLE, 1.0))
	_deco_mode = "receipt"
	_pop_in()


## The grand finale: reached LZ, 1.5 km down. The impossible energy, and
## its still-open mystery, revealed as the camera pans up to space.
func show_discovery(age_us: float, lab_us: float) -> void:
	_build_common()
	_line("I M P O S S I B L E .", 40, Color("ffb03a"))
	_line("you reached LZ — deep underground, where no cosmic ray belongs.", 18, Color(Juice.INK, 0.85))
	_line("", 8, Juice.INK)
	_line("you were the Oh-My-God particle. Utah, 1991. 3×10²⁰ eV.", 17, Juice.INK)
	_line("that is ABOVE the GZK limit — an energy theory says", 15, Color(Juice.INK, 0.8))
	_line("shouldn't survive the trip here at all.", 15, Color(Juice.INK, 0.8))
	_line("", 6, Juice.INK)
	_line("where it came from is still unknown.", 16, Color("6a5cff"))
	_line("a nearby source? dark matter? something we haven't named yet?", 15, Color(Juice.INK, 0.8))
	_line("", 6, Juice.INK)
	_line("lived %.2f µs proper · %.1f µs lab frame" % [age_us, lab_us], 14, Color(Juice.INK, 0.7))
	_line("the mystery is still open. thank you for chasing it. <3", 15, Color("e05c6e"))
	_line("", 6, Juice.INK)
	_line(_restart_hint(), 16, Color(Juice.PERIWINKLE, 1.0))
	_pop_in()


## The finale as an epilogue: no boxed panel, the camera rises behind it, and
## each line fades in on its own — one sentence at a time — over ~14 seconds,
## paced to land as the view reaches space. Wistful music is already playing.
func begin_epilogue(age_us: float, lab_us: float) -> void:
	active = true
	visible = true
	_tap_guard = 2.0
	for child in _vbox.get_children():
		child.queue_free()
	# No paper card — the words float over the rising sky.
	_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_dim.color = Color(Juice.INK, 0.0)
	_vbox.add_theme_constant_override("separation", 14)
	var soft := Color(Juice.CREAM, 0.92)
	var lines := [
		["I M P O S S I B L E .", 34, Color("ffce6a")],
		["you reached LZ.", 20, soft],
		["deeper than any cosmic ray has a right to go.", 17, soft],
		["you were the Oh-My-God particle.", 20, Color(Juice.CREAM, 0.96)],
		["Utah, 1991.  3×10²⁰ eV.", 17, soft],
		["above the GZK limit — an energy that shouldn't survive the trip.", 16, soft],
		["where it came from is still unknown.", 18, Color("9bb8ff")],
		["a nearby source?  dark matter?", 16, soft],
		["something we haven't named yet?", 16, soft],
		["you lived %.2f µs of your own time.  %.1f µs of ours." % [age_us, lab_us], 15, Color(Juice.CREAM, 0.75)],
		["the mystery is still open.", 17, Color("ff8f7a")],
		["thank you for chasing it. <3", 16, Color("ff8f7a")],
		[_restart_hint(), 16, Color("cbb8ff")],
	]
	var vw := get_viewport_rect().size.x
	var wrap_w: float = minf(vw - 30.0, 540.0)
	var tw := create_tween().set_ignore_time_scale(true)
	for i in lines.size():
		var l := _epilogue_line(str(lines[i][0]), int(lines[i][1]), lines[i][2], wrap_w)
		tw.parallel().tween_property(l, "modulate:a", 1.0, 1.0).set_delay(1.0 + i * 1.15)


func _epilogue_line(text: String, font_size: int, color: Color, wrap_w: float) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = wrap_w
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Juice.INK)
	l.add_theme_constant_override("outline_size", 6)
	l.modulate.a = 0.0
	_vbox.add_child(l)
	return l


func _build_common() -> void:
	active = true
	visible = true
	_tap_guard = 0.7
	_deco_mode = ""
	_perfect = false
	for child in _vbox.get_children():
		child.queue_free()


func _restart_hint() -> String:
	if Game.is_touch():
		return "tap — again"
	return "R — again        ESC — title"


func _line(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	_vbox.add_child(l)
	return l


func _gap(px: int) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = px
	_vbox.add_child(s)


## A receipt ledger row: label left, value right (bold mono), fixed width.
func _ledger(label_text: String, value_text: String, vcol: Color) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.x = 380.0
	var l := Label.new()
	l.text = label_text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", Juice.ui_font)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(Juice.INK, 0.7))
	var v := Label.new()
	v.text = value_text
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_override("font", Juice.ui_font_bold)
	v.add_theme_font_size_override("font_size", 15)
	v.add_theme_color_override("font_color", vcol)
	row.add_child(l)
	row.add_child(v)
	_vbox.add_child(row)


func _dashed_rule() -> void:
	var l := _line("– – – – – – – – – – – – – – – – – – – –", 12, Color(Juice.INK, 0.35))
	l.clip_text = true
	l.custom_minimum_size.x = 380.0


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


func _draw_deco() -> void:
	if _deco_mode != "receipt":
		return
	# Perforated top edge: notches biting into the paper.
	var w := _deco.size.x
	var nx := 8.0
	while nx < w - 4.0:
		_deco.draw_circle(Vector2(nx, 0.0), 4.0, Color(Juice.INK, 0.55))
		nx += 13.0


func _process(delta: float) -> void:
	if active:
		_tap_guard = maxf(_tap_guard - delta, 0.0)
		_center_panel()
		_deco.queue_redraw()


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
