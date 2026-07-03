class_name Atmos
extends RefCounted
## World geometry and the sky gradient. y=0 is where the muon is born
## ("100 km up", with some poetic license); GROUND_Y is the detector lab.

const WORLD_DEPTH := 24000.0
const GROUND_Y := 23000.0
const DETECT_Y := 22820.0
const X_LIMIT := 1150.0

const LAYER_NAMES := ["thermosphere", "mesosphere", "stratosphere", "troposphere", "the ground"]

# [y, altitude_km] anchors for the piecewise altitude readout.
const BANDS := [
	[0.0, 100.0],
	[4000.0, 85.0],
	[9500.0, 50.0],
	[16000.0, 12.0],
	[23000.0, 0.0],
]

const SKY_YS := [-2500.0, 0.0, 4000.0, 9500.0, 16000.0, 20500.0, 23000.0]
const SKY_COLORS := [
	Color("0d0d20"),
	Color("14142e"),
	Color("2f3061"),
	Color("5b5f97"),
	Color("b18fc9"),
	Color("ffcfc2"),
	Color("fff5e1"),
]

const GRASS := Color("9fd39a")
const GRASS_DARK := Color("86bf85")


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
	if y >= GROUND_Y - 400.0:
		return 4
	if y >= 16000.0:
		return 3
	if y >= 9500.0:
		return 2
	if y >= 4000.0:
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
