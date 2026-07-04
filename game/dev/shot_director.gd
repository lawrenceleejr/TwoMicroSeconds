extends Node
## Screenshot director (`game -- --shoot`): drives the game through scripted
## moments and saves PNGs to user://shots/. CI runs this under Xvfb and
## uploads the images, closing the visual feedback loop.

var _dir := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dir = OS.get_user_data_dir().path_join("shots")
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _run() -> void:
	await _wait(1.4)
	await _shot("01_title")
	_press(KEY_U)
	await _wait(0.5)
	await _shot("02_shop")
	_press(KEY_U)
	await _wait(0.3)
	Game.start_run()
	await _wait(0.95)
	await _shot("03_birth")
	await _wait(1.0)  # let the pion decay hand over control

	var muon := get_tree().get_first_node_in_group("muon")
	if muon == null:
		_finish()
		return

	# Aurora glide: aim at a real aurora and fly through its ribbon.
	var aurora := _nearest_in_group("aurora", Vector2(0, 1800))
	if aurora != null:
		muon.set("global_position", aurora.global_position + Vector2(-320, -60))
		muon.set("autopilot", Vector2(1, 0.15))
		await _wait(0.55)
		await _shot("04_aurora")

	# Satellite bump, captured mid-glitch. Set heading directly — steering
	# alone can't turn fast enough to line up the hit.
	var sat := _nearest_in_group("satellite", muon.get("global_position"))
	if sat != null:
		muon.set("global_position", sat.global_position + Vector2(0, -120))
		muon.set("heading", Vector2.DOWN)
		muon.set("autopilot", Vector2(0, 1))
		await _wait(0.34)
		await _shot("05_satellite_glitch")
		await _wait(0.8)

	# High-speed streak through the mesosphere (post-boost).
	muon.set("global_position", Vector2(-500, 6000))
	muon.set("autopilot", Vector2(1, 0.35))
	muon.call("boost", 500.0, "director's orders")
	await _wait(0.7)
	await _shot("06_speed")

	# Troposphere: zap among the clouds.
	muon.set("global_position", Vector2(0, 19500))
	muon.set("autopilot", Vector2(0.5, 0.6))
	await _wait(0.5)
	muon.call("_zap")
	await _wait(0.12)
	await _shot("07_zap")

	# Detection and the end screen.
	muon.set("global_position", Vector2(0, 22400))
	muon.set("autopilot", Vector2(0, 1))
	await _wait(1.6)
	await _shot("08_detected")
	await _wait(1.8)
	await _shot("09_end")
	_finish()


func _press(keycode: Key) -> void:
	var down := InputEventKey.new()
	down.physical_keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.physical_keycode = keycode
	up.pressed = false
	Input.parse_input_event(up)


func _nearest_in_group(group: String, pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := 1e12
	for node in get_tree().get_nodes_in_group(group):
		if node is Node2D:
			var d: float = node.global_position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = node
	return best


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_dir.path_join(shot_name + ".png"))
	print("SHOT saved: ", shot_name)


func _finish() -> void:
	print("SHOTS_DONE dir=", _dir)
	get_tree().quit()
