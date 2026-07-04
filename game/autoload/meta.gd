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
		"flavor": "surf a dying star's blast wave (Fermi acceleration)",
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
		"flavor": "Utah, 1991. 3×10²⁰ eV. oh. my. god.",
		"energy": "320 EeV",
		"gamma": 14.0,
		"cost": 16,
	},
]

var sparks := 0
var tier := 0
var total_sparks_earned := 0


func _ready() -> void:
	_load()


func origin() -> Dictionary:
	return TIERS[tier]


func gamma_bonus() -> float:
	return TIERS[tier]["gamma"]


func is_max_tier() -> bool:
	return tier >= TIERS.size() - 1


func next_tier() -> Dictionary:
	return TIERS[mini(tier + 1, TIERS.size() - 1)]


func can_upgrade() -> bool:
	return not is_max_tier() and sparks >= int(next_tier()["cost"])


func add_sparks(amount: int) -> void:
	sparks += amount
	total_sparks_earned += amount
	_save()
	sparks_changed.emit()


func try_upgrade() -> bool:
	if not can_upgrade():
		return false
	sparks -= int(next_tier()["cost"])
	tier += 1
	_save()
	sparks_changed.emit()
	return true


func reset_save() -> void:
	sparks = 0
	tier = 0
	total_sparks_earned = 0
	_save()
	sparks_changed.emit()


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"sparks": sparks,
		"tier": tier,
		"earned": total_sparks_earned,
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
		total_sparks_earned = maxi(int(data.get("earned", 0)), 0)
