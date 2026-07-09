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
	"the ground · not the finish line",
	"the bedrock · 100 m of rock means nothing to you",
]


func _ready() -> void:
	add_to_group("hud")
	add_to_group("menu_button")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Off-screen muon pointer: an arrow at the edge when it steers off-side.
	_arrow = Control.new()
	_arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(_draw_offscreen_arrow)
	add_child(_arrow)

	# Menu button (top-right): opens the pause menu. On a phone it's the only
	# way in — there's no ESC key — so touch taps are routed here too.
	_menu_btn = Control.new()
	_menu_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_btn.draw.connect(_draw_menu_btn)
	_menu_btn.gui_input.connect(_on_menu_input)
	add_child(_menu_btn)

	# Big transient banner (meteor warning, fusion event).
	_flash_label = Label.new()
	_flash_label.add_theme_font_override("font", Juice.ui_font)
	_flash_label.add_theme_font_size_override("font_size", 30)
	_flash_label.add_theme_color_override("font_outline_color", Juice.INK)
	_flash_label.add_theme_constant_override("outline_size", 8)
	_flash_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_label.visible = false
	add_child(_flash_label)

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

	_build_ribbon()

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
		_hint_label.text = "hold & slide left / right — steer · you fall on your own"
	else:
		_hint_label.text = "steer · ride what the sky throws at you      SPACE zap · TAB list"

	_plot = preload("res://game/ui/decay_plot.gd").new()
	add_child(_plot)

	_depth = preload("res://game/ui/depth_meter.gd").new()
	add_child(_depth)

	_toasts = TOASTS.duplicate()
	_toasts[0] = "born of a %s" % Meta.origin()["name"]


var _alt_chip: PanelContainer
var _mischief_chip: PanelContainer
var _sparks_chip: PanelContainer
var _plot: Control
var _depth: Control
var _lab_label: Label
var _alert_rect: ColorRect
var _alert_label: Label
var _alert_border: Control
var _glitch_timer := 0.0
var _flash_label: Label
var _flash_t := 0.0
var _flash_dur := 0.0
var _flash_col := Color.WHITE
var _arrow: Control
var _menu_btn: Control
# Causal-chain ribbon: names the physics as a chain, not four loose numbers.
var _ribbon_panel: PanelContainer
var _rib_v: Label
var _rib_a1: Label
var _rib_g: Label
var _rib_sky: Label
var _rib_a3: Label
var _rib_time: Label


func _build_ribbon() -> void:
	_ribbon_panel = PanelContainer.new()
	_ribbon_panel.add_theme_stylebox_override("panel", Juice.ui_chip(Juice.INK, 0.6))
	_ribbon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	_ribbon_panel.add_child(row)
	_rib_v = _rib_seg(row, "v —", Juice.CREAM)
	_rib_a1 = _rib_seg(row, "→", Color(Juice.CREAM, 0.4))
	_rib_g = _rib_seg(row, "γ —", Juice.SUN)
	_rib_seg(row, "→", Color(Juice.CREAM, 0.4))
	_rib_sky = _rib_seg(row, "sky —", Color("a99dff"))
	_rib_a3 = _rib_seg(row, "→", Color(Juice.CREAM, 0.4))
	_rib_time = _rib_seg(row, "time borrowed", Juice.MINT)
	add_child(_ribbon_panel)


func _rib_seg(row: HBoxContainer, text: String, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", Juice.ui_font)
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", col)
	row.add_child(l)
	return l


## Draw the menu button: a small hamburger glyph on an ink disc.
func _draw_menu_btn() -> void:
	var c: Vector2 = _menu_btn.size * 0.5
	_menu_btn.draw_circle(c, 17.0, Color(Juice.INK, 0.5))
	_menu_btn.draw_circle(c, 17.0, Color(Juice.CREAM, 0.35), false, 1.5)
	for i in 3:
		var yy := c.y - 6.0 + i * 6.0
		_menu_btn.draw_line(Vector2(c.x - 8.0, yy), Vector2(c.x + 8.0, yy),
			Color(Juice.CREAM, 0.9), 2.2)


func _on_menu_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_menu_btn.accept_event()
		_open_menu()


## Touch router hook (touch_controls forwards a tap that lands on us here).
func wants_touch(screen_pos: Vector2) -> bool:
	var local: Vector2 = _menu_btn.get_global_transform_with_canvas().affine_inverse() * screen_pos
	return Rect2(Vector2.ZERO, _menu_btn.size).grow(10.0).has_point(local)


func press_menu() -> void:
	_open_menu()


func _open_menu() -> void:
	var p := get_tree().get_first_node_in_group("pause")
	if p != null:
		p.open()


## An arrow at the screen edge when the muon has steered off to one side,
## so you always know where it is.
func _draw_offscreen_arrow() -> void:
	if muon == null or not is_instance_valid(muon):
		return
	if not muon.get("alive") or muon.get("finished"):
		return
	var vp := _arrow.get_viewport_rect().size
	var p: Vector2 = get_viewport().get_final_transform().affine_inverse() * Game.muon_screen_pos
	if p.x >= 24.0 and p.x <= vp.x - 24.0:
		return  # comfortably on screen
	var left := p.x < vp.x * 0.5
	var ex := 34.0 if left else vp.x - 34.0
	var ey := clampf(p.y, 90.0, vp.y - 90.0)
	var dir := -1.0 if left else 1.0
	var pulse := 0.7 + 0.3 * sin(_t * 6.0)
	# A little chip with a triangle pointing toward the muon.
	_arrow.draw_circle(Vector2(ex, ey), 20.0, Color(Juice.INK, 0.4))
	_arrow.draw_colored_polygon(PackedVector2Array([
		Vector2(ex + dir * 13.0, ey), Vector2(ex - dir * 8.0, ey - 11.0),
		Vector2(ex - dir * 8.0, ey + 11.0),
	]), Color(Juice.PINK, pulse))
	_arrow.draw_circle(Vector2(ex - dir * 12.0, ey), 4.0, Color(Juice.CREAM, pulse))


## A big strobing banner: meteor shower warnings, fusion events, etc.
func _flash_message(text: String, col: Color, dur: float) -> void:
	_flash_label.text = text
	_flash_col = col
	_flash_dur = dur
	_flash_t = dur
	_flash_label.visible = true


func meteor_warning() -> void:
	_flash_message("!! METEOR SHOWER INCOMING — DODGE !!", Juice.PINK, 2.6)


func fusion_event() -> void:
	_flash_message("MUON-CATALYZED FUSION EVENT!", Juice.SUN, 3.2)
	Juice.shake(0.4)


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
	# A tall phone is narrow: the big centered clock spans the whole width and
	# collides with the corner chips. On portrait we shrink the clock and move
	# the status chips into the right column (free now the note is menu-only).
	var portrait := vp.y > vp.x
	# On a phone the clock is the single hero readout — scale it up.
	_timer_label.add_theme_font_size_override("font_size", 40 if portrait else 46)
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
	# The clock is a budget, not a stat: name the ~2.2 µs mean it's spending
	# toward (decay is random — the plot shows the odds). Lab frame trails it.
	if portrait:
		_lab_label.text = "of ~2.2 µs mean · lab %.1f µs" % lab
	else:
		_lab_label.text = "proper time · of ~2.2 µs mean · lab frame %.1f µs" % lab
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
		# Narrow (portrait) screens get the short scream so it never clips.
		_alert_label.text = "!! DECAY PROBABILITY EXCEEDS 90% !!" if vp.x > 860.0 \
			else "!! P(DECAY) > 90% !!"
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

	# Causal-chain ribbon: v → γ → sky ÷γ → time borrowed, live. On a narrow
	# phone it compresses to just γ → sky (drop the ends).
	_rib_v.text = "v %.3fc" % beta
	_rib_g.text = "γ %.0f×" % gamma
	_rib_sky.text = "sky ÷%d" % maxi(1, int(round(gamma)))
	var full_chain := not portrait
	_rib_v.visible = full_chain
	_rib_a1.visible = full_chain
	_rib_time.visible = full_chain
	_rib_a3.visible = full_chain
	_ribbon_panel.reset_size()
	_ribbon_panel.position = Vector2(vp.x * 0.5 - _ribbon_panel.size.x * 0.5,
		150.0 if portrait else 132.0)

	var y_pos: float = muon.global_position.y
	var layer := Atmos.layer_index_at(y_pos)
	if layer == 5:
		_alt_label.text = "%d m deep · %s" % [int(round(Atmos.depth_m_at(y_pos))), Atmos.strata_label_at(y_pos)]
	else:
		_alt_label.text = "%d km · %s" % [int(round(Atmos.altitude_at(y_pos))), Atmos.LAYER_NAMES[layer]]
	if portrait:
		_alt_chip.position = Vector2(vp.x - _alt_chip.size.x - 12.0, 128.0) + jit * 0.7
	else:
		_alt_chip.position = Vector2(16.0, 12.0) + jit * 0.7

	_arrow.queue_redraw()

	# Menu button, top-right, clear of the checklist tab below it.
	_menu_btn.size = Vector2(34.0, 34.0)
	_menu_btn.position = Vector2(vp.x - 48.0, 12.0)
	_menu_btn.queue_redraw()

	# Big transient banner (meteor warning / fusion event): strobe + fade.
	if _flash_t > 0.0:
		_flash_t -= delta
		var on := int(_t * 8.0) % 2 == 0
		_flash_label.visible = on
		var a := clampf(_flash_t / maxf(_flash_dur, 0.01), 0.0, 1.0)
		_flash_label.add_theme_color_override("font_color", Color(_flash_col, 0.4 + 0.6 * a))
		_flash_label.pivot_offset = _flash_label.size * 0.5
		_flash_label.scale = Vector2.ONE * (1.0 + 0.08 * sin(_t * 14.0))
		_flash_label.position = Vector2(vp.x * 0.5 - _flash_label.size.x * 0.5, vp.y * 0.30)
		if _flash_t <= 0.0:
			_flash_label.visible = false
	_mischief_label.text = "mischief %d/%d" % [Tasks.optional_done_count(), Tasks.optional_total()]
	_sparks_label.text = str(Meta.sparks)
	if portrait:
		_mischief_chip.position = Vector2(vp.x - _mischief_chip.size.x - 12.0, 166.0) - jit * 0.5
		_sparks_chip.position = Vector2(vp.x - _sparks_chip.size.x - 12.0, 204.0) + jit * 0.6
	else:
		_mischief_chip.position = Vector2(16.0, 12.0 + 40.0) - jit * 0.5
		_sparks_chip.position = Vector2(16.0, 12.0 + 80.0) + jit * 0.6

	if layer != _last_layer:
		_last_layer = layer
		_show_toast(_toasts[layer])
	_toast_chip.position = Vector2(vp.x * 0.5 - _toast_chip.size.x * 0.5, 250.0 if portrait else 176.0)

	if _plot.get("muon") == null:
		_plot.set("muon", muon)
	_plot.position = Vector2(16.0, vp.y - _plot.size.y - 16.0)

	# The descent gauge rides the left edge between the chips and the plot.
	if _depth.get("muon") == null:
		_depth.set("muon", muon)
	var d_top := 148.0
	_depth.position = Vector2(14.0, d_top)
	_depth.size = Vector2(74.0, vp.y - _plot.size.y - 40.0 - d_top)

	_hint_t += delta
	_hint_chip.position = Vector2(vp.x * 0.5 - _hint_chip.size.x * 0.5, vp.y - 52.0)
	if _hint_t > 9.0 and _hint_chip.modulate.a > 0.0:
		_hint_chip.modulate.a = maxf(_hint_chip.modulate.a - delta * 0.8, 0.0)

	# Nothing gets to hide the muon: any element it flies behind fades
	# way down until it has passed. (Toast/hint own their alpha via
	# tweens; the danger banner stays — it's an alarm.)
	for el: Control in [_timer_label, _lab_label, _gamma_chip, _gamma_bar,
			_ribbon_panel, _alt_chip, _mischief_chip, _sparks_chip, _plot, _depth]:
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
