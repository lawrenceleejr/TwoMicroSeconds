extends Control
## First-run onboarding: three diegetic beats that annotate the live fall.
## Show, don't gate — the sim never pauses, each line fades in on its trigger,
## holds a few seconds, and gets out of the way. Once all three have played,
## the flag persists (Meta.seen_intro) and they never appear again. Dying
## mid-intro just replays the remaining beats next run.

const BEATS := [
	{
		"text": "you're falling. steer left & right — you can't stop.",
		"col": Color("ffb03a"),
	},
	{
		"text": "faster ≠ slower clock — it shrinks the sky instead.",
		"col": Color("3ecfb2"),
	},
	{
		"text": "reach the detectors before your ~2.2 µs runs out.",
		"col": Color("ff8073"),
	},
]
const HOLD := 3.6

var _stage := 0          # next beat to fire
var _showing := -1       # beat on screen, or -1
var _hold := 0.0
var _since_last := 0.0   # fallback timer so beat 2 fires even without a boost
var _boost_seen := false
var _hooked := false
var _label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.add_theme_font_override("font", Juice.hand_font)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_outline_color", Juice.INK)
	_label.add_theme_constant_override("outline_size", 8)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate.a = 0.0
	add_child(_label)


func _process(delta: float) -> void:
	var m := get_tree().get_first_node_in_group("muon")
	if m == null:
		return
	if not _hooked:
		_hooked = true
		m.connect("boosted", func(_amount: float, _source: String) -> void:
			_boost_seen = true)

	# Layout: centered, clear of the clock cluster and the toast line.
	var vp := get_viewport_rect().size
	var w := minf(vp.x - 40.0, 560.0)
	_label.custom_minimum_size.x = w
	_label.size.x = w
	_label.position = Vector2((vp.x - w) * 0.5, vp.y * 0.30)

	if _showing >= 0:
		_hold -= delta
		var target_a := 1.0 if _hold > 0.7 else 0.0
		_label.modulate.a = lerpf(_label.modulate.a, target_a, 1.0 - exp(-6.0 * delta))
		if _hold <= 0.0 and _label.modulate.a < 0.05:
			_showing = -1
			_since_last = 0.0
			if _stage >= BEATS.size():
				Meta.mark_intro_seen()
				queue_free()
		return

	# Between beats: wait for the next trigger.
	if not bool(m.get("alive")):
		queue_free()   # died mid-intro; remaining beats replay next run
		return
	_since_last += delta
	var fire := false
	match _stage:
		0:
			fire = not bool(m.get("intro_mode"))
		1:
			fire = _boost_seen or _since_last > 11.0
		2:
			fire = (m as Node2D).global_position.y > 40000.0 or _since_last > 14.0
	if fire:
		_label.text = str(BEATS[_stage]["text"])
		_label.add_theme_color_override("font_color", BEATS[_stage]["col"])
		_hold = HOLD
		_showing = _stage
		_stage += 1
