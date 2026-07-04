extends Control
## In-run HUD. One visual system: pill chips on an 8-px spacing grid,
## grouped by meaning — left: where/what; center: the clock (the star of
## the show); right side is kept clear for the checklist.

var muon: Node2D = null

var _timer_label: Label
var _gamma_chip: PanelContainer
var _gamma_label: Label
var _gamma_bar: Control
var _alt_label: Label
var _mischief_label: Label
var _sparks_label: Label
var _toast_chip: PanelContainer
var _toast_label: Label
var _hint_chip: PanelContainer
var _hint_label: Label
var _last_layer := -1
var _last_bucket := -1
var _hint_t := 0.0
var _t := 0.0
var _toasts := []

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

	# Red alert wash (P(decay) > 90%), beneath everything else.
	_alert_rect = ColorRect.new()
	_alert_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_rect.visible = false
	add_child(_alert_rect)

	# The clock: big, centered, unmissable.
	_timer_label = Label.new()
	_timer_label.add_theme_font_override("font", Juice.ui_font)
	_timer_label.add_theme_font_size_override("font_size", 46)
	_timer_label.add_theme_color_override("font_color", Juice.CREAM)
	_timer_label.add_theme_color_override("font_outline_color", Juice.INK)
	_timer_label.add_theme_constant_override("outline_size", 8)
	_timer_label.add_theme_color_override("font_shadow_color", Color(Juice.INK, 0.35))
	_timer_label.add_theme_constant_override("shadow_offset_y", 3)
	_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timer_label)

	# The same moment in the other frame, quietly underneath.
	_lab_label = Label.new()
	_lab_label.add_theme_font_size_override("font_size", 14)
	_lab_label.add_theme_color_override("font_color", Color(Juice.CREAM, 0.75))
	_lab_label.add_theme_color_override("font_outline_color", Juice.INK)
	_lab_label.add_theme_constant_override("outline_size", 5)
	_lab_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lab_label)

	_alert_label = Label.new()
	_alert_label.text = "!! DECAY PROBABILITY EXCEEDS 90% !!"
	_alert_label.add_theme_font_override("font", Juice.ui_font)
	_alert_label.add_theme_font_size_override("font_size", 26)
	_alert_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.4))
	_alert_label.add_theme_color_override("font_outline_color", Juice.INK)
	_alert_label.add_theme_constant_override("outline_size", 8)
	_alert_label.visible = false
	_alert_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_alert_label)

	# Pulsing red frame around the whole screen when it's dire.
	_alert_border = Control.new()
	_alert_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alert_border.visible = false
	_alert_border.draw.connect(_draw_alert_border)
	add_child(_alert_border)

	# γ / velocity chip with a small dilation bar.
	var gamma_pair := _mk_chip(14, "")
	_gamma_chip = gamma_pair[0]
	_gamma_label = gamma_pair[1]
	_gamma_bar = Control.new()
	_gamma_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gamma_bar.draw.connect(_draw_gamma_bar)
	add_child(_gamma_bar)

	# Left column chips.
	var alt_pair := _mk_chip(14, "")
	_alt_label = alt_pair[1]
	_alt_chip = alt_pair[0]
	var mischief_pair := _mk_chip(14, "")
	_mischief_label = mischief_pair[1]
	_mischief_chip = mischief_pair[0]
	var sparks_pair := _mk_chip(14, "res://assets/sprites/spark_icon.svg")
	_sparks_label = sparks_pair[1]
	_sparks_chip = sparks_pair[0]

	# Toast + hint.
	var toast_pair := _mk_chip(19, "")
	_toast_chip = toast_pair[0]
	_toast_label = toast_pair[1]
	_toast_label.add_theme_font_override("font", Juice.hand_font)
	_toast_chip.modulate.a = 0.0
	var hint_pair := _mk_chip(14, "")
	_hint_chip = hint_pair[0]
	_hint_label = hint_pair[1]
	_hint_chip.add_theme_stylebox_override("panel", Juice.ui_chip(Juice.INK, 0.45))
	_hint_label.add_theme_color_override("font_color", Juice.CREAM)
	if Game.is_touch():
		_hint_label.text = "drag left — steer · tap right — zap · tap the paper tab — to-dos"
	else:
		_hint_label.text = "steer · the sky has fields, find them      SPACE zap · TAB list"

	_plot = preload("res://game/ui/decay_plot.gd").new()
	add_child(_plot)

	_toasts = TOASTS.duplicate()
	_toasts[0] = "born of a %s" % Meta.origin()["name"]


var _alt_chip: PanelContainer
var _mischief_chip: PanelContainer
var _sparks_chip: PanelContainer
var _plot: Control
var _lab_label: Label
var _alert_rect: ColorRect
var _alert_label: Label
var _alert_border: Control
var _glitch_timer := 0.0


func _mk_chip(font_size: int, icon_path: String) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Juice.ui_chip())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	if icon_path != "":
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
	var label := Label.new()
	label.add_theme_font_override("font", Juice.ui_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Juice.INK)
	row.add_child(label)
	add_child(panel)
	return [panel, label]


func _process(delta: float) -> void:
	if muon == null or not is_instance_valid(muon):
		return
	_t += delta
	var vp := get_viewport_rect().size
	var age: float = muon.get("age_us")
	var gamma: float = muon.get("gamma")

	# Proper age, counting up. Past 2.2 you're living on luck.
	_timer_label.text = "%.2f µs" % age
	_timer_label.position = Vector2(vp.x * 0.5 - _timer_label.size.x * 0.5, 12.0)
	_timer_label.pivot_offset = _timer_label.size * 0.5
	var bucket := int(age * 20.0)
	if bucket != _last_bucket:
		_last_bucket = bucket
		_timer_label.scale = Vector2(1.12, 0.92)
		var tw := create_tween()
		tw.tween_property(_timer_label, "scale", Vector2.ONE, 0.18)
	if age > 1.76:
		var pulse := 0.5 + 0.5 * sin(_t * 10.0)
		_timer_label.add_theme_color_override("font_color", Juice.CREAM.lerp(Color("ff8fa3"), pulse))
	else:
		_timer_label.add_theme_color_override("font_color", Juice.CREAM)

	var lab: float = muon.get("lab_us")
	_lab_label.text = "proper · lab frame %.1f µs" % lab
	_lab_label.position = Vector2(vp.x * 0.5 - _lab_label.size.x * 0.5, 60.0)

	# Red alert: the dice are loaded now. The whole UI comes apart a little —
	# jitter, glitch bursts, a pulsing frame, a sustained tremble.
	var p_now: float = muon.get("decay_p")
	var in_danger: bool = p_now > 0.9 and muon.get("alive") and not muon.get("finished")
	_alert_rect.visible = in_danger
	_alert_border.visible = in_danger
	_alert_label.visible = in_danger and int(_t * 4.0) % 3 != 0
	var jit := Vector2.ZERO
	if in_danger:
		jit = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 3.5
		_alert_rect.color = Color(1.0, 0.2, 0.28, 0.06 + 0.06 * absf(sin(_t * 9.0)))
		_alert_border.queue_redraw()
		_alert_label.pivot_offset = _alert_label.size * 0.5
		_alert_label.scale = Vector2.ONE * (1.0 + 0.06 * sin(_t * 11.0))
		_alert_label.position = Vector2(vp.x * 0.5 - _alert_label.size.x * 0.5, 208.0) + jit * 1.6
		_timer_label.position += jit
		Juice.trauma = maxf(Juice.trauma, 0.17)
		_glitch_timer -= delta
		if _glitch_timer <= 0.0:
			_glitch_timer = randf_range(0.6, 1.2)
			Juice.glitch(0.2, 0.45)
			Sfx.play("glitch", -12.0, 0.2)

	var beta := sqrt(maxf(1.0 - 1.0 / (gamma * gamma), 0.0))
	_gamma_label.text = "γ %.1f · %.3fc" % [gamma, beta]
	_gamma_chip.position = Vector2(vp.x * 0.5 - _gamma_chip.size.x * 0.5, 84.0)
	_gamma_bar.position = Vector2(vp.x * 0.5 - 60.0, 116.0)
	_gamma_bar.size = Vector2(120.0, 8.0)
	_gamma_bar.queue_redraw()

	var y_pos: float = muon.global_position.y
	var layer := Atmos.layer_index_at(y_pos)
	_alt_label.text = "%d km · %s" % [int(round(Atmos.altitude_at(y_pos))), Atmos.LAYER_NAMES[layer]]
	_alt_chip.position = Vector2(16.0, 12.0) + jit * 0.7
	_mischief_label.text = "mischief %d/%d" % [Tasks.optional_done_count(), Tasks.optional_total()]
	_mischief_chip.position = Vector2(16.0, 12.0 + 40.0) - jit * 0.5
	_sparks_label.text = str(Meta.sparks)
	_sparks_chip.position = Vector2(16.0, 12.0 + 80.0) + jit * 0.6

	if layer != _last_layer:
		_last_layer = layer
		_show_toast(_toasts[layer])
	_toast_chip.position = Vector2(vp.x * 0.5 - _toast_chip.size.x * 0.5, 138.0)

	if _plot.get("muon") == null:
		_plot.set("muon", muon)
	_plot.position = Vector2(16.0, vp.y - _plot.size.y - 16.0)

	_hint_t += delta
	_hint_chip.position = Vector2(vp.x * 0.5 - _hint_chip.size.x * 0.5, vp.y - 52.0)
	if _hint_t > 9.0 and _hint_chip.modulate.a > 0.0:
		_hint_chip.modulate.a = maxf(_hint_chip.modulate.a - delta * 0.8, 0.0)

	# Nothing gets to hide the muon: any element it flies behind fades
	# way down until it has passed. (Toast/hint own their alpha via
	# tweens; the danger banner stays — it's an alarm.)
	for el: Control in [_timer_label, _lab_label, _gamma_chip, _gamma_bar,
			_alt_chip, _mischief_chip, _sparks_chip, _plot]:
		Juice.duck_behind_muon(el, delta)


func _show_toast(text: String) -> void:
	_toast_label.text = text
	var tw := create_tween()
	tw.tween_property(_toast_chip, "modulate:a", 1.0, 0.3)
	tw.tween_interval(2.2)
	tw.tween_property(_toast_chip, "modulate:a", 0.0, 0.5)


func _draw_alert_border() -> void:
	var vp := _alert_border.size
	var pulse := 0.35 + 0.35 * absf(sin(_t * 9.0))
	var col := Color(1.0, 0.25, 0.33, pulse)
	var w := 5.0 + 3.0 * absf(sin(_t * 9.0))
	_alert_border.draw_rect(Rect2(0, 0, vp.x, w), col)
	_alert_border.draw_rect(Rect2(0, vp.y - w, vp.x, w), col)
	_alert_border.draw_rect(Rect2(0, 0, w, vp.y), col)
	_alert_border.draw_rect(Rect2(vp.x - w, 0, w, vp.y), col)


func _draw_gamma_bar() -> void:
	if muon == null or not is_instance_valid(muon):
		return
	var gamma: float = muon.get("gamma")
	var frac := clampf((gamma - 1.0) / 24.0, 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(Juice.INK, 0.5)
	bg.set_corner_radius_all(4)
	bg.draw(_gamma_bar.get_canvas_item(), Rect2(0, 0, 120, 8))
	if frac > 0.02:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Juice.MINT.lerp(Juice.SUN, frac)
		fill.set_corner_radius_all(4)
		fill.draw(_gamma_bar.get_canvas_item(), Rect2(1, 1, 118.0 * frac, 6))
