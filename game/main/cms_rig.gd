extends Node3D
## CMS as REAL 3D geometry, sitting in the cavern at LHC Point 5 — a
## cylindrical barrel receding into the dark and a concentric end-cap
## wheel facing the diver. Lives in the stage's 3D scene (behind the flat
## gameplay plane), so the muon plunges into a detector with actual depth.
##
## Riso-flat surfacing: hard flat inks, no gloss, a rim of ink on the
## yoke. The warm cavern light does the shading.

const CORAL := Color("ff5c4d")
const TEAL := Color("3ecfb2")
const AMBER := Color("ffb03a")
const PAPER := Color("e9e1cf")
const INK := Color("171226")

var _t := 0.0
var _shown := 0.0
var _target := 0.0
var _celebrate := 0.0
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _lights := []


func _ready() -> void:
	visible = false
	scale = Vector3.ONE * 0.001

	# --- Barrel: the solenoid, receding into the dark cavern wall (the
	# opaque rock back-plane behind us is the cavern backdrop, so the
	# barrel just needs to reach toward it). --------------------------------
	_ring(1.95, 2.35, -0.2, -2.3, CORAL, 16)   # outer coil band
	var barrel := MeshInstance3D.new()
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 1.7
	bmesh.bottom_radius = 1.7
	bmesh.height = 2.2
	bmesh.radial_segments = 28
	barrel.mesh = bmesh
	barrel.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	barrel.position = Vector3(0, 0, -1.3)
	barrel.material_override = _flat(Color("d8cdb6"))
	add_child(barrel)

	# --- End-cap wheel: concentric rings facing the diver ----------------
	_disc(2.35, 0.16, INK)                 # ink back rim
	_yoke_ring()                            # coral yoke wedges (torus)
	_disc(1.5, 0.10, PAPER)                # paper cryostat face
	_ring_torus(1.02, 0.16, INK)           # bolt-ink separator
	_disc(0.95, 0.08, Color("d8cdb6"))     # tracker housing
	_ring_torus(0.62, 0.12, TEAL)          # teal tracker ring
	_disc(0.42, 0.06, PAPER)               # inner face

	# Beam spot: the bright amber eye the muon dives into.
	_beam = MeshInstance3D.new()
	var beam_mesh := SphereMesh.new()
	beam_mesh.radius = 0.16
	beam_mesh.height = 0.32
	_beam.mesh = beam_mesh
	_beam.position = Vector3(0, 0, 0.12)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.albedo_color = AMBER
	_beam_mat.emission_enabled = true
	_beam_mat.emission = AMBER
	_beam_mat.emission_energy_multiplier = 2.2
	_beam.material_override = _beam_mat
	add_child(_beam)

	# --- Lights: warm key + amber fill from the beam ---------------------
	var key := OmniLight3D.new()
	key.position = Vector3(2.2, 2.4, 3.0)
	key.light_color = Color("ffd9a8")
	key.light_energy = 3.2
	key.omni_range = 14.0
	add_child(key)
	_lights.append(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.6, -1.4, 2.2)
	fill.light_color = TEAL
	fill.light_energy = 1.1
	fill.omni_range = 10.0
	add_child(fill)
	_lights.append(fill)

	# --- Sign, stencilled above the wheel --------------------------------
	var sign := Label3D.new()
	sign.text = "CMS · LHC POINT 5"
	sign.font = Juice.ui_font
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.modulate = Color(PAPER, 0.92)
	sign.outline_modulate = Color(INK, 0.9)
	sign.outline_size = 12
	sign.position = Vector3(0, 2.9, 0.2)
	sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(sign)


## A flat unshaded-ish ink material (still lit, but matte and saturated).
func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 1.0
	m.metallic = 0.0
	return m


## A thin disc (short cylinder) facing +Z at depth z.
func _disc(radius: float, thick: float, c: Color) -> void:
	var d := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = thick
	m.radial_segments = 40
	d.mesh = m
	d.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	d.position = Vector3(0, 0, 0.02)
	d.material_override = _flat(c)
	add_child(d)


## A torus ring facing the camera (ring in the XY plane).
func _ring_torus(radius: float, tube: float, c: Color) -> void:
	var t := MeshInstance3D.new()
	var m := TorusMesh.new()
	m.inner_radius = radius - tube
	m.outer_radius = radius + tube
	m.rings = 32
	t.mesh = m
	t.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	t.position = Vector3(0, 0, 0.08)
	t.material_override = _flat(c)
	add_child(t)


## The coral yoke: a fat torus standing in for the 12-segment wheel.
func _yoke_ring() -> void:
	var t := MeshInstance3D.new()
	var m := TorusMesh.new()
	m.inner_radius = 1.5
	m.outer_radius = 2.3
	m.rings = 48
	m.ring_segments = 16
	t.mesh = m
	t.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	t.position = Vector3(0, 0, 0.05)
	t.material_override = _flat(CORAL)
	add_child(t)


## A cylindrical coil band from z0 to z1 (for the barrel's outer coils).
func _ring(r_in: float, r_out: float, z0: float, z1: float, c: Color, _seg: int) -> void:
	var t := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = r_out
	m.bottom_radius = r_out
	m.height = absf(z1 - z0)
	m.radial_segments = 32
	t.mesh = m
	t.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	t.position = Vector3(0, 0, (z0 + z1) * 0.5)
	var mat := _flat(c)
	t.material_override = mat
	add_child(t)


func reveal() -> void:
	_target = 1.0
	visible = true


func celebrate() -> void:
	_celebrate = 4.0


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, _target, 1.0 - exp(-4.0 * delta))
	if _target <= 0.0 and _shown < 0.01:
		visible = false
		return
	# Rise into place with a little elastic overshoot on the scale.
	var s := _shown * (1.0 + 0.06 * sin(_t * 2.0) * clampf(1.0 - _shown, 0.0, 1.0))
	scale = Vector3.ONE * maxf(s, 0.001)
	# Slow majestic spin so the 3D form reads unmistakably.
	rotation.z = sin(_t * 0.12) * 0.06
	rotation.y = deg_to_rad(4.0) + sin(_t * 0.09) * 0.05
	# Beam breathes; blazes when it counts you.
	_celebrate = maxf(_celebrate - delta, 0.0)
	var pulse := 1.6 + 0.6 * sin(_t * 3.0)
	if _celebrate > 0.0:
		pulse = 5.0 + 2.0 * sin(_t * 22.0)
		_beam_mat.emission = AMBER.lerp(TEAL, 0.5 + 0.5 * sin(_t * 18.0))
	else:
		_beam_mat.emission = AMBER
	_beam_mat.emission_energy_multiplier = pulse
	var boom := 0.4 if _celebrate > 0.0 else 0.0
	_beam.scale = Vector3.ONE * (1.0 + 0.12 * sin(_t * 3.0) + boom)
