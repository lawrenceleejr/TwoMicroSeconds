class_name Atmos
extends RefCounted
## World geometry and the sky gradient. y=0 is where the muon is born
## ("100 km up", poetic license). GROUND_Y is the surface. Below it the
## muon can punch through a whole STACK of real detectors, deeper and
## deeper, if it survives: HAWC on the surface, IceCube in the ice, CMS
## at 100 m, and — only for the boldest — the LZ dark-matter experiment
## 1.5 km down. Reaching LZ is the grand finale.

const GROUND_Y := 69000.0
const X_LIMIT := 1150.0

## Pixels per metre underground (CMS at 100 m sits 5650 px below ground).
const PX_PER_M := 56.5

## Detector-stack depths (world y).
const HAWC_Y := 69010.0     # ~0 m, surface water-Cherenkov array
const ICECUBE_Y := 72100.0  # ~55 m, strung through glacial ice
const CMS_Y := 74650.0      # 100 m, LHC Point 5
const LZ_Y := 108550.0      # ~700 m, deep dark-matter cavern (kept close
                            # enough that the descent between stays eventful)

## Legacy alias (first detection point) — kept for old references.
const DETECT_Y := 69010.0
const WORLD_DEPTH := 109600.0

## The detector stack, shallow → deep. Each is a fly-through: passing it
## "counts" you and pays a spark; the run only ends at decay or at LZ.
const DETECTORS := [
	{"kind": "hawc", "y": 69010.0, "depth_m": 0.0, "label": "HAWC", "sub": "surface array"},
	{"kind": "icecube", "y": 72100.0, "depth_m": 55.0, "label": "ICECUBE", "sub": "in the glacial ice"},
	{"kind": "cms", "y": 74650.0, "depth_m": 100.0, "label": "CMS", "sub": "LHC Point 5"},
	{"kind": "lz", "y": 108550.0, "depth_m": 700.0, "label": "LZ", "sub": "dark matter · deep underground"},
]

const LAYER_NAMES := [
	"thermosphere", "mesosphere", "stratosphere", "troposphere",
	"the ground", "underground",
]

# [y, altitude_km] anchors for the piecewise altitude readout.
const BANDS := [
	[0.0, 100.0],
	[12000.0, 85.0],
	[28500.0, 50.0],
	[48000.0, 12.0],
	[69000.0, 0.0],
]


## Metres below the surface (0 above ground).
static func depth_m_at(y: float) -> float:
	if y <= GROUND_Y:
		return 0.0
	return (y - GROUND_Y) / PX_PER_M


## The geological stratum at a given depth (for the labelled Earth layers).
static func strata_label_at(y: float) -> String:
	var d := depth_m_at(y)
	if d < 20.0:
		return "topsoil"
	if d < 75.0:
		return "glacial ice"
	if d < 140.0:
		return "bedrock"
	if d < 560.0:
		return "deep rock"
	return "the deep cavern"

# Riso dusk: violet-black space, electric violet upper air, a dusty mauve
# middle, a burnt coral dusk band into warm paper at the horizon — then
# below the turf, soil, a band of pale glacial ice, then rock darkening
# all the way down to the deep cavern.
const SKY_YS := [
	-7500.0, 0.0, 12000.0, 28500.0, 48000.0, 61500.0, 69000.0,
	69120.0, 70600.0, 72100.0, 73600.0, 76000.0, 120000.0, 153600.0,
]
const SKY_COLORS := [
	Color("0b0817"),
	Color("120e22"),
	Color("2b2350"),
	Color("53437e"),
	Color("a05f77"),
	Color("e08a5f"),
	Color("ecd9b8"),
	Color("6b5a4a"),   # topsoil
	Color("8fa6b8"),   # glacial ice (pale blue)
	Color("6f8494"),   # deeper ice
	Color("3a2c26"),   # bedrock
	Color("241a16"),   # deep rock
	Color("140f14"),   # deeper rock
	Color("0a0810"),   # the deep cavern
]

const GRASS := Color("7aa98c")
const GRASS_DARK := Color("618f77")


static func altitude_at(y: float) -> float:
	if y <= 0.0:
		return 100.0
	if y >= GROUND_Y:
		return 0.0
	for i in range(BANDS.size() - 1):
		var y0: float = BANDS[i][0]
		var y1: float = BANDS[i + 1][0]
		if y <= y1:
			var f := (y - y0) / (y1 - y0)
			return lerpf(BANDS[i][1], BANDS[i + 1][1], f)
	return 0.0


static func layer_index_at(y: float) -> int:
	if y >= GROUND_Y + 120.0:
		return 5
	if y >= GROUND_Y - 1200.0:
		return 4
	if y >= 48000.0:
		return 3
	if y >= 28500.0:
		return 2
	if y >= 12000.0:
		return 1
	return 0


static func sky_color_at(y: float) -> Color:
	if y <= float(SKY_YS[0]):
		return SKY_COLORS[0]
	for i in range(SKY_YS.size() - 1):
		var y1: float = SKY_YS[i + 1]
		if y < y1:
			var y0: float = SKY_YS[i]
			var f := (y - y0) / (y1 - y0)
			var c0: Color = SKY_COLORS[i]
			return c0.lerp(SKY_COLORS[i + 1], f)
	return SKY_COLORS[SKY_COLORS.size() - 1]
