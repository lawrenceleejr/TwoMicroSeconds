extends "res://game/world/props/prop_base.gd"
## A meteor, part of a shower. Streaks across the sky fast. Fly through one
## and it rips a chunk of your speed away — dodge them.

const SLOW := 150.0

var vel := Vector2(400.0, 900.0)
var _t := 0.0
var _trail := []
var _hit := false


func _setup() -> void:
	add_to_group("hazard")
	z_index = 4
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat


func _process(delta: float) -> void:
	_t += delta
	position += vel * delta
	_trail.push_front(global_position)
	if _trail.size() > 10:
		_trail.pop_back()
	var m := muon()
	if m != null and not _hit and m.get("alive") and muon_dist() < 44.0:
		_hit = true
		m.slow(SLOW, "meteor")
	# Cull once well past the muon or off the world.
	if m != null and global_position.y > (m as Node2D).global_position.y + 1400.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	# Trail (in local space) behind a bright head.
	var dir := vel.normalized()
	for i in _trail.size():
		var p: Vector2 = _trail[i] - global_position
		var f := 1.0 - float(i) / float(_trail.size())
		draw_circle(p, 3.0 + f * 4.0, Color(Juice.SUN.lerp(Juice.PINK, 1.0 - f), 0.5 * f))
	draw_line(-dir * 40.0, Vector2.ZERO, Color(Juice.CREAM, 0.7), 3.0, true)
	draw_circle(Vector2.ZERO, 7.0, Color(1, 1, 0.95))
	draw_circle(Vector2.ZERO, 11.0, Color(Juice.PINK, 0.4))
