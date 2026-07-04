extends Node
## Screenshot director (`game -- --shoot`): drives the game through scripted
## moments and saves PNGs to user://shots/. CI runs this under Xvfb and
## uploads the images, closing the visual feedback loop.
##
## The shot list is the full audit surface: every prop interaction, every
## UI state (shop with progress, tucked checklist, danger mode, pause),
## and both endings, on a seeded mid-game save so nothing renders empty.

var _dir := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_dir = OS.get_user_data_dir().path_join("shots")
	DirAccess.make_dir_recursive_absolute(_dir)
	_run()


func _seed_meta() -> void:
	# A mid-game save: histograms have data, sparks buy things, a tier is
	# owned but not equipped — every meta UI state has content.
	if not Meta.lifetimes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 36:
		var tau := clampf(-2.2 * log(1.0 - rng.randf()), 0.05, 6.4)
		Meta.record_lifetime(tau, tau * rng.randf_range(1.8, 6.0))
	Meta.sparks = 7
	Meta.owned_tier = 2
	Meta.equip(1)


func _run() -> void:
	_seed_meta()
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
	var aurora := _nearest_in_group("aurora", Vector2(0, 5400))
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

	# Noctilucent cloud: zap it and catch the teal crackle.
	await _visit_and_zap(muon, "noctilucent", Vector2(0, 15500), "06_noctilucent", 0.18)

	# Red sprite: zap startles it fully lit.
	await _visit_and_zap(muon, "red_sprite", Vector2(0, 16500), "07_red_sprite", 0.25)

	# High-speed streak through the mesosphere (post-boost).
	muon.set("global_position", Vector2(-500, 18000))
	muon.set("autopilot", Vector2(1, 0.35))
	muon.call("boost", 500.0, "director's orders")
	await _wait(0.7)
	await _shot("08_speed")

	# Weather balloon panic (zap startles it).
	await _visit_and_zap(muon, "weather_balloon", Vector2(0, 31500), "09_balloon", 0.3)

	# Thundercloud: zap for the lightning bolt.
	await _visit_and_zap(muon, "props/cloud.gd", Vector2(0, 55000), "10_cloud_lightning", 0.14)

	# Airplane fly-through (avionics glitch + cabin flicker).
	var plane := _nearest_prop("airplane", Vector2(0, 54000))
	if plane != null:
		muon.set("speed", 320.0)
		muon.set("global_position", plane.global_position + Vector2(-170, 0))
		muon.set("heading", Vector2.RIGHT)
		muon.set("autopilot", Vector2(1, 0))
		await _wait(0.3)
		await _shot("11_airplane")
		await _wait(0.6)

	# Bird flock scatter.
	await _visit_and_zap(muon, "bird_flock", Vector2(0, 52000), "12_birds", 0.35)

	# Park mid-sky for the UI-state shots: a slow, centered descent. At
	# stroll speed the ground stays kilometers away, and the muon keeps
	# mid-frame instead of drifting to the x-limit (where the decay would
	# fire off-screen behind the checklist).
	muon.set("speed", 320.0)
	muon.set("global_position", Vector2(0, 40000))
	muon.set("heading", Vector2.DOWN)
	muon.set("autopilot", Vector2(0.15, 1))

	# Checklist tucked away: the edge tab affordance.
	_press(KEY_TAB)
	await _wait(0.6)
	await _shot("13_checklist_tucked")
	_press(KEY_TAB)
	await _wait(0.4)

	# Danger mode: P(decay) past 90% — the whole UI goes wild.
	muon.set("_hazard_integral", 2.5)
	await _wait(0.8)
	await _shot("14_danger")
	muon.set("_hazard_integral", 0.25)
	await _wait(0.4)

	# Pause overlay.
	_press(KEY_ESCAPE)
	await _wait(0.5)
	await _shot("15_pause")
	_press(KEY_ESCAPE)
	await _wait(0.4)

	# Decay: the burst, then the lose screen (with histograms).
	muon.call("_die")
	await _wait(0.15)
	await _shot("16_decay")
	await _wait(1.8)
	await _shot("17_end_lose")

	# Restart and run the happy ending.
	_press(KEY_R)
	await _wait(3.2)  # scene reload + birth sequence
	muon = get_tree().get_first_node_in_group("muon")
	if muon == null:
		_finish()
		return
	muon.set("global_position", Vector2(0, 68300))
	muon.set("autopilot", Vector2(0, 1))
	await _wait(1.6)
	await _shot("18_detected")
	await _wait(1.8)
	await _shot("19_end_win")
	_finish()


## Teleport next to a prop (matched by script-path hint), zap, screenshot.
## Speed is reset to a stroll each visit — after a boost the tour would
## otherwise streak past every subject at gamma 7.
func _visit_and_zap(muon: Node, hint: String, near: Vector2, shot_name: String,
		delay: float) -> void:
	var prop := _nearest_prop(hint, near)
	if prop == null:
		print("SHOT skipped (no prop): ", shot_name)
		return
	muon.set("speed", 320.0)
	muon.set("global_position", prop.global_position + Vector2(-60, -90))
	muon.set("heading", Vector2.DOWN)
	muon.set("autopilot", Vector2(0.3, 1))
	await _wait(0.25)
	muon.call("_zap")
	await _wait(delay)
	await _shot(shot_name)
	await _wait(0.5)


func _press(keycode: Key) -> void:
	# Both keycodes: game actions match physical, the built-in ui_*
	# actions (ui_cancel for pause) match the logical keycode.
	var down := InputEventKey.new()
	down.physical_keycode = keycode
	down.keycode = keycode
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventKey.new()
	up.physical_keycode = keycode
	up.keycode = keycode
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


## Nearest zappable whose script path contains `hint`.
func _nearest_prop(hint: String, pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := 1e12
	for node in get_tree().get_nodes_in_group("zappable"):
		if node is Node2D:
			var scr := node.get_script() as Script
			if scr == null or not scr.resource_path.contains(hint):
				continue
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
	# The portrait/touch audit pass prefixes its shots.
	var prefix := "p_" if Game.fake_touch else ""
	img.save_png(_dir.path_join(prefix + shot_name + ".png"))
	print("SHOT saved: ", prefix + shot_name)


func _finish() -> void:
	print("SHOTS_DONE dir=", _dir)
	get_tree().quit()
