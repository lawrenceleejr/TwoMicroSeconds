extends Node
## The juice drawer: palette, screen shake, hitstop, full-screen effect
## layers (relativity / vignette / glitch), and the shared UI style kit.
##
## Screen-effect layer order (UI lives above all of them, on layer 100):
##   world (0) -> relativity (70) -> vignette (80) -> glitch (90) -> UI (100)

const INK := Color("454063")
const CREAM := Color("fff5e1")
const PAPER := Color("fffaf0")
const PINK := Color("ffc2d1")
const BLUSH := Color("ffb3c6")
const MINT := Color("9ee7d9")
const LILAC := Color("b8b5e1")
const PERIWINKLE := Color("5b5f97")
const SUN := Color("ffe08a")
const RAIN := Color("8fb8e8")
const CONFETTI_COLORS: Array[Color] = [
	Color("ffc2d1"), Color("9ee7d9"), Color("ffe08a"), Color("b8b5e1"), Color("ffffff"),
]

var camera: Camera2D = null
var trauma := 0.0
## A friendly hand-written system font where available (macOS ships several);
## falls back to the default sans elsewhere.
var hand_font := SystemFont.new()

var _noise := FastNoiseLite.new()
var _t := 0.0
var _in_hitstop := false
var _glitch_rect: ColorRect
var _glitch_mat: ShaderMaterial
var _glitch_tween: Tween
var _rel_rect: ColorRect
var _rel_mat: ShaderMaterial


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = 1137
	_noise.frequency = 2.0
	hand_font.font_names = PackedStringArray(
		["Marker Felt", "Chalkboard SE", "Comic Sans MS", "Comic Neue"])
	_rel_mat = _build_screen_layer(70, "res://game/fx/relativity.gdshader", true)
	_rel_rect = _last_rect
	_build_screen_layer(80, "res://game/fx/vignette.gdshader", true)
	_glitch_mat = _build_screen_layer(90, "res://game/fx/glitch.gdshader", false)
	_glitch_rect = _last_rect


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
	_rel_rect.visible = strength > 0.02 or gamma_norm > 0.02
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

func ui_panel(bg := PAPER, alpha := 0.95, radius := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, alpha)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(INK, 0.22)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 3)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func ui_chip(bg := PAPER, alpha := 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, alpha)
	sb.set_corner_radius_all(99)
	sb.shadow_color = Color(INK, 0.16)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	sb.content_margin_left = 13
	sb.content_margin_right = 13
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb
