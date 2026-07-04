extends Node2D
## Base for everything zappable in the atmosphere.

var _muon: Node2D = null


func _ready() -> void:
	add_to_group("zappable")
	z_index = 2
	_setup()


func _setup() -> void:
	pass


func zapped(_source: Node2D) -> void:
	pass


## Adds a sprite child (SVG art from assets/sprites/).
func make_sprite(path: String, sprite_scale: float, pos := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.scale = Vector2.ONE * sprite_scale
	s.position = pos
	add_child(s)
	return s


## Adds a drawing layer ABOVE any sprites (faces, lights, dynamic bits).
## The callback receives the layer node and should call draw_* on it.
func make_overlay(callback: Callable) -> Node2D:
	var layer := Node2D.new()
	add_child(layer)
	layer.draw.connect(func() -> void: callback.call(layer))
	return layer


func muon() -> Node2D:
	if _muon == null or not is_instance_valid(_muon):
		_muon = get_tree().get_first_node_in_group("muon")
	return _muon


func muon_dist() -> float:
	var m := muon()
	if m == null:
		return 1e9
	return global_position.distance_to(m.global_position)
