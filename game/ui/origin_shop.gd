extends Control
## The origin-story shop, on the title screen. Spend sparks to be produced
## by ever more violent astrophysics. U toggles, ENTER acquires.

const W := 600.0
const ROW_H := 44.0
const ROW_TOP := 104.0   # first row's y — leaves room for the energy track
const GOLD := Color("ffe08a")
const TaskPop := preload("res://game/fx/task_pop.gd")


## The origin ladder's colour spine: energy (and γ) climbing coral → gold.
func _grad(f: float) -> Color:
	var stops := [Color("ff5c4d"), Color("ffb03a"), Color("3ecfb2"), Color("6a5cff"), GOLD]
	var x := clampf(f, 0.0, 1.0) * float(stops.size() - 1)
	var i := int(floor(x))
	if i >= stops.size() - 1:
		return stops[stops.size() - 1]
	return (stops[i] as Color).lerp(stops[i + 1], x - float(i))

var active := false

var _cursor := 0
var _reset_armed := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(W, ROW_TOP + Meta.TIERS.size() * ROW_H + 90.0)


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
		var row := int(floor((local.y - (ROW_TOP - 6.0)) / ROW_H))
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

	# The energy ladder's spine: a gradient track from a modest solar flare to
	# the impossible OMG particle — each origin is a rung further up it.
	var last := Meta.TIERS.size() - 1
	draw_string(font, Vector2(24, 62), "MORE ENERGY AT BIRTH →", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.INK, 0.5))
	var hg := "HIGHER γ →"
	var hgw := font.get_string_size(hg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, Vector2(W - 24 - hgw, 62), hg, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(Juice.PERIWINKLE, 0.7))
	var tx0 := 24.0
	var tw := W - 48.0
	var ty := 70.0
	var step := 4.0
	var sx := tx0
	while sx < tx0 + tw:
		draw_rect(Rect2(sx, ty, step + 1.0, 9.0), _grad((sx - tx0) / tw))
		sx += step
	draw_rect(Rect2(tx0, ty, tw, 9.0), Color(Juice.INK, 0.4), false, 1.0)
	# Marker at the equipped tier's rung.
	var mx := tx0 + (float(Meta.tier) / float(maxi(last, 1))) * tw
	draw_colored_polygon(PackedVector2Array([
		Vector2(mx, ty - 2.0), Vector2(mx - 5.0, ty - 10.0), Vector2(mx + 5.0, ty - 10.0),
	]), Juice.CREAM)
	draw_line(Vector2(20, ROW_TOP - 14.0), Vector2(W - 20, ROW_TOP - 14.0), Color(Juice.INK, 0.2), 1.5)

	for i in Meta.TIERS.size():
		var t: Dictionary = Meta.tier_display(i)
		var y := ROW_TOP + i * ROW_H
		var rung := _grad(float(i) / float(maxi(last, 1)))
		var is_omg := i == last
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
		# The finale glows even while it's still a mystery.
		if is_omg:
			draw_rect(Rect2(14, y - 6, W - 28, ROW_H - 4), Color(GOLD, 0.13))
		# Rung dot: this origin's place on the energy ladder.
		draw_circle(Vector2(24, y + 10), 4.0, Color(rung, 1.0 if (owned or next_up) else 0.35))
		var name_col := Juice.INK if (owned or next_up) else Color(Juice.INK, 0.4)
		if is_omg and (owned or next_up):
			name_col = Color("b8860b")
		var nm := str(t["name"])
		if is_omg and not Meta.is_mystery(i):
			nm += " ★"
		draw_string(font, Vector2(38, y + 12), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, name_col)
		draw_string(font, Vector2(38, y + 29), str(t["flavor"]), HORIZONTAL_ALIGNMENT_LEFT, 288, 11, Color(Juice.INK, 0.5))
		# Middle column: energy + gamma. Right column: status, right-aligned.
		draw_string(font, Vector2(W - 254, y + 12), "E ≈ %s" % t["energy"], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.INK, 0.7))
		draw_string(font, Vector2(W - 254, y + 28), "γ +%.1f" % float(t["gamma"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(Juice.PERIWINKLE, 0.9))
		var status := ""
		var status_col := Color(Juice.INK, 0.5)
		var act := "tap" if Game.is_touch() else "ENTER"
		if equipped:
			status = "EQUIPPED"
			status_col = Color("2e8b57")
		elif owned:
			status = "%s — equip" % act
			status_col = Juice.INK if i == _cursor else Color(Juice.INK, 0.5)
		elif next_up:
			status = ("%s · %d sparks" % [act, int(t["cost"])]) if Meta.can_upgrade() \
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
	if Game.is_touch():
		reset_hint = "tap a row — acquire / equip · tap outside — close"
	if _reset_armed > 0.0:
		reset_hint = "BACKSPACE again to really reset everything!"
	draw_string(font, Vector2(24, foot_y + 22), reset_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color("e05c6e") if _reset_armed > 0.0 else Color(Juice.INK, 0.6))
