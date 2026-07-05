extends Control
## Touchscreen controls (web/mobile): drag anywhere on the left side to
## steer with a floating joystick; tap the right side to zap. Hidden and
## inert when no touchscreen exists.

const STICK_RADIUS := 70.0

var _steer_id := -1
var _anchor := Vector2.ZERO
var _vec := Vector2.ZERO
var _zap_pressed := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Game.is_touch():
		visible = false
		set_process_input(false)
		set_process(false)


func _exit_tree() -> void:
	# Never leave a stale steer vector behind on scene changes mid-drag.
	Game.touch_steer = Vector2.ZERO
	if _zap_pressed:
		Input.action_release("zap")


func _process(_delta: float) -> void:
	# Release the zap action one frame after the tap so
	# is_action_just_pressed fires exactly once.
	if _zap_pressed:
		_zap_pressed = false
		Input.action_release("zap")


func _input(event: InputEvent) -> void:
	# Something above us (the to-do note's tap target) took this touch.
	if get_viewport().is_input_handled():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			# The to-do note owns its tab/body: a tap there toggles the
			# list and is NOT a zap. touch_controls is the single router
			# for touches, so there's no ordering ambiguity.
			var note := get_tree().get_first_node_in_group("checklist")
			if note != null and note.wants_touch(event.position):
				note.toggle_from_touch()
				get_viewport().set_input_as_handled()
				return
			if event.position.x < get_viewport_rect().size.x * 0.55 and _steer_id == -1:
				_steer_id = event.index
				_anchor = event.position
				_vec = Vector2.ZERO
			else:
				Input.action_press("zap")
				_zap_pressed = true
		elif event.index == _steer_id:
			_steer_id = -1
			_vec = Vector2.ZERO
			Game.touch_steer = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _steer_id:
		_vec = ((event.position - _anchor) / STICK_RADIUS).limit_length(1.0)
		Game.touch_steer = _vec
		queue_redraw()


func _draw() -> void:
	if _steer_id == -1:
		return
	draw_circle(_anchor, STICK_RADIUS, Color(1, 1, 1, 0.10))
	draw_arc(_anchor, STICK_RADIUS, 0, TAU, 40, Color(1, 1, 1, 0.30), 2.0, true)
	draw_circle(_anchor + _vec * (STICK_RADIUS - 16.0), 22.0, Color(1, 1, 1, 0.35))
