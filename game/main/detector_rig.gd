extends Node3D
## A real 3D detector, built by `kind`, that the muon flies through on its
## way down: HAWC (surface water-Cherenkov tanks), ICECUBE (sensor strings
## in glacial ice), CMS (the LHC wheel), LZ (a xenon dark-matter TPC deep
## underground). Riso-flat surfacing; the warm rig light does the shading.
## The stage places each one at its true depth and scales it in on approach.

const CORAL := Color("ff5c4d")
const TEAL := Color("3ecfb2")
const AMBER := Color("ffb03a")
const PAPER := Color("e9e1cf")
const INK := Color("171226")
const VIOLET := Color("6a5cff")

var kind := "cms"
var label_text := "CMS"
var sub_text := ""

var _t := 0.0
var _shown := 0.0
var _target := 0.0
var _celebrate := 0.0
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _pulsers := []  # [MeshInstance3D, StandardMaterial3D, phase]


func _ready() -> void:
	visible = false
	scale = Vector3.ONE * 0.001
	match kind:
		"hawc": _build_hawc()
		"icecube": _build_icecube()
		"lz": _build_lz()
		_: _build_cms()
	_build_sign()

	# One warm key + a cool fill so the geometry reads as solid 3D.
	var key := OmniLight3D.new()
	key.position = Vector3(2.4, 2.6, 3.2)
	key.light_color = Color("ffd9a8")
	key.light_energy = 3.0
	key.omni_range = 16.0
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.6, -1.4, 2.4)
	fill.light_color = TEAL
	fill.light_energy = 1.0
	fill.omni_range = 12.0
	add_child(fill)


func _flat(c: Color, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic = 0.0
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m


func _cyl(r: float, h: float, c: Color, pos: Vector3, axis := "y", emit := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 32
	mi.mesh = m
	if axis == "z":
		mi.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	elif axis == "x":
		mi.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	mi.position = pos
	mi.material_override = _flat(c, emit)
	add_child(mi)
	return mi


func _disc(radius: float, thick: float, c: Color, z := 0.02) -> void:
	var mi := _cyl(radius, thick, c, Vector3(0, 0, z), "z")


func _torus(radius: float, tube: float, c: Color, z := 0.08, segs := 32) -> void:
	var t := MeshInstance3D.new()
	var m := TorusMesh.new()
	m.inner_radius = radius - tube
	m.outer_radius = radius + tube
	m.rings = 48
	m.ring_segments = segs
	t.mesh = m
	t.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	t.position = Vector3(0, 0, z)
	t.material_override = _flat(c)
	add_child(t)


func _sphere(r: float, c: Color, pos: Vector3, emit := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	mi.mesh = m
	mi.position = pos
	mi.material_override = _flat(c, emit)
	add_child(mi)
	return mi


# ---------------------------------------------------------------- CMS ------
# The unmistakable CMS shape: a big red CYLINDRICAL barrel lying on its
# side (beam axis horizontal), banded with silver rings and capped by the
# end-cap wheel. The muon plunges onto the top of the drum.
func _build_cms() -> void:
	var half := 2.3
	# The red solenoid drum, axis along X.
	_cyl(1.5, half * 2.0, CORAL, Vector3(0, 0, -0.4), "x")
	# Silver segment bands + ink rings around the drum.
	for bx: float in [-1.7, -0.85, 0.0, 0.85, 1.7]:
		_cyl(1.54, 0.16, Color("d8cdb6"), Vector3(bx, 0, -0.4), "x")
		_cyl(1.56, 0.05, INK, Vector3(bx + 0.42, 0, -0.4), "x")
	# End caps: the near one is the concentric wheel (with the beam spot).
	_cyl(1.5, 0.16, INK, Vector3(-half, 0, -0.4), "x")
	_cyl(1.52, 0.22, Color("caa23a"), Vector3(half, 0, -0.4), "x")   # far amber cap
	# Near-end wheel rings, standing off the +X face toward the camera.
	var fx := half + 0.14
	_ring_x(1.2, 0.22, CORAL, fx)
	_ring_x(0.78, 0.14, PAPER, fx + 0.02)
	_ring_x(0.44, 0.12, TEAL, fx + 0.04)
	_beam = _sphere(0.2, AMBER, Vector3(fx + 0.1, 0, 0), 2.2)
	_beam_mat = _beam.material_override


## A ring standing on the +X face (tube around the X axis).
func _ring_x(radius: float, tube: float, c: Color, x: float) -> void:
	var t := MeshInstance3D.new()
	var m := TorusMesh.new()
	m.inner_radius = radius - tube
	m.outer_radius = radius + tube
	m.rings = 40
	m.ring_segments = 16
	t.mesh = m
	t.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	t.position = Vector3(x, 0, 0)
	t.material_override = _flat(c)
	add_child(t)


# --------------------------------------------------------------- HAWC ------
# A grid of squat water-Cherenkov tanks on a sunlit surface pad.
func _build_hawc() -> void:
	var pad := _cyl(3.0, 0.2, Color("9a8f77"), Vector3(0, -0.4, -0.2), "y")
	for gx in range(-2, 3):
		for gy in range(-1, 2):
			var c := CORAL if (gx + gy) % 2 == 0 else PAPER
			_cyl(0.38, 0.5, c, Vector3(gx * 0.95, -0.15, -0.3 + gy * 0.9))
	# A bright sky-glow disc behind (surface, not a cavern).
	var glow := _sphere(0.9, AMBER, Vector3(0.0, 2.2, -1.0), 1.4)
	_beam = glow
	_beam_mat = glow.material_override


# ------------------------------------------------------------ ICECUBE ------
# Vertical sensor strings threaded with glowing DOMs, in blue ice.
func _build_icecube() -> void:
	var ice := _sphere(2.6, Color(0.55, 0.66, 0.78), Vector3(0, 0, -1.4), 0.0)
	ice.material_override.albedo_color = Color(0.55, 0.66, 0.78, 0.28)
	ice.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for s in range(-2, 3):
		var sx := s * 0.85
		_cyl(0.03, 3.4, Color(0.8, 0.9, 1.0), Vector3(sx, 0, -0.3))
		for d in range(5):
			var dom := _sphere(0.12, TEAL, Vector3(sx, 1.5 - d * 0.75, -0.3), 2.0)
			_pulsers.append([dom, dom.material_override, float(s) + d * 0.5])
	_beam = _sphere(0.18, Color(0.7, 0.95, 1.0), Vector3(0, 0, 0.1), 2.4)
	_beam_mat = _beam.material_override


# ----------------------------------------------------------------- LZ ------
# An upright xenon time-projection chamber: a glowing cylinder under a dome,
# in the deepest cavern of all.
func _build_lz() -> void:
	_cyl(1.5, 2.6, Color("2a2440"), Vector3(0, 0, -1.1))          # outer cryostat
	_cyl(1.15, 2.2, VIOLET, Vector3(0, 0, -0.7), "y", 0.5)       # xenon volume, aglow
	_torus(1.15, 0.14, PAPER, 1.1)                                 # top ring (PMT array)
	_torus(1.15, 0.14, PAPER, -1.1)                                # bottom ring
	# PMT dots around the top ring.
	for i in range(14):
		var a := float(i) / 14.0 * TAU
		var dom := _sphere(0.1, TEAL, Vector3(cos(a) * 1.15, 1.12, sin(a) * 1.15), 1.8)
		_pulsers.append([dom, dom.material_override, float(i)])
	_beam = _sphere(0.26, Color(0.8, 0.9, 1.0), Vector3(0, 0, 0.1), 2.6)
	_beam_mat = _beam.material_override


func _build_sign() -> void:
	var sign := Label3D.new()
	sign.text = label_text
	sign.font = Juice.ui_font
	sign.font_size = 72
	sign.pixel_size = 0.006
	sign.modulate = Color(PAPER, 0.95)
	sign.outline_modulate = Color(INK, 0.9)
	sign.outline_size = 14
	sign.position = Vector3(0, 3.0, 0.2)
	add_child(sign)
	if sub_text != "":
		var sub := Label3D.new()
		sub.text = sub_text
		sub.font = Juice.ui_font
		sub.font_size = 40
		sub.pixel_size = 0.006
		sub.modulate = Color(PAPER, 0.6)
		sub.outline_modulate = Color(INK, 0.8)
		sub.outline_size = 8
		sub.position = Vector3(0, 2.6, 0.2)
		add_child(sub)


func set_shown(v: float) -> void:
	_target = clampf(v, 0.0, 1.0)
	if _target > 0.01:
		visible = true


func celebrate() -> void:
	_celebrate = 4.0


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, _target, 1.0 - exp(-6.0 * delta))
	if _target <= 0.001 and _shown < 0.01:
		visible = false
		return
	scale = Vector3.ONE * maxf(_shown, 0.001)
	rotation.z = sin(_t * 0.12) * 0.05
	rotation.y = deg_to_rad(4.0) + sin(_t * 0.09) * 0.05
	_celebrate = maxf(_celebrate - delta, 0.0)
	if _beam_mat != null:
		var pulse := 1.6 + 0.5 * sin(_t * 3.0)
		if _celebrate > 0.0:
			pulse = 5.0 + 2.0 * sin(_t * 22.0)
		_beam_mat.emission_energy_multiplier = pulse
	for p in _pulsers:
		var m: StandardMaterial3D = p[1]
		var ph: float = p[2]
		m.emission_energy_multiplier = 1.2 + 1.0 * sin(_t * 2.5 + ph)
