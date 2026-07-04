extends Control
## Esc pauses. The universe can wait.

var can_pause := true

var _label: Label
var _sub: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(Juice.INK, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_label = Label.new()
	_label.text = "paused"
	_label.add_theme_font_override("font", Juice.hand_font)
	_label.add_theme_font_size_override("font_size", 44)
	_label.add_theme_color_override("font_color", Juice.CREAM)
	add_child(_label)

	_sub = Label.new()
	_sub.text = "(the universe can wait)      ESC — resume · T — give up, go to title"
	_sub.add_theme_font_size_override("font_size", 16)
	_sub.add_theme_color_override("font_color", Color(Juice.CREAM, 0.8))
	add_child(_sub)


func _process(_delta: float) -> void:
	if not visible:
		return
	var vp := get_viewport_rect().size
	_label.position = Vector2(vp.x * 0.5 - _label.size.x * 0.5, vp.y * 0.42)
	_sub.position = Vector2(vp.x * 0.5 - _sub.size.x * 0.5, vp.y * 0.42 + 56.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and can_pause:
		get_viewport().set_input_as_handled()
		var tree := get_tree()
		tree.paused = not tree.paused
		visible = tree.paused
		Sfx.play("pop", -8.0)
		return
	var key := event as InputEventKey
	if visible and key != null and key.pressed and key.physical_keycode == KEY_T:
		get_viewport().set_input_as_handled()
		Game.to_title()
		return
	# Tap anywhere resumes (touch devices have no ESC).
	var mb := event as InputEventMouseButton
	if visible and mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		visible = false
		Sfx.play("pop", -8.0)
