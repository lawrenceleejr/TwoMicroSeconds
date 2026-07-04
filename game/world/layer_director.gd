extends Node2D
## Populates the atmosphere at the start of a run and keeps the
## mesosphere supplied with shooting stars while the muon is passing through.

const Aurora := preload("res://game/world/props/aurora.gd")
const Satellite := preload("res://game/world/props/satellite.gd")
const RedSprite := preload("res://game/world/props/red_sprite.gd")
const ShootingStar := preload("res://game/world/props/shooting_star.gd")
const Noctilucent := preload("res://game/world/props/noctilucent_cloud.gd")
const Balloon := preload("res://game/world/props/weather_balloon.gd")
const Cloud := preload("res://game/world/props/cloud.gd")
const BirdFlock := preload("res://game/world/props/bird_flock.gd")
const Airplane := preload("res://game/world/props/airplane.gd")
const Detector := preload("res://game/world/props/detector.gd")

var detector: Node2D

var _rng := RandomNumberGenerator.new()
var _star_timer := 2.0


func _ready() -> void:
	if Game.shoot_mode:
		_rng.seed = 12345  # deterministic world for the screenshot director
	else:
		_rng.randomize()
	_spawn_all()


func _spawn_all() -> void:
	# Thermosphere: auroras and satellites — the early fields you live on.
	for i in 5:
		_place(Aurora.new(), _rng.randf_range(-850, 850), 600.0 + i * 640.0 + _rng.randf_range(-180, 180))
	for i in 10:
		_place(Satellite.new(), _rng.randf_range(-950, 950), 600.0 + i * 480.0 + _rng.randf_range(-160, 160))
	# Red sprites flicker over the mesosphere.
	for i in 3:
		_place(RedSprite.new(), _rng.randf_range(-800, 800), 5200.0 + i * 1300.0 + _rng.randf_range(-300, 300))
	# Mesosphere: noctilucent clouds (shooting stars spawn dynamically).
	for i in 3:
		_place(Noctilucent.new(), _rng.randf_range(-900, 900), _rng.randf_range(4300, 6300))
	# Stratosphere: weather balloons.
	for i in 5:
		_place(Balloon.new(), _rng.randf_range(-900, 900), 10200.0 + i * 1050.0 + _rng.randf_range(-300, 300))
	# Troposphere: clouds, birds, airplanes.
	for i in 7:
		_place(Cloud.new(), _rng.randf_range(-1000, 1000), _rng.randf_range(16600, 21900))
	for i in 4:
		_place(BirdFlock.new(), _rng.randf_range(-900, 900), _rng.randf_range(17200, 22300))
	for i in 3:
		_place(Airplane.new(), _rng.randf_range(-600, 600), 17600.0 + i * 1150.0 + _rng.randf_range(-250, 250))
	# The finish line.
	detector = Detector.new()
	_place(detector, 0.0, Atmos.GROUND_Y - 26.0)


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


func _spawn_star(m: Node2D) -> void:
	var star: Node2D = ShootingStar.new()
	var from_left := _rng.randf() < 0.5
	var x := m.global_position.x + (-950.0 if from_left else 950.0)
	star.position = Vector2(x, m.global_position.y - _rng.randf_range(120.0, 420.0))
	star.vel = Vector2(700.0 if from_left else -700.0, _rng.randf_range(220.0, 420.0))
	add_child(star)
