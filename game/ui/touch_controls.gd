extends Control
## Touchscreen control: hold anywhere and slide left/right to steer (how far
## from centre you hold sets the lock). A quick tap is a manual zap — the
## "honk" stays in your hands, even though the muon also auto-zaps. A tinted
## thumb-zone shows the steering pad until you've used it. Inert on desktop.

var _steer_id := -1
var _press_ms := 0
var _press_pos := Vector2.ZERO
var _moved := 0.0
var _has_steered := false
var _hint_a := 1.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Game.is_touch():
		visible = false
		set_process_input(false)
		set_process(false)


func _exit_tree() -> void:
	Game.touch_steer_x = 0.0


func _process(delta: float) -> void:
	# The steering-pad hint fades out for good once you've actually steered.
	if _has_steered and _hint_a > 0.0:
		_hint_a = maxf(_hint_a - delta * 0.9, 0.0)
		queue_redraw()


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
				_press_ms = Time.get_ticks_msec()
				_press_pos = event.position
				_moved = 0.0
			_steer_from(event.position.x)
			queue_redraw()
		elif event.index == _steer_id:
			# A quick, barely-moved press was a tap → fire a manual zap.
			var dur := Time.get_ticks_msec() - _press_ms
			if _moved < 18.0 and dur < 240:
				var m := get_tree().get_first_node_in_group("muon")
				if m != null and m.has_method("_zap"):
					m.call("_zap")
			_steer_id = -1
			Game.touch_steer_x = 0.0
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _steer_id:
		_moved = maxf(_moved, event.position.distance_to(_press_pos))
		if _moved > 18.0:
			_has_steered = true
		_steer_from(event.position.x)
		queue_redraw()


func _draw() -> void:
	var vp := get_viewport_rect().size
	# Thumb-zone affordance: the bottom third is the steering pad. Fades once
	# you've steered, so it teaches without lingering.
	if _hint_a > 0.01:
		var zt := vp.y * 0.66
		draw_rect(Rect2(0, zt, vp.x, vp.y - zt), Color(Juice.MINT, 0.05 * _hint_a))
		var dx := 0.0
		while dx < vp.x:
			draw_line(Vector2(dx, zt), Vector2(dx + 14.0, zt), Color(Juice.MINT, 0.45 * _hint_a), 2.0)
			dx += 26.0
		var font := ThemeDB.fallback_font
		var t1 := "◂   HOLD & SLIDE TO STEER   ▸"
		var t1w := font.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(vp.x * 0.5 - t1w * 0.5, zt + 28.0), t1,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.55 * _hint_a))
		var t2 := "auto-zaps · tap = manual zap"
		var t2w := font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(font, Vector2(vp.x * 0.5 - t2w * 0.5, zt + 48.0), t2,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.4 * _hint_a))

	# Live steering marker while a hold is active.
	if _steer_id != -1:
		var y := vp.y - 34.0
		draw_line(Vector2(vp.x * 0.16, y), Vector2(vp.x * 0.84, y), Color(1, 1, 1, 0.14), 4.0)
		var cx := vp.x * 0.5 + Game.touch_steer_x * (vp.x * 0.34)
		draw_circle(Vector2(cx, y), 16.0, Color(1, 1, 1, 0.32))
		draw_circle(Vector2(vp.x * 0.5, y), 3.0, Color(1, 1, 1, 0.25))
