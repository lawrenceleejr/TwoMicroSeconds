extends Control
## Touchscreen control: STEERING ONLY. Hold anywhere and slide left/right;
## how far from center you hold sets how hard the fall angles that way.
## No taps, no zap button (the muon auto-zaps what it passes), no vertical
## control (a muon only falls). Inert when there's no touchscreen.

var _steer_id := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Game.is_touch():
		visible = false
		set_process_input(false)
		set_process(false)


func _exit_tree() -> void:
	Game.touch_steer_x = 0.0


func _steer_from(x: float) -> void:
	# Proportional to horizontal distance from screen center: the edges
	# are full lock, the middle is a dead-ahead dive.
	var w := get_viewport_rect().size.x
	Game.touch_steer_x = clampf((x - w * 0.5) / (w * 0.34), -1.0, 1.0)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			# A tap on the menu button opens the pause menu (no ESC on touch).
			var menu := get_tree().get_first_node_in_group("menu_button")
			if menu != null and menu.wants_touch(event.position):
				get_viewport().set_input_as_handled()
				menu.press_menu()
				return
			# A tap on the to-do note (or its tucked grab-tab) toggles the
			# list and must NOT also begin a steer — this is the only route
			# to reopen it on touch, since there is no keyboard.
			var cl := get_tree().get_first_node_in_group("checklist")
			if cl != null and cl.wants_touch(event.position):
				get_viewport().set_input_as_handled()
				cl.toggle_from_touch()
				return
			if _steer_id == -1:
				_steer_id = event.index
			_steer_from(event.position.x)
			queue_redraw()
		elif event.index == _steer_id:
			_steer_id = -1
			Game.touch_steer_x = 0.0
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _steer_id:
		_steer_from(event.position.x)
		queue_redraw()


func _draw() -> void:
	if _steer_id == -1:
		return
	# A slim steering bar along the bottom, with the current lock marked.
	var vp := get_viewport_rect().size
	var y := vp.y - 34.0
	draw_line(Vector2(vp.x * 0.16, y), Vector2(vp.x * 0.84, y), Color(1, 1, 1, 0.14), 4.0)
	var cx := vp.x * 0.5 + Game.touch_steer_x * (vp.x * 0.34)
	draw_circle(Vector2(cx, y), 16.0, Color(1, 1, 1, 0.32))
	draw_circle(Vector2(vp.x * 0.5, y), 3.0, Color(1, 1, 1, 0.25))
