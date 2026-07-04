extends Node
## Persistent meta-progression: sparks (earned by bumping satellites and
## finishing runs) buy a better origin story — a higher-energy production
## mechanism, which means a bigger Lorentz factor from birth.

signal sparks_changed

const SAVE_PATH := "user://two_microseconds_save.json"

const TIERS := [
	{
		"name": "solar flare",
		"flavor": "a modest belch from our own sun",
		"energy": "10 GeV",
		"gamma": 0.0,
		"cost": 0,
	},
	{
		"name": "red dwarf superflare",
		"flavor": "small star, terrible temper",
		"energy": "100 GeV",
		"gamma": 1.0,
		"cost": 2,
	},
	{
		"name": "supernova shock front",
		"flavor": "surf a dying star's blast wave, Fermi-style",
		"energy": "10 TeV",
		"gamma": 2.5,
		"cost": 4,
	},
	{
		"name": "pulsar wind nebula",
		"flavor": "spun up by a lighthouse made of star corpse",
		"energy": "1 PeV",
		"gamma": 4.0,
		"cost": 6,
	},
	{
		"name": "magnetar flare",
		"flavor": "the loudest magnet in the galaxy",
		"energy": "100 PeV",
		"gamma": 6.0,
		"cost": 9,
	},
	{
		"name": "active galactic nucleus",
		"flavor": "launched by a feeding supermassive black hole",
		"energy": "10 EeV",
		"gamma": 9.0,
		"cost": 12,
	},
	{
		"name": "the Oh-My-God particle",
		"flavor": "Utah, 1991. 3e20 eV. oh. my. god.",
		"energy": "320 EeV",
		"gamma": 14.0,
		"cost": 16,
	},
]

var sparks := 0
## Equipped origin (what you're born as). Any owned tier can be equipped —
## sometimes you want the slow sky back.
var tier := 0
## Highest origin purchased.
var owned_tier := 0
var total_sparks_earned := 0
## Proper lifetime (µs) of every decayed muon, ever. Exponentially
## distributed by construction; the mean converges on 2.2 as you play.
var lifetimes: Array = []
## Matching lab-frame durations (seconds) — γ-stretched, so NOT 2.2-anything.
var lifetimes_lab: Array = []


func _ready() -> void:
	_load()


func origin() -> Dictionary:
	return TIERS[tier]


func gamma_bonus() -> float:
	return TIERS[tier]["gamma"]


func is_max_tier() -> bool:
	return tier >= TIERS.size() - 1


func next_tier() -> Dictionary:
	return TIERS[mini(owned_tier + 1, TIERS.size() - 1)]


func can_upgrade() -> bool:
	return owned_tier < TIERS.size() - 1 and sparks >= int(next_tier()["cost"])


func equip(i: int) -> bool:
	if i < 0 or i > owned_tier or i == tier:
		return false
	tier = i
	_save()
	sparks_changed.emit()
	return true


func add_sparks(amount: int) -> void:
	sparks += amount
	total_sparks_earned += amount
	_save()
	sparks_changed.emit()


func record_lifetime(us: float, lab_seconds: float) -> void:
	lifetimes.append(snappedf(us, 0.001))
	lifetimes_lab.append(snappedf(lab_seconds, 0.01))
	if lifetimes.size() > 2000:
		lifetimes = lifetimes.slice(lifetimes.size() - 2000)
		lifetimes_lab = lifetimes_lab.slice(lifetimes_lab.size() - 2000)
	_save()


func lab_mean() -> float:
	if lifetimes_lab.is_empty():
		return 0.0
	var total := 0.0
	for v in lifetimes_lab:
		total += float(v)
	return total / lifetimes_lab.size()


func lifetime_mean() -> float:
	if lifetimes.is_empty():
		return 0.0
	var total := 0.0
	for v in lifetimes:
		total += float(v)
	return total / lifetimes.size()


func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	sparks -= int(next_tier()["cost"])
	owned_tier += 1
	tier = owned_tier  # a new origin equips itself; downgrade any time
	_save()
	sparks_changed.emit()
	return true


func reset_save() -> void:
	sparks = 0
	tier = 0
	owned_tier = 0
	total_sparks_earned = 0
	lifetimes = []
	lifetimes_lab = []
	_save()
	sparks_changed.emit()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"sparks": sparks,
		"tier": tier,
		"owned": owned_tier,
		"earned": total_sparks_earned,
		"lifetimes": lifetimes,
		"lifetimes_lab": lifetimes_lab,
	}))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		sparks = maxi(int(data.get("sparks", 0)), 0)
		tier = clampi(int(data.get("tier", 0)), 0, TIERS.size() - 1)
		owned_tier = clampi(int(data.get("owned", tier)), tier, TIERS.size() - 1)
		total_sparks_earned = maxi(int(data.get("earned", 0)), 0)
		var lts = data.get("lifetimes", [])
		if lts is Array:
			lifetimes = lts
		var lls = data.get("lifetimes_lab", [])
		if lls is Array:
			lifetimes_lab = lls
		lifetimes_lab.resize(lifetimes.size())
