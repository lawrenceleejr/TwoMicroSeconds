extends Control
## Pause / menu. ESC or the on-screen menu button opens it; from here you
## can resume or give up and go back to the title. Every option is reachable
## by touch (phones have no ESC / T keys).

var can_pause := true

var _label: Label
var _sub: Label
var _resume_chip: PanelContainer
var _title_chip: PanelContainer
var _tasks: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Juice.INK, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_label = Label.new()
	_label.text = "paused"
	_label.add_theme_font_override("font", Juice.hand_font)
	_label.add_theme_font_size_override("font_size", 44)
	_label.add_theme_color_override("font_color", Juice.CREAM)
	add_child(_label)

	_sub = Label.new()
	_sub.text = "the universe can wait"
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(Juice.CREAM, 0.8))
	add_child(_sub)

	# The to-do list, shown here so it's reachable on a vertical phone (where
	# the pinned note is hidden). It's a read-out — progress, not a target.
	_tasks = Control.new()
	_tasks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks.draw.connect(_draw_tasks)
	add_child(_tasks)

	_resume_chip = _mk_chip("▸ resume", Juice.MINT)
	_title_chip = _mk_chip("give up — back to title", Juice.PAPER)


func _mk_chip(text: String, bg: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Juice.ui_chip(bg, 0.94))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Juice.ui_font)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Juice.INK)
	panel.add_child(l)
	add_child(panel)
	return panel


## Open the menu (called by the HUD's menu button, and mirrors ESC).
func open() -> void:
	if get_tree().paused:
		return
	get_tree().paused = true
	visible = true
	Sfx.play("pop", -8.0)


func _resume() -> void:
	get_tree().paused = false
	visible = false
	Sfx.play("pop", -8.0)


func _process(_delta: float) -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	var cx := vp.x * 0.5
	var top := vp.y * 0.09
	_label.position = Vector2(cx - _label.size.x * 0.5, top)
	_sub.position = Vector2(cx - _sub.size.x * 0.5, top + 52.0)
	var tw: float = minf(vp.x - 48.0, 360.0)
	var th: float = 54.0 + Tasks.DEFS.size() * 22.0 + 20.0
	_tasks.size = Vector2(tw, th)
	_tasks.position = Vector2(cx - tw * 0.5, top + 92.0)
	_tasks.queue_redraw()
	_resume_chip.position = Vector2(cx - _resume_chip.size.x * 0.5, vp.y - 150.0)
	_title_chip.position = Vector2(cx - _title_chip.size.x * 0.5, vp.y - 98.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and can_pause:
		get_viewport().set_input_as_handled()
		var tree := get_tree()
		tree.paused = not tree.paused
		visible = tree.paused
		Sfx.play("pop", -8.0)
		return
	if not visible:
		return
	# Desktop shortcut: T gives up to the title.
	var key := event as InputEventKey
	if key != null and key.pressed and key.physical_keycode == KEY_T:
		get_viewport().set_input_as_handled()
		_give_up()
		return
	# A press on a chip fires it; a press anywhere else resumes.
	var pos := _press_pos(event)
	if pos.x < 0.0:
		return
	get_viewport().set_input_as_handled()
	if _hits(_title_chip, pos):
		_give_up()
	else:
		_resume()


func _give_up() -> void:
	get_tree().paused = false
	Game.to_title()


## Screen-space position of a fresh press (mouse or touch), or (-1,-1).
func _press_pos(event: InputEvent) -> Vector2:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		return mb.position
	var st := event as InputEventScreenTouch
	if st != null and st.pressed:
		return st.position
	return Vector2(-1.0, -1.0)


func _draw_tasks() -> void:
	var w := _tasks.size.x
	var h := _tasks.size.y
	var sb := Juice.ui_panel(Juice.PAPER, 0.96, 12)
	sb.draw(_tasks.get_canvas_item(), Rect2(Vector2.ZERO, Vector2(w, h)))
	var font: Font = Juice.hand_font
	_tasks.draw_string(font, Vector2(16, 26), "to-do", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Juice.INK)
	_tasks.draw_string(font, Vector2(78, 26), "(mischief optional)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Juice.INK, 0.55))
	_tasks.draw_line(Vector2(14, 34), Vector2(w - 14, 34), Color(Juice.INK, 0.25), 1.5)
	for i in Tasks.DEFS.size():
		var d: Dictionary = Tasks.DEFS[i]
		var id: String = d["id"]
		var y := 54.0 + i * 22.0
		var done: bool = Tasks.is_done(id)
		_tasks.draw_rect(Rect2(16, y - 11, 14, 14), Color(Juice.INK, 0.6), false, 1.6)
		if done:
			_tasks.draw_rect(Rect2(17.5, y - 9.5, 11, 11), Color(Juice.MINT, 0.9))
		var col := Color(Juice.INK, 0.4) if done else Juice.INK
		_tasks.draw_string(font, Vector2(38, y), d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	_tasks.draw_string(font, Vector2(16, h - 12),
		"%d / %d" % [Tasks.optional_done_count(), Tasks.optional_total()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.INK, 0.7))


func _hits(chip: Control, screen_pos: Vector2) -> bool:
	var local: Vector2 = chip.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return Rect2(Vector2.ZERO, chip.size).grow(8.0).has_point(local)
