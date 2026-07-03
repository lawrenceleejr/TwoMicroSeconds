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


func muon() -> Node2D:
	if _muon == null or not is_instance_valid(_muon):
		_muon = get_tree().get_first_node_in_group("muon")
	return _muon


func muon_dist() -> float:
	var m := muon()
	if m == null:
		return 1e9
	return global_position.distance_to(m.global_position)
