extends Node
## The juice drawer: screen shake, hitstop, and the game's pastel palette.

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

var _noise := FastNoiseLite.new()
var _t := 0.0
var _in_hitstop := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_noise.seed = 1137
	_noise.frequency = 2.0


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
