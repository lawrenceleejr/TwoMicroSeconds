extends Node
## The juice drawer: palette, screen shake, hitstop, full-screen effect
## layers (relativity / vignette / glitch), and the shared UI style kit.
##
## Screen-effect layer order (UI lives above all of them, on layer 100):
##   world (0) -> relativity (70) -> vignette (80) -> glitch (90) -> UI (100)

# "Riso night" palette: a handful of print inks on warm paper. Deep
# violet-black ink, fluorescent coral, electric violet, teal, amber —
# risograph zine, not candy shop.
const INK := Color("171226")
const CREAM := Color("efe7d6")
const PAPER := Color("e9e1cf")
const PINK := Color("ff5c4d")    # riso fluorescent coral (primary accent)
const BLUSH := Color("ff5c4d")
const MINT := Color("3ecfb2")
const LILAC := Color("9b93c9")
const PERIWINKLE := Color("6a5cff")
const SUN := Color("ffb03a")
const RAIN := Color("6f8fc9")
const CONFETTI_COLORS: Array[Color] = [
	Color("ff5c4d"), Color("3ecfb2"), Color("ffb03a"), Color("6a5cff"), Color("efe7d6"),
]

var camera: Camera2D = null
var trauma := 0.0
## Editorial serif italic — flavor text, toasts, subtitles. Paired with a
## mono UI it reads "design studio", not "science fair".
var hand_font := SystemFont.new()
## Technical monospace for chips, numbers, and instrument readouts.
var ui_font := SystemFont.new()

var _noise := FastNoiseLite.new()
var _t := 0.0
var _in_hitstop := false
var _glitch_rect: ColorRect
var _glitch_mat: ShaderMaterial
var _glitch_tween: Tween
var _rel_rects: Array = []
var _rel_mat: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = 1137
	_noise.frequency = 2.0
	# One type language everywhere: technical mono as the default face.
	ThemeDB.fallback_font = ui_font
	hand_font.font_names = PackedStringArray(
		["Iowan Old Style", "Palatino", "Georgia", "Times New Roman", "serif"])
	hand_font.font_italic = true
	ui_font.font_names = PackedStringArray(
		["SF Mono", "Menlo", "JetBrains Mono", "Cascadia Code", "Consolas",
		"Liberation Mono", "monospace"])
	# Relativity is created inside the gameplay SubViewport by the stage
	# (see create_relativity_in) so contraction can sample the overscan
	# margin instead of smearing the screen edge.
	_build_screen_layer(80, "res://game/fx/vignette.gdshader", true)
	_glitch_mat = _build_screen_layer(90, "res://game/fx/glitch.gdshader", false)
	_glitch_rect = _last_rect


## Build a relativity layer inside `vp`. Call once per world viewport (the
## sky plane and the gameplay plane each get one); they share one material
## so contraction/Doppler stay in lockstep across the depth planes.
func create_relativity_in(vp: Viewport) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 70
	vp.add_child(layer)
	if _rel_mat == null:
		_rel_mat = ShaderMaterial.new()
		_rel_mat.shader = load("res://game/fx/relativity.gdshader")
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _rel_mat
	layer.add_child(rect)
	_rel_rects = _rel_rects.filter(func(r) -> bool: return is_instance_valid(r))
	_rel_rects.append(rect)


var _last_rect: ColorRect


func _build_screen_layer(layer_num: int, shader_path: String, start_visible: bool) -> ShaderMaterial:
	var layer := CanvasLayer.new()
	layer.layer = layer_num
	add_child(layer)
	var mat := ShaderMaterial.new()
	mat.shader = load(shader_path)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat
	rect.visible = start_visible
	layer.add_child(rect)
	_last_rect = rect
	return mat


# ------------------------------------------------------------- effects ----

func register_camera(cam: Camera2D) -> void:
	camera = cam


func shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Brief slow-motion punch. Safe to call from signal handlers.
func hitstop(duration := 0.06, time_scale := 0.05) -> void:
	if _in_hitstop:
		return
	_in_hitstop = true
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_in_hitstop = false


## Digital-artifact screen glitch + shake, decaying to nothing over `duration`.
func glitch(duration := 0.5, strength := 1.0) -> void:
	if _glitch_tween != null and _glitch_tween.is_valid():
		_glitch_tween.kill()
	_glitch_rect.visible = true
	_glitch_mat.set_shader_parameter("intensity", strength)
	shake(0.45 * strength)
	_glitch_tween = create_tween()
	_glitch_tween.tween_method(func(v: float) -> void:
		_glitch_mat.set_shader_parameter("intensity", v)
	, strength, 0.0, duration)
	_glitch_tween.tween_callback(func() -> void:
		_glitch_rect.visible = false
	)


## Relativistic view along screen-space `dir`. Doppler and blur scale with
## `strength` (speed); length contraction scales with `gamma_norm` — energy
## squashes the sky, because in your rest frame that's what energy does.
func set_relativity(dir: Vector2, strength: float, gamma_norm := 0.0) -> void:
	if _rel_mat == null:
		return
	var on := strength > 0.02 or gamma_norm > 0.02
	for r in _rel_rects:
		if is_instance_valid(r):
			r.visible = on
	_rel_mat.set_shader_parameter("motion_dir", dir)
	_rel_mat.set_shader_parameter("contraction", 0.06 + 0.34 * gamma_norm)
	_rel_mat.set_shader_parameter("doppler", 0.85 * strength)
	_rel_mat.set_shader_parameter("blur_amount", 0.016 * strength)


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.001)
	_t += real_delta
	trauma = maxf(trauma - real_delta * 1.4, 0.0)
	if camera == null or not is_instance_valid(camera):
		return
	var s := trauma * trauma
	camera.offset = Vector2(
		_noise.get_noise_2d(_t * 60.0, 0.0),
		_noise.get_noise_2d(0.0, _t * 60.0)
	) * 22.0 * s
	camera.rotation = _noise.get_noise_2d(_t * 45.0, 99.0) * 0.05 * s


# ------------------------------------------------------------ UI kit ------
# One visual system: consistent radii, shadows, and margins everywhere.

# Riso print language: near-square corners, a hairline ink border, and a
# hard offset "misprint" shadow in coral instead of a soft blur.

func ui_panel(bg := PAPER, alpha := 0.95, radius := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, alpha)
	sb.set_corner_radius_all(mini(radius, 5))
	sb.set_border_width_all(1)
	sb.border_color = Color(INK, 0.75)
	sb.shadow_color = Color(PINK, 0.55)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(5, 5)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func ui_chip(bg := PAPER, alpha := 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, alpha)
	sb.set_corner_radius_all(3)
	sb.set_border_width_all(1)
	sb.border_color = Color(INK, 0.55) if bg != INK else Color(PAPER, 0.30)
	sb.shadow_color = Color(INK, 0.35)
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(2, 2)
	sb.content_margin_left = 13
	sb.content_margin_right = 13
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb
