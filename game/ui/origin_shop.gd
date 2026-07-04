extends Control
## The origin-story shop, on the title screen. Spend sparks to be produced
## by ever more violent astrophysics. U toggles, ENTER acquires.

const W := 600.0
const ROW_H := 44.0
const TaskPop := preload("res://game/fx/task_pop.gd")

var active := false

var _cursor := 0
var _reset_armed := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, Meta.TIERS.size() * ROW_H + 150.0)


func _process(delta: float) -> void:
	_reset_armed = maxf(_reset_armed - delta, 0.0)
	if not active:
		return
	var vp := get_viewport_rect().size
	position = (vp - size) * 0.5
	queue_redraw()


func toggle() -> void:
	active = not active
	visible = active
	_cursor = Meta.tier
	Sfx.play("pop", -8.0)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Touch / click: tap a row to select-and-activate, tap outside to close.
	# (Touches arrive here as emulated mouse buttons.)
	var mb := event as InputEventMouseButton
	if active and mb != null and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		get_viewport().set_input_as_handled()
		var local := mb.position - global_position
		if not Rect2(Vector2.ZERO, size).has_point(local):
			toggle()
			return
		var row := int(floor((local.y - 56.0) / ROW_H))
		if row >= 0 and row < Meta.TIERS.size() and row <= Meta.owned_tier + 1:
			_cursor = row
			_activate_cursor()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_U:
		get_viewport().set_input_as_handled()
		toggle()
	elif active and (key.physical_keycode == KEY_UP or key.physical_keycode == KEY_W):
		get_viewport().set_input_as_handled()
		_cursor = maxi(_cursor - 1, 0)
		Sfx.play("tick", -10.0)
		queue_redraw()
	elif active and (key.physical_keycode == KEY_DOWN or key.physical_keycode == KEY_S):
		get_viewport().set_input_as_handled()
		_cursor = mini(_cursor + 1, mini(Meta.owned_tier + 1, Meta.TIERS.size() - 1))
		Sfx.play("tick", -10.0)
		queue_redraw()
	elif active and (key.physical_keycode == KEY_ENTER or key.physical_keycode == KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		_activate_cursor()
	elif active and key.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		toggle()
	elif active and key.physical_keycode == KEY_BACKSPACE:
		get_viewport().set_input_as_handled()
		if _reset_armed > 0.0:
			Meta.reset_save()
			Sfx.play("deny", -2.0)
			_reset_armed = 0.0
		else:
			_reset_armed = 1.0
			Sfx.play("tick", -4.0)
		queue_redraw()


func _activate_cursor() -> void:
	if _cursor <= Meta.owned_tier:
		# Equip (downgrades welcome — sometimes you want the slow sky back).
		if Meta.equip(_cursor):
			Sfx.play("pop", -4.0)
		else:
			Sfx.play("deny", -6.0)
	elif _cursor == Meta.owned_tier + 1 and Meta.try_upgrade():
		_cursor = Meta.tier
		Sfx.play("buy", -2.0)
		TaskPop.confetti(self, Vector2(W * 0.5, 70.0), 30)
		if Meta.is_max_tier():
			Juice.glitch(0.45, 0.8)
	else:
		Sfx.play("deny", -4.0)
	queue_redraw()


func _draw() -> void:
	# Dim the world behind the modal.
	var vp := get_viewport_rect().size
	draw_rect(Rect2(-position, vp), Color(Juice.INK, 0.4))
	var sb := Juice.ui_panel(Juice.PAPER, 0.99, 16)
	sb.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(24, 34), "ORIGIN STORY", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Juice.INK)
	draw_string(font, Vector2(216, 34), "· choose your birth", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(Juice.INK, 0.55))
	var sparks_text := "sparks: %d" % Meta.sparks
	var stw := font.get_string_size(sparks_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(W - 24 - stw, 34), sparks_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Juice.PERIWINKLE)
	draw_line(Vector2(20, 46), Vector2(W - 20, 46), Color(Juice.INK, 0.2), 1.5)

	for i in Meta.TIERS.size():
		var t: Dictionary = Meta.TIERS[i]
		var y := 62.0 + i * ROW_H
		var equipped := i == Meta.tier
		var owned := i <= Meta.owned_tier
		var next_up := i == Meta.owned_tier + 1
		# Highlight boxes: equipped mint, cursor sun.
		if equipped:
			var hl := StyleBoxFlat.new()
			hl.bg_color = Color(Juice.MINT, 0.35)
			hl.set_corner_radius_all(8)
			hl.draw(get_canvas_item(), Rect2(14, y - 6, W - 28, ROW_H - 4))
		if i == _cursor:
			var hl2 := StyleBoxFlat.new()
			hl2.bg_color = Color(0, 0, 0, 0)
			hl2.set_border_width_all(2)
			hl2.border_color = Color(Juice.SUN, 0.9)
			hl2.set_corner_radius_all(8)
			hl2.draw(get_canvas_item(), Rect2(14, y - 6, W - 28, ROW_H - 4))
			# Cursor arrow.
			draw_colored_polygon(PackedVector2Array([
				Vector2(6, y + 6), Vector2(12, y + 11), Vector2(6, y + 16)
			]), Juice.INK)
		var name_col := Juice.INK if (owned or next_up) else Color(Juice.INK, 0.4)
		draw_string(font, Vector2(28, y + 12), str(t["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, name_col)
		draw_string(font, Vector2(28, y + 29), str(t["flavor"]), HORIZONTAL_ALIGNMENT_LEFT, 300, 11, Color(Juice.INK, 0.5))
		# Middle column: energy + gamma. Right column: status, right-aligned.
		draw_string(font, Vector2(W - 254, y + 12), "E ≈ %s" % t["energy"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.INK, 0.7))
		draw_string(font, Vector2(W - 254, y + 28), "γ +%.1f" % float(t["gamma"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.PERIWINKLE, 0.9))
		var status := ""
		var status_col := Color(Juice.INK, 0.5)
		if equipped:
			status = "EQUIPPED"
			status_col = Color("2e8b57")
		elif owned:
			status = "ENTER — equip"
			status_col = Juice.INK if i == _cursor else Color(Juice.INK, 0.5)
		elif next_up:
			status = ("ENTER · %d sparks" % int(t["cost"])) if Meta.can_upgrade() \
				else "%d sparks" % int(t["cost"])
			status_col = Juice.INK if Meta.can_upgrade() else Color(Juice.INK, 0.4)
		else:
			status = "%d sparks" % int(t["cost"])
			status_col = Color(Juice.INK, 0.3)
		var sw := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(W - 28 - sw, y + 20), status, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, status_col)

	var foot_y := size.y - 44.0
	draw_line(Vector2(20, foot_y - 14), Vector2(W - 20, foot_y - 14), Color(Juice.INK, 0.2), 1.5)
	draw_string(font, Vector2(24, foot_y + 4), "satellites pay sparks — hit them fast for double",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(Juice.INK, 0.6))
	var reset_hint := "↑↓ — browse · ENTER — acquire / equip · U — close · BACKSPACE ×2 — reset save"
	if _reset_armed > 0.0:
		reset_hint = "BACKSPACE again to really reset everything!"
	draw_string(font, Vector2(24, foot_y + 22), reset_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color("e05c6e") if _reset_armed > 0.0 else Color(Juice.INK, 0.6))
