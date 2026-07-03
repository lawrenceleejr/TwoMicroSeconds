extends Control
## Proper-time countdown, gamma meter, altitude readout, layer toasts, hints.

var muon: Node2D = null

var _timer_label: Label
var _gamma_label: Label
var _alt_label: Label
var _mischief_label: Label
var _toast_label: Label
var _hint_label: Label
var _gamma_bar: Control
var _last_layer := -1
var _last_bucket := -1
var _hint_t := 0.0
var _t := 0.0

const TOASTS := [
	"the thermosphere · born of a cosmic ray",
	"the mesosphere · where stars come to fall",
	"the stratosphere · shh, the ozone is sleeping",
	"the troposphere · weather happens here",
	"the ground · almost home",
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer_label = _mk_label(46)
	_gamma_label = _mk_label(16)
	_alt_label = _mk_label(17)
	_mischief_label = _mk_label(15)
	_toast_label = _mk_label(24)
	_toast_label.modulate.a = 0.0
	_hint_label = _mk_label(17)
	_hint_label.text = "move fast — fast muons age slowly.   SPACE zip · Z zap · TAB to-do list"
	_gamma_bar = Control.new()
	_gamma_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gamma_bar.draw.connect(_draw_gamma_bar)
	add_child(_gamma_bar)


func _mk_label(font_size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Juice.CREAM)
	l.add_theme_color_override("font_outline_color", Juice.INK)
	l.add_theme_constant_override("outline_size", 7)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _process(delta: float) -> void:
	if muon == null or not is_instance_valid(muon):
		return
	_t += delta
	var vp := get_viewport_rect().size
	var pt: float = maxf(muon.get("proper_time"), 0.0)
	var gamma: float = muon.get("gamma")

	_timer_label.text = "%.2f µs" % pt
	_timer_label.position = Vector2(vp.x * 0.5 - _timer_label.size.x * 0.5, 14.0)
	_timer_label.pivot_offset = _timer_label.size * 0.5
	var bucket := int(pt * 20.0)
	if bucket != _last_bucket:
		_last_bucket = bucket
		_timer_label.scale = Vector2(1.12, 0.92)
		var tw := create_tween()
		tw.tween_property(_timer_label, "scale", Vector2.ONE, 0.18)
	if pt < 0.45:
		var pulse := 0.5 + 0.5 * sin(_t * 10.0)
		_timer_label.add_theme_color_override("font_color", Juice.CREAM.lerp(Color("ff8fa3"), pulse))
	else:
		_timer_label.add_theme_color_override("font_color", Juice.CREAM)

	_gamma_label.text = "γ = %.1f" % gamma
	_gamma_label.position = Vector2(vp.x * 0.5 - 80.0, 68.0)
	_gamma_bar.position = Vector2(vp.x * 0.5 - 80.0 + _gamma_label.size.x + 10.0, 76.0)
	_gamma_bar.size = Vector2(120.0, 10.0)
	_gamma_bar.queue_redraw()

	var y_pos: float = muon.global_position.y
	var layer := Atmos.layer_index_at(y_pos)
	_alt_label.text = "%d km · %s" % [int(round(Atmos.altitude_at(y_pos))), Atmos.LAYER_NAMES[layer]]
	_alt_label.position = Vector2(16.0, 12.0)
	_mischief_label.text = "mischief %d/%d" % [Tasks.optional_done_count(), Tasks.optional_total()]
	_mischief_label.position = Vector2(16.0, 40.0)

	if layer != _last_layer:
		_last_layer = layer
		_show_toast(TOASTS[layer])
	_toast_label.position = Vector2(vp.x * 0.5 - _toast_label.size.x * 0.5, 120.0)

	_hint_t += delta
	_hint_label.position = Vector2(vp.x * 0.5 - _hint_label.size.x * 0.5, vp.y - 54.0)
	if _hint_t > 8.0 and _hint_label.modulate.a > 0.0:
		_hint_label.modulate.a = maxf(_hint_label.modulate.a - delta * 0.8, 0.0)


func _show_toast(text: String) -> void:
	_toast_label.text = text
	var tw := create_tween()
	tw.tween_property(_toast_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.2)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.5)


func _draw_gamma_bar() -> void:
	if muon == null or not is_instance_valid(muon):
		return
	var gamma: float = muon.get("gamma")
	var frac := clampf((gamma - 1.0) / 20.0, 0.0, 1.0)
	_gamma_bar.draw_rect(Rect2(0, 0, 120, 10), Color(Juice.INK, 0.5))
	var col := Juice.MINT.lerp(Juice.SUN, frac)
	_gamma_bar.draw_rect(Rect2(1, 1, 118.0 * frac, 8), col)
