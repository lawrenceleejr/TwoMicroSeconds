class_name Atmos
extends RefCounted
## World geometry and the sky gradient. y=0 is where the muon is born
## ("100 km up", with some poetic license). GROUND_Y is the surface —
## but muons don't stop there: the run ends ~100 m down, in the CMS
## cavern at LHC Point 5.

const WORLD_DEPTH := 76000.0
const GROUND_Y := 69000.0
## The CMS cavern: crossing this depth counts you.
const DETECT_Y := 74450.0
const CMS_Y := 74650.0
const X_LIMIT := 1150.0

const LAYER_NAMES := [
	"thermosphere", "mesosphere", "stratosphere", "troposphere",
	"the ground", "the bedrock",
]

# [y, altitude_km] anchors for the piecewise altitude readout.
const BANDS := [
	[0.0, 100.0],
	[12000.0, 85.0],
	[28500.0, 50.0],
	[48000.0, 12.0],
	[69000.0, 0.0],
]


## Metres below the surface (0 above ground). The cavern sits at ~100 m,
## like the real one.
static func depth_m_at(y: float) -> float:
	if y <= GROUND_Y:
		return 0.0
	return (y - GROUND_Y) / (CMS_Y - GROUND_Y) * 100.0

# Riso dusk: violet-black space, electric violet upper air, a dusty mauve
# middle, a burnt coral dusk band into warm paper at the horizon — then
# below the turf, warm sediment inks darkening toward the cavern.
const SKY_YS := [
	-7500.0, 0.0, 12000.0, 28500.0, 48000.0, 61500.0, 69000.0,
	69120.0, 72500.0, 76000.0,
]
const SKY_COLORS := [
	Color("0b0817"),
	Color("120e22"),
	Color("2b2350"),
	Color("53437e"),
	Color("a05f77"),
	Color("e08a5f"),
	Color("ecd9b8"),
	Color("41302a"),
	Color("2b201c"),
	Color("171110"),
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
