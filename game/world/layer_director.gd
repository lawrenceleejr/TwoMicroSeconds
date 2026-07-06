extends Node2D
## Populates the world at the start of a run, keeps the mesosphere supplied
## with shooting stars, and runs the occasional meteor shower. The detector
## stack itself is 3D geometry owned by the stage, not placed here.

const Aurora := preload("res://game/world/props/aurora.gd")
const Satellite := preload("res://game/world/props/satellite.gd")
const RedSprite := preload("res://game/world/props/red_sprite.gd")
const ShootingStar := preload("res://game/world/props/shooting_star.gd")
const Noctilucent := preload("res://game/world/props/noctilucent_cloud.gd")
const Balloon := preload("res://game/world/props/weather_balloon.gd")
const Cloud := preload("res://game/world/props/cloud.gd")
const BirdFlock := preload("res://game/world/props/bird_flock.gd")
const Airplane := preload("res://game/world/props/airplane.gd")
const RadioWave := preload("res://game/world/props/radio_wave.gd")
const SpaceJunk := preload("res://game/world/props/space_junk.gd")
const Meteor := preload("res://game/world/props/meteor.gd")
const Discovery := preload("res://game/world/props/discovery.gd")

var _rng := RandomNumberGenerator.new()
var _star_timer := 2.0
var _shower_cd := 0.0
var _shower_left := 0.0
var _shower_timer := 0.0


func _ready() -> void:
	if Game.shoot_mode:
		_rng.seed = 12345  # deterministic world for the screenshot director
	else:
		_rng.randomize()
	_shower_cd = _rng.randf_range(14.0, 26.0)
	_spawn_all()


func _spawn_all() -> void:
	# Thermosphere: a DENSE field of auroras and satellites — the busy
	# opening where you fight for your first energy.
	for i in 8:
		_place(Aurora.new(), _rng.randf_range(-950, 950), 1400.0 + i * 1250.0 + _rng.randf_range(-400, 400))
	for i in 16:
		_place(Satellite.new(), _rng.randf_range(-1000, 1000), 1400.0 + i * 850.0 + _rng.randf_range(-350, 350))
	# Rare space junk drifting up high — AVOID it, it saps your speed.
	for i in 2:
		_place(SpaceJunk.new(), _rng.randf_range(-1000, 1000), _rng.randf_range(2200, 11000))
	# Below the ionosphere: stray radio waves you can surf for a boost.
	for i in 6:
		_place(RadioWave.new(), _rng.randf_range(-950, 950), 12500.0 + i * 2600.0 + _rng.randf_range(-700, 700))
	# Red sprites flicker over the mesosphere.
	for i in 3:
		_place(RedSprite.new(), _rng.randf_range(-800, 800), 15600.0 + i * 3900.0 + _rng.randf_range(-900, 900))
	# Mesosphere: noctilucent clouds (shooting stars spawn dynamically).
	for i in 4:
		_place(Noctilucent.new(), _rng.randf_range(-900, 900), _rng.randf_range(12900, 20900))
	# Stratosphere: weather balloons.
	for i in 6:
		_place(Balloon.new(), _rng.randf_range(-900, 900), 30600.0 + i * 2700.0 + _rng.randf_range(-800, 800))
	# Troposphere: clouds, birds, airplanes.
	for i in 8:
		_place(Cloud.new(), _rng.randf_range(-1000, 1000), _rng.randf_range(49800, 66700))
	for i in 4:
		_place(BirdFlock.new(), _rng.randf_range(-900, 900), _rng.randf_range(51600, 66900))
	for i in 3:
		_place(Airplane.new(), _rng.randf_range(-600, 600), 52800.0 + i * 3450.0 + _rng.randf_range(-750, 750))
	# Underground curiosities to discover on the long way down.
	var kinds := ["tomb", "oil", "tunnel"]
	for i in 7:
		var depth_y := _rng.randf_range(Atmos.GROUND_Y + 1500.0, Atmos.LZ_Y - 3000.0)
		_place(Discovery.new_kind(kinds[i % kinds.size()]), _rng.randf_range(-950, 950), depth_y)


func _place(node: Node2D, x: float, y: float) -> void:
	node.position = Vector2(x, y)
	add_child(node)


func _process(delta: float) -> void:
	var m := get_tree().get_first_node_in_group("muon")
	if m == null or not (m as Node2D).get("alive"):
		return
	var muon_y: float = (m as Node2D).global_position.y
	if Atmos.layer_index_at(muon_y) == 1:
		_star_timer -= delta
		if _star_timer <= 0.0:
			_star_timer = _rng.randf_range(3.0, 6.0)
			_spawn_star(m as Node2D)
	_update_meteor_shower(delta, m as Node2D, muon_y)


# ------------------------------------------------------- meteor shower ----
func _update_meteor_shower(delta: float, m: Node2D, muon_y: float) -> void:
	# Only up in the sky, and never during the birth intro.
	if muon_y > Atmos.GROUND_Y - 4000.0 or bool(m.get("intro_mode")):
		return
	if _shower_left > 0.0:
		_shower_left -= delta
		_shower_timer -= delta
		if _shower_timer <= 0.0:
			_shower_timer = _rng.randf_range(0.12, 0.34)
			_spawn_meteor(m)
		return
	_shower_cd -= delta
	if _shower_cd <= 0.0:
		# Kick off a shower: warn loudly, then rain meteors for a few s.
		_shower_cd = _rng.randf_range(22.0, 40.0)
		_shower_left = _rng.randf_range(4.5, 7.0)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud != null:
			hud.meteor_warning()
		Sfx.play("deny", -3.0, 0.0)


func _spawn_meteor(m: Node2D) -> void:
	var meteor: Node2D = Meteor.new()
	var from_left := _rng.randf() < 0.5
	var x := m.global_position.x + _rng.randf_range(-1100.0, 1100.0)
	meteor.position = Vector2(x, m.global_position.y - _rng.randf_range(500.0, 900.0))
	meteor.vel = Vector2((520.0 if from_left else -520.0) + _rng.randf_range(-120, 120),
		_rng.randf_range(760.0, 1180.0))
	add_child(meteor)


func _spawn_star(m: Node2D) -> void:
	var star: Node2D = ShootingStar.new()
	var from_left := _rng.randf() < 0.5
	var x := m.global_position.x + (-950.0 if from_left else 950.0)
	star.position = Vector2(x, m.global_position.y - _rng.randf_range(120.0, 420.0))
	star.vel = Vector2(700.0 if from_left else -700.0, _rng.randf_range(220.0, 420.0))
	add_child(star)
