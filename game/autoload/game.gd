extends Node
## Run flow, input map registration, and a couple of global toggles.

const MAIN_SCENE := "res://game/main/stage.tscn"
const TITLE_SCENE := "res://game/main/title.tscn"

var run_start_msec := 0
## Steering vector from the on-screen touch joystick (zero = none).
var touch_steer := Vector2.ZERO
## Set by the 3D stage before it instances the world: the atmosphere then
## splits itself across the stage's real depth planes (sky/world/near haze).
var stage_planes := false


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()


var shoot_mode := false
## Forced by `-- --touch` so CI can audit the touch/phone UI without a
## real touchscreen.
var fake_touch := false


## The single source of truth for "is this a touch device": everything
## that adapts to phones asks here.
func is_touch() -> bool:
	return fake_touch or DisplayServer.is_touchscreen_available()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	fake_touch = "--touch" in args
	_apply_ui_scale()
	get_window().size_changed.connect(_apply_ui_scale)
	if "--shoot" in args:
		# Screenshot mode: a director drives the game through scripted
		# moments and saves PNGs (used by CI for the visual feedback loop).
		shoot_mode = true
		seed(7)
		add_child(load("res://game/dev/shot_director.gd").new())
	elif "--smoke" in args:
		# CI smoke test: boot straight into a run so the whole gameplay
		# stack (muon, props, HUD) gets exercised headlessly.
		start_run.call_deferred()


## Where the muon sits on the real screen (root-canvas px), published by
## the 3D stage each frame so UI panels can duck out of its way.
var muon_screen_pos := Vector2(-1e6, -1e6)


func _apply_ui_scale() -> void:
	# A 720-unit-tall canvas maps to a few centimeters of glass on a phone;
	# scale the whole UI up on touch screens (portrait gets a bit more).
	# The 3D world renders at full window resolution either way.
	var win := get_window()
	var f := 1.0
	if is_touch():
		f = 1.55
		if win.size.y > win.size.x:
			f = 2.0
	win.content_scale_factor = f


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
	# No throttle: a muon can't accelerate itself. Steering + zap only.
	# (No mouse binding: on touch devices taps are routed by TouchControls,
	# and emulated clicks from steering touches must not fire zaps.)
	_add_action("zap", [KEY_Z, KEY_X, KEY_SPACE], [JOY_BUTTON_X, JOY_BUTTON_A], [])
	_add_action("toggle_checklist", [KEY_TAB], [JOY_BUTTON_Y], [])
	_add_action("restart", [KEY_R], [JOY_BUTTON_START], [])


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
