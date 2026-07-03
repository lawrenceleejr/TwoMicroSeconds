extends Node2D
## Confetti burst helper, used for task completions and celebrations.


static func confetti(parent: Node, pos: Vector2, amount := 26) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 9
	p.amount = amount
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 1.0
	p.spread = 180.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 260.0
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.scale_amount_min = 2.4
	p.scale_amount_max = 4.4
	var grad := Gradient.new()
	var colors := Juice.CONFETTI_COLORS
	for i in colors.size():
		var offset := float(i) / float(colors.size() - 1)
		if i == 0:
			grad.set_color(0, colors[0])
		elif i == colors.size() - 1:
			grad.set_color(1, colors[i])
		else:
			grad.add_point(offset, colors[i])
	p.color_initial_ramp = grad
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(1.6).timeout.connect(p.queue_free)
