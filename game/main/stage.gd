extends Node3D
## The presentation stage. Gameplay stays flat 2D, but the world is split
## across REAL depth planes in a 3D scene:
##
##   z -2.6  sky plane        (gradient, far haze, horizon slab)
##   z -2..+1.3  cloud meshes (actual translucent 3D geometry, lit)
##   z  0.0  gameplay plane   (props, muon, stars, ground — transparent bg)
##   z +1.7  near-haze plane  (transparent, drifts in front of the action)
##
## A perspective camera sits at a hard oblique angle, banks into turns,
## breathes with speed, and dollies with the muon's velocity — the planes
## genuinely parallax against each other. The UI lives on the real screen.

const AtmosphereScript := preload("res://game/world/atmosphere.gd")
const DetectorRigScript := preload("res://game/main/detector_rig.gd")

const BASE_W := 1280.0
const BASE_H := 720.0
const OVERSCAN := 1.5
## Haze planes (sky, near fog) render at this fraction of the gameplay
## viewport's resolution — they're low-detail, so it's a free ~4x saving.
const HAZE_RES := 0.5
const CAM_FOV := 55.0
# The camera sits LOW and pitches UP: the sky overhead recedes with real
# perspective (a true vanishing point far above, from foreshortening —
# nothing painted), and the low grazing angle maximizes plane parallax.
const TILT_DEG := 13.0
const YAW_DEG := 9.0
const CAM_Y := -0.95
const BACK_Z := -2.6
const FRONT_Z := 1.7

var _vp: SubViewport
var _vp_back: SubViewport
var _vp_front: SubViewport
var _cam: Camera3D
var _cam_back: Camera2D
var _cam_front: Camera2D
var _muon
var _wisps := []
var _blobs := []
var _bank := 0.0
var _t := 0.0
var _dolly := Vector3.ZERO
var _env: Environment
var _rigs := []  # [{node, y, kind}] — the detector stack, one per depth
var _discovery := false
var _disc_t := 0.0
var _muon_x := 0.0
var _q := 1.0  # internal-resolution scale (lower on phones)


## A depth-plane viewport size: overscanned base × mobile quality × the
## plane's own detail fraction, floored so it never collapses to nothing.
func _vp_size(frac: float) -> Vector2i:
	return Vector2i(
		maxi(320, int(BASE_W * OVERSCAN * _q * frac)),
		maxi(180, int(BASE_H * OVERSCAN * _q * frac)))


func _ready() -> void:
	Game.stage_planes = true
	var d0 := 7.2 / (2.0 * tan(deg_to_rad(CAM_FOV * 0.5)))
	# Phones render three full-res viewports every frame under Forward+ —
	# the biggest heat source. Drop the internal resolution on touch, and
	# render the two blurry haze planes at half of that (they're just
	# gradients and fog, so it's invisible but quarters their pixel cost).
	_q = 0.66 if Game.is_touch() else 1.0

	# --- Sky plane (far) ---------------------------------------------------
	_vp_back = SubViewport.new()
	_vp_back.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp_back.size = _vp_size(HAZE_RES)
	add_child(_vp_back)
	var back_root := Node2D.new()
	var back_atmo = AtmosphereScript.new()
	back_atmo.mode = "back"
	back_root.add_child(back_atmo)
	_cam_back = Camera2D.new()
	back_root.add_child(_cam_back)
	_vp_back.add_child(back_root)
	_cam_back.make_current()
	# Generous margin: the dolly + bank can reach well past the frustum.
	# The sky contracts and Doppler-shifts too (relativity on its quad).
	var back_scale := (d0 - BACK_Z) / d0 * 1.6
	_make_plane(_vp_back, BACK_Z, back_scale, false, true)

	# --- Gameplay plane ----------------------------------------------------
	_vp = SubViewport.new()
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.size = _vp_size(1.0)
	_vp.transparent_bg = true
	add_child(_vp)
	_vp.add_child(load("res://game/main/main.tscn").instantiate())
	_make_plane(_vp, 0.0, 1.0, true, true)

	# --- Near-haze plane (in front of the action) --------------------------
	_vp_front = SubViewport.new()
	_vp_front.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp_front.size = _vp_size(HAZE_RES)
	_vp_front.transparent_bg = true
	add_child(_vp_front)
	var front_root := Node2D.new()
	var front_atmo = AtmosphereScript.new()
	front_atmo.mode = "front"
	front_root.add_child(front_atmo)
	_cam_front = Camera2D.new()
	front_root.add_child(_cam_front)
	_vp_front.add_child(front_root)
	_cam_front.make_current()
	var front_scale := (d0 - FRONT_Z) / d0 * 1.3
	_make_plane(_vp_front, FRONT_Z, front_scale, true, false)

	_cam = Camera3D.new()
	_cam.fov = CAM_FOV
	add_child(_cam)

	var world_env := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	# Followed to the local sky color each frame, so anything the oblique
	# angle reveals past the planes blends into sky, never a hard edge.
	_env.background_color = Color("120e22")
	world_env.environment = _env
	add_child(world_env)

	# CMS lives behind the gameplay plane (z < 0), seen at the camera's
	# oblique angle so its barrel genuinely recedes. Hidden until the
	# muon punches underground.
	add_to_group("stage")
	# The detector stack: HAWC, IceCube, CMS, LZ — each built as real 3D
	# geometry, placed at its true depth, flown through on the way down.
	for det in Atmos.DETECTORS:
		var rig = DetectorRigScript.new()
		rig.kind = det["kind"]
		rig.label_text = det["label"]
		rig.sub_text = det["sub"]
		add_child(rig)
		_rigs.append({"node": rig, "y": float(det["y"]), "kind": det["kind"]})

	_spawn_wisps()
	_spawn_blobs()


## main.gd calls this as the muon flies through each detector.
func celebrate_kind(kind: String) -> void:
	for r in _rigs:
		if r["kind"] == kind and is_instance_valid(r["node"]):
			r["node"].celebrate()


## The grand finale: the camera pans and tilts up toward space.
func begin_discovery() -> void:
	_discovery = true


func _make_plane(vp: SubViewport, z: float, s: float, transparent: bool,
		relativity := false) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	# 7.2 world-units tall fills the un-overscanned frame at the camera
	# distance; each plane is scaled for its depth plus a safety margin.
	mesh.size = Vector2(12.8, 7.2) * OVERSCAN * s
	quad.mesh = mesh
	if relativity:
		# The plane displaces its own texture in place — the ONLY draw of
		# this viewport, so contraction never leaves a doubled original.
		quad.material_override = Juice.make_relativity_material(vp.get_texture())
	else:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_texture = vp.get_texture()
		if transparent:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad.material_override = mat
	quad.position = Vector3(0.0, 0.0, z)
	add_child(quad)
	return quad


## Set dressing between the planes: printed fog bands (flat strata bars,
## not soft ovals) and four-point star glints. The glints are the
## near-field starfield — real 3D points that slide with the dolly.
func _spawn_wisps() -> void:
	for i in 6:
		var s := Sprite3D.new()
		s.texture = load("res://assets/sprites/fogband.svg")
		s.pixel_size = 0.010 + (i % 3) * 0.004
		s.modulate = Color(1, 1, 1, 0.06 + 0.04 * (i % 3))
		s.position = Vector3(randf_range(-7.5, 7.5), randf_range(-5.5, 5.5),
			randf_range(-1.8, 1.3))
		add_child(s)
		_wisps.append(s)


func _spawn_blobs() -> void:
	for i in 10:
		var g := Sprite3D.new()
		g.texture = load("res://assets/sprites/glint.svg")
		g.pixel_size = 0.0022 + (i % 4) * 0.0012
		g.modulate = Color(1, 1, 1, 0.30 + 0.14 * (i % 3))
		g.position = Vector3(randf_range(-8.0, 8.0), randf_range(-5.5, 5.5),
			randf_range(0.3, 3.8))
		add_child(g)
		_blobs.append(g)


func _process(delta: float) -> void:
	_t += delta
	if _muon == null or not is_instance_valid(_muon):
		_muon = get_tree().get_first_node_in_group("muon")
	var vel := Vector2.ZERO
	if _muon != null:
		vel = _muon.velocity
	var speed_f := clampf(vel.length() / 1250.0, 0.0, 1.0)

	# Keep the depth-plane cameras in lockstep with the gameplay camera
	# (including shake) — the 3D scene supplies all the parallax.
	var gcam := Juice.camera
	if gcam != null and is_instance_valid(gcam):
		var center := gcam.get_screen_center_position()
		for c: Camera2D in [_cam_back, _cam_front]:
			c.global_position = center
			c.offset = gcam.offset
			c.rotation = gcam.rotation
			c.zoom = gcam.zoom

	# Bank into turns; widen the lens with speed.
	var target_bank := clampf(-vel.x / 2500.0, -1.0, 1.0) * 0.12
	_bank = lerpf(_bank, target_bank, 1.0 - exp(-3.0 * delta))
	_cam.fov = lerpf(_cam.fov, CAM_FOV + 9.0 * speed_f, 1.0 - exp(-3.0 * delta))

	# Velocity dolly: the 3D camera physically moves with the muon, so the
	# sky, cloud meshes, action, and near haze slide against each other.
	var dolly_target := Vector3(
		clampf(vel.x * 0.00040, -0.45, 0.45),
		clampf(-vel.y * 0.00026, -0.30, 0.30),
		0.0)
	_dolly = _dolly.lerp(dolly_target, 1.0 - exp(-2.2 * delta))

	# Keep the un-overscanned frame filling the window at any fov, then
	# sit low and pitch up: the oblique perspective is the whole point.
	var d := 7.2 / (2.0 * tan(deg_to_rad(_cam.fov * 0.5)))
	var tilt := TILT_DEG
	if _discovery:
		# The finale: rise and level off, tilting from the oblique dive
		# toward looking straight out as the world scrolls up to space.
		_disc_t += delta
		tilt = lerpf(TILT_DEG, -6.0, clampf(_disc_t / 5.0, 0.0, 1.0))
		d += clampf(_disc_t / 6.0, 0.0, 1.0) * 1.3
	_cam.position = Vector3(sin(_t * 0.23) * 0.08, CAM_Y + sin(_t * 0.31) * 0.05, d) + _dolly
	_cam.rotation = Vector3(deg_to_rad(tilt), deg_to_rad(YAW_DEG) + sin(_t * 0.17) * 0.012, _bank)

	# Blend the void past the planes into the local sky.
	if _muon != null and _env != null:
		var sky := Atmos.sky_color_at(_muon.global_position.y - 260.0)
		_env.background_color = _env.background_color.lerp(sky.darkened(0.25), 1.0 - exp(-2.0 * delta))

	# Publish the muon's real-screen position so UI panels can duck out of
	# its way. `lp` is the muon's point on the gameplay quad in stage space.
	var cam_center := Vector2.ZERO
	if _muon != null and gcam != null and is_instance_valid(gcam):
		cam_center = gcam.get_screen_center_position()
		var dpx: Vector2 = _muon.global_position - cam_center
		var lp := Vector3(dpx.x * (12.8 / BASE_W), -dpx.y * (7.2 / BASE_H), 0.0)
		Game.muon_screen_pos = _cam.unproject_position(lp)
		_muon_x = lp.x

	# Place each detector rig at its true depth (behind the play plane),
	# horizontally anchored to the muon so it's flown through clean. Scale
	# it in only when the muon is within a couple screens of that depth.
	if gcam != null and is_instance_valid(gcam):
		for r in _rigs:
			var rig = r["node"]
			if not is_instance_valid(rig):
				continue
			var dy: float = float(r["y"]) - cam_center.y   # world px below camera
			var qy: float = -dy * (7.2 / BASE_H)            # stage-space y
			var near: float = clampf(1.0 - absf(dy) / 2000.0, 0.0, 1.0)
			rig.set_shown(near)
			var tgt := Vector3(_muon_x, qy - 0.15, -1.15)
			rig.position = rig.position.lerp(tgt, 1.0 - exp(-6.0 * delta))

	# Drift the set dressing. Apparent speed scales with how far in front
	# of the play plane a piece sits (true parallax rates).
	for w in _wisps:
		_drift(w, vel, delta)
	for b in _blobs:
		_drift(b, vel, delta)


func _drift(w: Node3D, vel: Vector2, delta: float) -> void:
	var par := maxf(0.15, 1.0 + w.position.z * 0.45)
	w.position.y += vel.y * delta * 0.0011 * par
	w.position.x += -vel.x * delta * 0.0004 * par \
		+ sin(_t * 0.1 + w.position.z * 3.0) * delta * 0.05
	if w.position.y > 6.5:
		w.position.y = -6.5
		w.position.x = randf_range(-8.0, 8.0)
	elif w.position.y < -6.5:
		w.position.y = 6.5
		w.position.x = randf_range(-8.0, 8.0)
	if w.position.x > 9.5:
		w.position.x = -9.5
	elif w.position.x < -9.5:
		w.position.x = 9.5
