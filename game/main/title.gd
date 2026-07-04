extends Node2D
## Title screen: gradient dusk, the muon (sprite art), a clear CTA,
## origin/sparks status chips, and a hint bar. U opens the origin shop.

var _t := 0.0
var _started := false

var _muon_tex: Texture2D
var _title_label: Label
var _title_shadow: Label
var _sub_label: Label
var _cta_chip: PanelContainer
var _origin_chip: PanelContainer
var _origin_label: Label
var _sparks_chip: PanelContainer
var _sparks_label: Label
var _hint_chip: PanelContainer
var _histo: Control
var _shop  # untyped: exposes script members (`active`)
var _root: Control


func _ready() -> void:
	_muon_tex = load("res://assets/sprites/muon.svg")
	var ui := CanvasLayer.new()
	ui.layer = 100
	add_child(ui)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_root)

	# Editorial serif italic for the wordmark, offset coral misprint behind.
	_title_shadow = _mk_label("two microseconds", 66, Color(Juice.PINK, 0.75))
	_title_shadow.add_theme_font_override("font", Juice.hand_font)
	_title_label = _mk_label("two microseconds", 66, Juice.CREAM)
	_title_label.add_theme_font_override("font", Juice.hand_font)
	_sub_label = _mk_label("the (brief) life of a muon", 18, Color(Juice.CREAM, 0.8))

	_cta_chip = _mk_chip(Juice.MINT, 0.92)
	var cta_text := "press any key — be born"
	if DisplayServer.is_touchscreen_available():
		cta_text = "tap anywhere — be born"
	var cta := _chip_label(_cta_chip, cta_text, 18)
	cta.add_theme_color_override("font_color", Juice.INK)

	_origin_chip = _mk_chip(Juice.PAPER, 0.88)
	_origin_label = _chip_label(_origin_chip, "", 14)
	_sparks_chip = _mk_chip(Juice.PAPER, 0.88)
	_sparks_label = _chip_label(_sparks_chip, "", 14)
	# Both status chips open the shop when tapped/clicked.
	for chip: PanelContainer in [_origin_chip, _sparks_chip]:
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.gui_input.connect(_on_chip_input)

	_hint_chip = _mk_chip(Juice.INK, 0.4)
	var hint_text := "WASD steer · SPACE zap · TAB to-dos · U origin shop · F fullscreen · M mute"
	if DisplayServer.is_touchscreen_available():
		hint_text = "drag left — steer · tap right — zap · tap a chip for the origin shop"
	var hint := _chip_label(_hint_chip, hint_text, 13)
	hint.add_theme_color_override("font_color", Juice.CREAM)

	_histo = preload("res://game/ui/lifetime_histogram.gd").new()
	_histo.compact = true
	_root.add_child(_histo)

	_shop = preload("res://game/ui/origin_shop.gd").new()
	_root.add_child(_shop)


func _mk_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _mk_chip(bg: Color, alpha: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Juice.ui_chip(bg, alpha))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)
	return panel


func _chip_label(chip: PanelContainer, text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Juice.INK)
	chip.add_child(l)
	return l


func _process(delta: float) -> void:
	_t += delta
	var vp := _root.get_viewport_rect().size
	_title_label.position = Vector2(vp.x * 0.5 - _title_label.size.x * 0.5, vp.y * 0.16)
	_title_label.rotation = -0.015
	# Misregistered print pass: coral copy a few points off-register.
	_title_shadow.position = _title_label.position + Vector2(-3.5, 3.0)
	_title_shadow.rotation = -0.015
	_sub_label.position = Vector2(vp.x * 0.5 - _sub_label.size.x * 0.5, vp.y * 0.16 + 84.0)
	_cta_chip.position = Vector2(vp.x * 0.5 - _cta_chip.size.x * 0.5, vp.y * 0.72)
	_cta_chip.pivot_offset = _cta_chip.size * 0.5
	_cta_chip.scale = Vector2.ONE * (1.0 + 0.03 * sin(_t * 2.6))
	_origin_chip.position = Vector2(16, 12)
	_sparks_chip.position = Vector2(vp.x - _sparks_chip.size.x - 16.0, 12)
	_hint_chip.position = Vector2(vp.x * 0.5 - _hint_chip.size.x * 0.5, vp.y - 46.0)
	_histo.position = Vector2(16.0, vp.y - _histo.size.y - 64.0)
	_histo.visible = Meta.lifetimes.size() > 0
	_histo.queue_redraw()

	var o := Meta.origin()
	_origin_label.text = "origin: %s · E ≈ %s · γ +%.1f" % [o["name"], o["energy"], float(o["gamma"])]
	_sparks_label.text = "sparks %d  ·  U — shop" % Meta.sparks
	queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	# Riso dusk gradient (fine steps: banding is visible at coarse ones).
	var steps := 110
	for i in steps:
		var f := float(i) / steps
		var col := Color("120e22").lerp(Color("53437e"), clampf(f * 1.6, 0.0, 1.0))
		col = col.lerp(Color("e08a5f"), clampf((f - 0.62) * 2.6, 0.0, 1.0))
		draw_rect(Rect2(0, vp.y * f, vp.x, vp.y / steps + 1.0), col)
	# Stars.
	for i in 46:
		var h := absi(hash(i * 7919))
		var pos := Vector2(float(h % 1280) / 1280.0 * vp.x, float((h / 1280) % 520) / 520.0 * vp.y * 0.55)
		var tw := 0.5 + 0.5 * sin(_t * 1.5 + float(h % 100))
		draw_circle(pos, 1.4 + float(h % 3), Color(1, 1, 0.95, 0.6 * tw))
	# A big thin orbit ring behind the muon — poster geometry.
	var center := Vector2(vp.x * 0.5, vp.y * 0.47 + sin(_t * 1.6) * 8.0)
	draw_arc(center, 165.0, 0, TAU, 96, Color(Juice.CREAM, 0.22), 1.5, true)
	draw_arc(center + Vector2(-5, 4), 165.0, 0, TAU, 96, Color(Juice.PINK, 0.20), 1.5, true)
	# The muon: the sprite plus its live minimal face (two ink dashes).
	var size := 190.0
	draw_texture_rect(_muon_tex, Rect2(center - Vector2(size, size) * 0.5, Vector2(size, size)), false)
	var look := Vector2(sin(_t * 0.7) * 6.0, 0.0)
	for side: float in [-1.0, 1.0]:
		var eye := center + Vector2(side * 22.0, -10.0) + look
		draw_rect(Rect2(eye.x - 4.5, eye.y - 11.0, 9.0, 22.0), Juice.INK)
	# The neutrino that got away, on the ring.
	var orbit := center + Vector2(cos(_t * 0.6), sin(_t * 0.6)) * 165.0
	draw_circle(orbit, 6.0, Color(Juice.CREAM, 0.9))
	draw_circle(orbit, 10.0, Color(Juice.PINK, 0.35))


func _on_chip_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and not _started:
		_root.accept_event()
		if _shop != null:
			_shop.toggle()


func _unhandled_input(event: InputEvent) -> void:
	if _started or (_shop != null and _shop.active):
		return
	# Keys with their own jobs shouldn't also start the game.
	var key := event as InputEventKey
	if key != null and key.physical_keycode in [KEY_U, KEY_F, KEY_M, KEY_BACKSPACE, KEY_ESCAPE]:
		return
	var wanted := event is InputEventKey or event is InputEventJoypadButton \
		or event is InputEventMouseButton or event is InputEventScreenTouch
	if wanted and event.is_pressed() and not event.is_echo():
		_started = true
		Sfx.play("task_done", -6.0, 0.0)
		# A tiny beat so the sound lands before the scene swaps.
		get_tree().create_timer(0.25).timeout.connect(Game.start_run)
