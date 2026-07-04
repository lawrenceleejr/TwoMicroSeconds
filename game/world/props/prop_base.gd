extends Node2D
## Base for everything zappable in the atmosphere.

## Soft ambient shadow under the prop (0 = none) — cheap depth cue.
var shadow_size := 0.0
var shadow_drop := 40.0

var _muon: Node2D = null


func _ready() -> void:
	add_to_group("zappable")
	z_index = 2
	_setup()
	queue_redraw()


func _draw() -> void:
	if shadow_size <= 0.0:
		return
	# Print-hatch shadow: stacked ink strokes, shorter as they descend —
	# an engraver's mark, not a blurry oval.
	var half := shadow_size * 0.5
	for i in 3:
		var f := 1.0 - i * 0.3
		var y := shadow_drop + i * 4.0
		draw_line(Vector2(-half * f, y), Vector2(half * f, y),
			Color(Juice.INK, 0.10 - i * 0.02), 2.5)


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
