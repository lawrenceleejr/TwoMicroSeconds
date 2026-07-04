extends Control
## The paper to-do list, Goose-style. Tab slides it away.
## Fully custom-drawn: hand-wobbled strikethroughs and all.

const W := 300.0
const TaskPop := preload("res://game/fx/task_pop.gd")

var open := true

var _slide := 0.0
var _strikes := {}
var _t := 0.0
var _stamp_scale := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, Tasks.DEFS.size() * 26.0 + 78.0)
	pivot_offset = Vector2(W * 0.5, 0.0)
	rotation = -0.012  # pinned up slightly crooked, like a real note
	Tasks.task_completed.connect(_on_task_completed)
	# Phones: start tucked away — the sky is small enough already.
	if DisplayServer.is_touchscreen_available():
		open = false
		_slide = 1.0


func _input(event: InputEvent) -> void:
	# Tap/click the note (or its edge tab when tucked away) toggles it.
	# (On touch devices, taps also arrive as emulated mouse clicks — only
	# listen to one kind per device class to avoid double toggles.)
	var pt := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pt = event.position
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not DisplayServer.is_touchscreen_available():
		pt = event.position
	else:
		return
	var canvas_pt: Vector2 = get_viewport().get_final_transform().affine_inverse() * pt
	if get_global_rect().grow(8.0).has_point(canvas_pt):
		get_viewport().set_input_as_handled()
		open = not open
		Sfx.play("pop", -10.0)


func _process(delta: float) -> void:
	_t += delta
	if Input.is_action_just_pressed("toggle_checklist"):
		open = not open
		Sfx.play("pop", -10.0)
	var target := 0.0 if open else 1.0
	_slide = lerpf(_slide, target, 1.0 - exp(-10.0 * delta))
	var vp := get_viewport_rect().size
	# Tucked away, a 28-px sliver of paper stays on screen as the handle.
	position = Vector2(vp.x - W - 14.0 + _slide * (W - 14.0), 64.0)
	if Tasks.all_optional_done() and _stamp_scale < 1.0:
		_stamp_scale = minf(_stamp_scale + delta * 3.0, 1.0)
	# Never hide the muon: when it flies behind the note, the paper turns
	# translucent until it has passed.
	if open:
		Juice.duck_behind_muon(self, delta, 46.0)
	queue_redraw()


func _on_task_completed(task: Dictionary) -> void:
	var id: String = task["id"]
	_strikes[id] = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_strikes[id] = v
	, 0.0, 1.0, 0.4).set_delay(0.15)
	# Confetti at the item's spot on the list.
	var idx := 0
	for i in Tasks.DEFS.size():
		if Tasks.DEFS[i]["id"] == id:
			idx = i
			break
	TaskPop.confetti(self, Vector2(30.0, 56.0 + idx * 26.0), 14)


func _draw() -> void:
	# Paper, held up by a piece of washi tape.
	var sb := Juice.ui_panel(Juice.PAPER, 0.93, 14)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	# Edge tab affordances on the visible sliver when tucked away.
	if _slide > 0.5:
		draw_colored_polygon(PackedVector2Array([
			Vector2(18.0, 40.0), Vector2(8.0, 48.0), Vector2(18.0, 56.0),
		]), Color(Juice.INK, 0.6))
		draw_string(Juice.ui_font, Vector2(6.0, 84.0),
			"%d" % Tasks.optional_done_count(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
			Color(Juice.INK, 0.7))
	draw_set_transform(Vector2(W * 0.5, 0.0), 0.06, Vector2.ONE)
	draw_rect(Rect2(-26, -8, 52, 16), Color(Juice.MINT, 0.55))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var font: Font = Juice.hand_font
	draw_string(font, Vector2(16, 28), "to-do", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Juice.INK)
	draw_string(font, Vector2(76, 28), "(mischief optional)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Juice.INK, 0.55))
	draw_line(Vector2(14, 36), Vector2(W - 14, 36), Color(Juice.INK, 0.25), 1.5)

	for i in Tasks.DEFS.size():
		var d: Dictionary = Tasks.DEFS[i]
		var id: String = d["id"]
		var y := 56.0 + i * 26.0
		var jitter := float(absi(hash(id)) % 100 - 50) * 0.0005
		var is_done: bool = Tasks.is_done(id)
		draw_set_transform(Vector2(16, y), jitter, Vector2.ONE)
		# Checkbox.
		var box := Rect2(0, -11, 15, 15)
		draw_rect(box, Color(Juice.INK, 0.6), false, 1.8)
		if is_done:
			draw_rect(Rect2(1.5, -9.5, 12, 12), Color(Juice.MINT, 0.9))
			draw_line(Vector2(3, -4), Vector2(6.5, 0.5), Juice.INK, 2.2)
			draw_line(Vector2(6.5, 0.5), Vector2(13, -9), Juice.INK, 2.2)
		# Text.
		var text_col := Color(Juice.INK, 0.45) if is_done else Juice.INK
		draw_string(font, Vector2(24, 3), d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, text_col)
		# Wobbly strikethrough.
		var progress: float = _strikes.get(id, 1.0 if is_done else 0.0)
		if progress > 0.0:
			var text_w: float = font.get_string_size(d["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			var strike_w := (text_w + 6.0) * progress
			var pts := PackedVector2Array()
			var x := 0.0
			while x <= strike_w:
				pts.append(Vector2(22.0 + x, -3.0 + sin(x * 0.25 + float(absi(hash(id)) % 10)) * 1.6))
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
