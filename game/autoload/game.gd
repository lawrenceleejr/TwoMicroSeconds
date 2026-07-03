extends Node
## Run flow, input map registration, and a couple of global toggles.

const MAIN_SCENE := "res://game/main/main.tscn"
const TITLE_SCENE := "res://game/main/title.tscn"

var run_start_msec := 0


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()


func start_run() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)


func to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func mark_run_start() -> void:
	run_start_msec = Time.get_ticks_msec()


func real_elapsed() -> float:
	return float(Time.get_ticks_msec() - run_start_msec) / 1000.0


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.physical_keycode == KEY_F:
			_toggle_fullscreen()
		elif key.physical_keycode == KEY_M:
			var bus := AudioServer.get_bus_index("Master")
			AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))


func _toggle_fullscreen() -> void:
	var win := get_window()
	if win.mode == Window.MODE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
	else:
		win.mode = Window.MODE_FULLSCREEN


func _register_inputs() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_add_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_add_action("move_up", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_add_action("move_down", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_add_action("dash", [KEY_SPACE, KEY_SHIFT], [JOY_BUTTON_A], [])
	_add_action("zap", [KEY_Z, KEY_X], [JOY_BUTTON_X], [])
	_add_action("toggle_checklist", [KEY_TAB], [JOY_BUTTON_Y], [])
	_add_action("restart", [KEY_R], [JOY_BUTTON_START], [])
	# Mouse click also zaps.
	var mouse_ev := InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("zap", mouse_ev)


func _add_action(action_name: String, keys: Array, buttons: Array, axes: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name, 0.25)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action_name, ev)
	for b in buttons:
		var ev_btn := InputEventJoypadButton.new()
		ev_btn.button_index = b
		InputMap.action_add_event(action_name, ev_btn)
	for ax in axes:
		var ev_ax := InputEventJoypadMotion.new()
		ev_ax.axis = ax[0]
		ev_ax.axis_value = ax[1]
		InputMap.action_add_event(action_name, ev_ax)
