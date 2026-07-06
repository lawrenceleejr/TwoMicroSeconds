extends Control
## Pause / menu. ESC or the on-screen menu button opens it; from here you
## can resume or give up and go back to the title. Every option is reachable
## by touch (phones have no ESC / T keys).

var can_pause := true

var _label: Label
var _sub: Label
var _resume_chip: PanelContainer
var _title_chip: PanelContainer


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
	var top := vp.y * 0.34
	_label.position = Vector2(cx - _label.size.x * 0.5, top)
	_sub.position = Vector2(cx - _sub.size.x * 0.5, top + 54.0)
	_resume_chip.position = Vector2(cx - _resume_chip.size.x * 0.5, top + 104.0)
	_title_chip.position = Vector2(cx - _title_chip.size.x * 0.5, top + 156.0)


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


func _hits(chip: Control, screen_pos: Vector2) -> bool:
	var local: Vector2 = chip.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return Rect2(Vector2.ZERO, chip.size).grow(8.0).has_point(local)
