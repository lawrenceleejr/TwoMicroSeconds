extends Control
## The paper to-do list, Goose-style. Tab slides it away.
## Fully custom-drawn: hand-wobbled strikethroughs and all.

const W := 300.0
# The grab-tab that stays on screen when the note is tucked away.
const TAB_W := 46.0
const TAB_H := 128.0
const TAB_Y := 30.0
## How long the note shows itself at run start before tucking away (touch).
const PEEK_T := 2.8

const TaskPop := preload("res://game/fx/task_pop.gd")

const LIST_TOP := 48.0
const ROW_STEP := 24.0
const SECTION_STEP := 22.0
## Task → prop sprite, so the list doubles as a preview of what you'll meet.
const ICONS := {
	"tickle_aurora": "sparkle", "bonk_satellite": "satellite",
	"overclock": "streak", "photobomb_star": "glint",
	"zap_noctilucent": "noctilucent", "startle_balloon": "balloon",
	"thread_airplane": "airplane", "make_rain": "cloud",
	"get_detected": "cms",
}

var open := true

var _slide := 0.0
var _strikes := {}
var _t := 0.0
var _stamp_scale := 0.0
var _peek_left := 0.0
var _user_touched := false
var _task_y := {}       # id → y, so rows and confetti agree
var _sections := []     # [{name, y}] atmospheric-band headers
var _icon_cache := {}


## Group the tasks by atmospheric band: the list becomes a map of the descent.
func _build_layout() -> void:
	var y := LIST_TOP
	var cur := -1
	for d in Tasks.DEFS:
		var lyr := int(d["layer"])
		if lyr != cur:
			cur = lyr
			y += 6.0
			_sections.append({"name": str(Atmos.LAYER_NAMES[lyr]), "y": y})
			y += SECTION_STEP
		_task_y[d["id"]] = y
		y += ROW_STEP
	size = Vector2(W, y + 30.0)


func _icon(id: String) -> Texture2D:
	if not ICONS.has(id):
		return null
	if not _icon_cache.has(id):
		_icon_cache[id] = load("res://assets/sprites/%s.svg" % ICONS[id])
	return _icon_cache[id]


func _ready() -> void:
	add_to_group("checklist")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layout()
	pivot_offset = Vector2(W * 0.5, 0.0)
	rotation = -0.012  # pinned up slightly crooked, like a real note
	Tasks.task_completed.connect(_on_task_completed)
	# Phones: show the note for a beat so you know it exists, then it
	# animates away — the tab stays on screen to bring it back.
	if Game.is_touch():
		open = true
		_peek_left = PEEK_T


func _toggle() -> void:
	open = not open
	_user_touched = true
	Sfx.play("pop", -10.0)


## Does a raw screen-space press (window pixels) land on our tap target?
## Uses the canvas-with-stretch transform so it is correct under the phone
## content_scale_factor — the plain viewport transform is off by that
## factor, which is why a small tucked tab was un-tappable before.
func wants_touch(screen_pos: Vector2) -> bool:
	if not visible:
		return false
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * screen_pos
	if _slide > 0.5:
		# Tucked: only the grab-tab column is on screen. Generous padding.
		return Rect2(-30.0, TAB_Y - 24.0, TAB_W + 62.0, TAB_H + 48.0).has_point(local)
	# Open: the whole note dismisses on tap.
	return Rect2(Vector2.ZERO, size).grow(10.0).has_point(local)


## Touchscreen router (touch_controls) forwards a tab/note tap here.
func toggle_from_touch() -> void:
	_toggle()


func _input(event: InputEvent) -> void:
	# Desktop only: click the note (or its grab-tab) to toggle. On touch
	# devices the routing goes through touch_controls (single owner) so a
	# tap can't also fire a zap.
	if Game.is_touch():
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if wants_touch(mb.position):
		get_viewport().set_input_as_handled()
		_toggle()


func _process(delta: float) -> void:
	_t += delta
	# On a vertical phone the note lives in the pause menu only — off the
	# play field, where it kept getting in the way. (Landscape/desktop keep
	# the pinned note.)
	if Game.is_touch():
		var vsz := get_viewport_rect().size
		if vsz.y > vsz.x:
			visible = false
			return
	visible = true
	if Input.is_action_just_pressed("toggle_checklist"):
		_toggle()
	# The opening peek: visible for a beat, then it slides itself away
	# (unless the player already grabbed it).
	if _peek_left > 0.0:
		_peek_left -= delta
		if _peek_left <= 0.0 and not _user_touched:
			open = false
			Sfx.play("pop", -14.0)
	var target := 0.0 if open else 1.0
	_slide = lerpf(_slide, target, 1.0 - exp(-10.0 * delta))
	var vp := get_viewport_rect().size
	# Tucked away, the note slides out until only the grab-tab column
	# (its first TAB_W units) stays on screen. On narrow (portrait)
	# screens the note starts below the HUD's center cluster.
	var y_top := 64.0 if vp.x > 900.0 else 150.0
	position = Vector2(vp.x - W - 14.0 + _slide * (W - TAB_W + 8.0), y_top)
	if Tasks.all_optional_done() and _stamp_scale < 1.0:
		_stamp_scale = minf(_stamp_scale + delta * 3.0, 1.0)
	# Never hide the muon: when it flies behind the note, the paper turns
	# translucent until it has passed. When tucked, always recover to
	# full opacity — otherwise a duck frozen at tuck time leaves the
	# grab-tab invisible (the "where did my to-do list go" bug).
	if open:
		Juice.duck_behind_muon(self, delta, 46.0)
	else:
		modulate.a = lerpf(modulate.a, 1.0, 1.0 - exp(-9.0 * delta))
	queue_redraw()


func _on_task_completed(task: Dictionary) -> void:
	# On touch there's no way to open the list by hand (steering only), so
	# it flashes itself open to show the strike-through, then re-tucks.
	if Game.is_touch():
		open = true
		_user_touched = false
		_peek_left = maxf(_peek_left, 2.2)
	var id: String = task["id"]
	_strikes[id] = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_strikes[id] = v
	, 0.0, 1.0, 0.4).set_delay(0.15)
	# Confetti at the item's spot on the list.
	TaskPop.confetti(self, Vector2(30.0, float(_task_y.get(id, 56.0))), 14)


func _draw() -> void:
	# Mostly tucked: draw ONLY the grab-tab, a paper tongue occupying the
	# note's first on-screen column — THE way to bring the note back.
	if _slide > 0.5:
		var tab := Rect2(0.0, TAB_Y, TAB_W, TAB_H)
		draw_rect(Rect2(tab.position + Vector2(-4, 4), tab.size), Color(Juice.PINK, 0.5))
		draw_rect(tab, Juice.PAPER)
		draw_rect(tab, Color(Juice.INK, 0.75), false, 1.5)
		# Chevron + list glyph + mischief count, stacked.
		draw_colored_polygon(PackedVector2Array([
			Vector2(28.0, TAB_Y + 18.0), Vector2(16.0, TAB_Y + 27.0),
			Vector2(28.0, TAB_Y + 36.0),
		]), Color(Juice.INK, 0.75))
		for li in 3:
			var ly := TAB_Y + 52.0 + li * 9.0
			draw_rect(Rect2(10.0, ly, 6.0, 3.0), Color(Juice.MINT, 0.9))
			draw_rect(Rect2(20.0, ly, 14.0, 3.0), Color(Juice.INK, 0.55))
		draw_string(Juice.ui_font, Vector2(12.0, TAB_Y + 104.0),
			"%d" % Tasks.optional_done_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Juice.INK)
		return
	# Paper, held up by a piece of washi tape.
	var sb := Juice.ui_panel(Juice.PAPER, 0.93, 14)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	draw_set_transform(Vector2(W * 0.5, 0.0), 0.06, Vector2.ONE)
	draw_rect(Rect2(-26, -8, 52, 16), Color(Juice.MINT, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var font: Font = Juice.hand_font
	draw_string(font, Vector2(16, 28), "mischief", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Juice.INK)
	# Perfect-sheet bonus, surfaced so the reward isn't hidden.
	var bonus := "clear all · +5 ◆"
	var bw: float = Juice.ui_font.get_string_size(bonus, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var bonus_col := Color("2e8b57") if Tasks.all_optional_done() else Color(Juice.SUN, 0.9)
	draw_string(Juice.ui_font, Vector2(W - 14 - bw, 26), bonus, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, bonus_col)
	draw_line(Vector2(14, 36), Vector2(W - 14, 36), Color(Juice.INK, 0.25), 1.5)

	# Atmospheric-band section labels (the descent, top to bottom).
	for s in _sections:
		draw_string(Juice.ui_font, Vector2(16, float(s["y"]) + 10.0),
			str(s["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a99dff"))

	for d: Dictionary in Tasks.DEFS:
		var id: String = d["id"]
		var y: float = _task_y[id]
		var jitter := float(absi(hash(id)) % 100 - 50) * 0.0005
		var is_done: bool = Tasks.is_done(id)
		draw_set_transform(Vector2(16, y), jitter, Vector2.ONE)
		# Checkbox.
		draw_rect(Rect2(0, -11, 15, 15), Color(Juice.INK, 0.6), false, 1.8)
		if is_done:
			draw_rect(Rect2(1.5, -9.5, 12, 12), Color(Juice.MINT, 0.9))
			draw_line(Vector2(3, -4), Vector2(6.5, 0.5), Juice.INK, 2.2)
			draw_line(Vector2(6.5, 0.5), Vector2(13, -9), Juice.INK, 2.2)
		# Prop sprite (where one exists), then the task text.
		var text_x := 24.0
		var icon := _icon(id)
		if icon != null:
			draw_texture_rect(icon, Rect2(22, -12, 17, 17), false,
				Color(1, 1, 1, 0.55 if is_done else 1.0))
			text_x = 44.0
		var text_col := Color(Juice.INK, 0.45) if is_done else Juice.INK
		draw_string(font, Vector2(text_x, 3), d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)
		# Wobbly strikethrough.
		var progress: float = _strikes.get(id, 1.0 if is_done else 0.0)
		if progress > 0.0:
			var text_w: float = font.get_string_size(d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var strike_w := (text_w + 6.0) * progress
			var pts := PackedVector2Array()
			var x := 0.0
			while x <= strike_w:
				pts.append(Vector2(text_x - 2.0 + x, -3.0 + sin(x * 0.25 + float(absi(hash(id)) % 10)) * 1.6))
				x += 6.0
			if pts.size() >= 2:
				draw_polyline(pts, Color(Juice.INK, 0.75), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Counter and (maybe) the coveted stamp.
	var count_y := size.y - 14.0
	draw_string(font, Vector2(16, count_y), "%d / %d" % [Tasks.optional_done_count(), Tasks.optional_total()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(Juice.INK, 0.7))
	if _stamp_scale > 0.0:
		draw_set_transform(Vector2(W - 70, count_y - 6.0), -0.22, Vector2.ONE * _stamp_scale)
		draw_arc(Vector2.ZERO, 26.0, 0, TAU, 24, Color("e05c6e"), 2.5, true)
		draw_string(font, Vector2(-19, 5), "A++", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("e05c6e"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
