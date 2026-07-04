extends Node3D
## The presentation stage. Gameplay is the same flat 2D world, rendered
## into a SubViewport and textured onto a quad in a real 3D scene. A
## perspective camera sits at a slight angle, banks into turns, and
## breathes with speed; translucent wisps float in front of the plane
## for true depth parallax. The UI lives on the real screen, crisp.

const BASE_W := 1280.0
const BASE_H := 720.0
const OVERSCAN := 1.5
const CAM_FOV := 55.0
const TILT_DEG := -13.0
const YAW_DEG := 6.5

var _vp: SubViewport
var _cam: Camera3D
var _muon
var _wisps := []
var _bank := 0.0
var _t := 0.0
var _env: Environment


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.size = Vector2i(int(BASE_W * OVERSCAN), int(BASE_H * OVERSCAN))
	add_child(_vp)
	_vp.add_child(load("res://game/main/main.tscn").instantiate())
	Juice.create_relativity_in(_vp)

	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	# The un-overscanned frame is 7.2 units tall at the camera distance
	# below; the quad carries the overscan margin so the tilt never
	# reveals the void.
	mesh.size = Vector2(12.8, 7.2) * OVERSCAN
	quad.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vp.get_texture()
	quad.material_override = mat
	add_child(quad)

	_cam = Camera3D.new()
	_cam.fov = CAM_FOV
	add_child(_cam)

	var world_env := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	# Followed to the local sky color each frame, so anything the steeper
	# tilt reveals past the quad blends into the sky instead of reading
	# as an edge.
	_env.background_color = Color("101024")
	world_env.environment = _env
	add_child(world_env)

	_spawn_wisps()


func _spawn_wisps() -> void:
	var texs := ["res://assets/sprites/cloud.svg", "res://assets/sprites/noctilucent.svg"]
	for i in 12:
		var s := Sprite3D.new()
		s.texture = load(texs[i % texs.size()])
		s.pixel_size = 0.012 + (i % 4) * 0.005
		s.modulate = Color(1, 1, 1, 0.07 + 0.045 * (i % 4))
		# A wide depth spread: near wisps whip past, far ones drift —
		# the speed difference is what sells the depth.
		s.position = Vector3(randf_range(-7.5, 7.5), randf_range(-5.5, 5.5),
			randf_range(1.2, 4.4))
		add_child(s)
		_wisps.append(s)


func _process(delta: float) -> void:
	_t += delta
	if _muon == null or not is_instance_valid(_muon):
		_muon = get_tree().get_first_node_in_group("muon")
	var vel := Vector2.ZERO
	if _muon != null:
		vel = _muon.velocity
	var speed_f := clampf(vel.length() / 1250.0, 0.0, 1.0)

	# Bank into turns; widen the lens with speed.
	var target_bank := clampf(-vel.x / 2500.0, -1.0, 1.0) * 0.11
	_bank = lerpf(_bank, target_bank, 1.0 - exp(-3.0 * delta))
	_cam.fov = lerpf(_cam.fov, CAM_FOV + 9.0 * speed_f, 1.0 - exp(-3.0 * delta))

	# Keep the un-overscanned frame filling the window at any fov, then
	# tilt hard: the oblique perspective is the whole point.
	var d := 7.2 / (2.0 * tan(deg_to_rad(_cam.fov * 0.5)))
	_cam.position = Vector3(sin(_t * 0.23) * 0.08, 0.42 + sin(_t * 0.31) * 0.05, d)
	_cam.rotation = Vector3(deg_to_rad(TILT_DEG), deg_to_rad(YAW_DEG) + sin(_t * 0.17) * 0.012, _bank)

	# Blend the void behind/around the quad into the local sky so the
	# steep angle never reads as a floating rectangle.
	if _muon != null and _env != null:
		var sky := Atmos.sky_color_at(_muon.global_position.y - 260.0)
		_env.background_color = _env.background_color.lerp(sky.darkened(0.25), 1.0 - exp(-2.0 * delta))

	# Foreground wisps: genuine 3D parallax against the gameplay plane —
	# nearer wisps stream past faster as the muon falls.
	for w in _wisps:
		w.position.y += vel.y * delta * 0.001 * w.position.z
		w.position.x += -vel.x * delta * 0.0004 * w.position.z \
			+ sin(_t * 0.1 + w.position.z * 3.0) * delta * 0.05
		if w.position.y > 6.5:
			w.position.y = -6.5
			w.position.x = randf_range(-7.5, 7.5)
		elif w.position.y < -6.5:
			w.position.y = 6.5
			w.position.x = randf_range(-7.5, 7.5)
		if w.position.x > 9.0:
			w.position.x = -9.0
		elif w.position.x < -9.0:
			w.position.x = 9.0
