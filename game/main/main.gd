extends Node2D
## One continuous descent: builds the world, wires the signals,
## and referees the two endings.

const MuonScript := preload("res://game/player/muon.gd")
const AtmosphereScript := preload("res://game/world/atmosphere.gd")
const DirectorScript := preload("res://game/world/layer_director.gd")
const HudScript := preload("res://game/ui/hud.gd")
const ChecklistScript := preload("res://game/ui/checklist.gd")
const EndScreenScript := preload("res://game/ui/end_screen.gd")
const PauseScript := preload("res://game/ui/pause_overlay.gd")
const DecayBurst := preload("res://game/fx/decay_burst.gd")
const BirthSequence := preload("res://game/fx/birth_sequence.gd")
const TaskPop := preload("res://game/fx/task_pop.gd")
const FloatText := preload("res://game/fx/float_text.gd")
const TouchControlsScript := preload("res://game/ui/touch_controls.gd")
const SurfaceBurst := preload("res://game/fx/surface_burst.gd")

# Untyped: these expose script-defined members/methods.
var muon
var director
var end_screen
var pause_overlay

var _ended := false
var _sparks_at_start := 0
var _underground := false
var _ui_layer: CanvasLayer
var _hud
## Detector stack progress.
var _passed := {}
var _deepest := ""          # sub-label of the deepest detector reached
var _perfect_awarded := false


func _ready() -> void:
	if not Game.shoot_mode:
		randomize()
	Tasks.reset()
	Game.mark_run_start()
	_sparks_at_start = Meta.sparks

	var atmo = AtmosphereScript.new()
	if Game.stage_planes:
		# The stage renders sky and near haze on separate 3D depth planes.
		atmo.mode = "world"
	add_child(atmo)

	director = DirectorScript.new()
	add_child(director)

	muon = MuonScript.new()
	muon.position = Vector2(0, 220)
	add_child(muon)
	muon.decayed.connect(_on_decayed)
	muon.circle_drawn.connect(_on_circle_drawn)

	# Birth: proton in, shower, ride a pion, decay to muon, play.
	muon.intro_mode = true
	muon.visible = false
	var birth: Node2D = BirthSequence.new()
	birth.position = muon.position
	birth.muon = muon
	add_child(birth)
	if Meta.is_max_tier():
		# The Oh-My-God particle arrives with authority.
		Juice.glitch(0.4, 0.7)

	# UI lives on the ROOT viewport (the world may be rendered inside a
	# SubViewport on the 3D stage) and above the effect layers
	# (relativity 70, vignette 80, glitch 90): crisp, flat, un-shifted.
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 100
	# Touch controls sit under the HUD so chips/toasts stay readable.
	_ui_layer.add_child(TouchControlsScript.new())
	_hud = HudScript.new()
	_hud.muon = muon
	_ui_layer.add_child(_hud)
	_ui_layer.add_child(ChecklistScript.new())
	end_screen = EndScreenScript.new()
	_ui_layer.add_child(end_screen)
	pause_overlay = PauseScript.new()
	_ui_layer.add_child(pause_overlay)
	get_tree().root.add_child.call_deferred(_ui_layer)

	Tasks.task_completed.connect(_on_task_completed)


func _exit_tree() -> void:
	# The UI layer was handed to the root viewport; take it with us.
	if _ui_layer != null and is_instance_valid(_ui_layer):
		_ui_layer.queue_free()


func _process(_delta: float) -> void:
	if _ended:
		return
	# Punching through the surface: the Ridiculous Fishing moment — the
	# meadow was never the finish line. Big, loud, once.
	if not _underground and muon.alive and muon.global_position.y >= Atmos.GROUND_Y + 20.0:
		_underground = true
		var burst: Node2D = SurfaceBurst.new()
		burst.position = Vector2(muon.global_position.x, Atmos.GROUND_Y + 30.0)
		burst.motion = muon.velocity
		add_child(burst)
		Sfx.play("zap", -1.0, 0.0)
		Sfx.play("decay", -6.0, 0.35)
		Juice.shake(0.7)
		Juice.hitstop(0.06, 0.12)
		Juice.glitch(0.22, 0.4)
		FloatText.spawn(self, muon.global_position + Vector2(0, -60),
			"THROUGH!", Juice.SUN)
	# Fly through each detector in the stack as we reach its depth.
	if muon.alive and not muon.finished:
		for det in Atmos.DETECTORS:
			if not _passed.has(det["kind"]) and muon.global_position.y >= float(det["y"]):
				_pass_detector(det)
				break


## Punch through a detector on the way down. All but LZ are fly-throughs
## (count, spark, keep falling); LZ is the grand finale.
func _pass_detector(det: Dictionary) -> void:
	_passed[det["kind"]] = true
	_deepest = "%s · %s" % [det["label"], det["sub"]]
	var stage := get_tree().get_first_node_in_group("stage")
	if stage != null:
		stage.celebrate_kind(det["kind"])
	if det["kind"] == "lz":
		_discover()
		return
	Meta.add_sparks(1)
	Sfx.play("detected", -3.0, 0.0)
	# Matrix bullet-time: drop into a deep, ~2-second ultra slo-mo so you can
	# read everything as the detector counts you — music out, whoosh in.
	# (Not during the screenshot tour, which teleports on a tight clock.)
	if not Game.shoot_mode:
		Juice.bullet_time()
	Juice.shake(0.2)
	Juice.glitch(0.25, 0.4)
	TaskPop.confetti(self, muon.global_position, 22)
	FloatText.spawn(self, muon.global_position + Vector2(0, -52),
		"%s counted you!" % det["label"], Juice.MINT)
	Tasks.complete("get_detected")


func _on_task_completed(task: Dictionary) -> void:
	if task["id"] == "get_detected":
		return
	Sfx.play("task_done", -4.0)
	Juice.hitstop(0.05, 0.1)
	Juice.shake(0.12)
	TaskPop.confetti(self, muon.global_position, 26)
	FloatText.spawn(self, muon.global_position + Vector2(0, -34), "mischief!", Juice.MINT)
	# Perfect sheet: clearing every bit of mischief pays a one-time bonus.
	if not _perfect_awarded and Tasks.all_optional_done():
		_perfect_awarded = true
		Meta.add_sparks(5)
		Sfx.play("buy", -3.0)
		FloatText.spawn(self, muon.global_position + Vector2(0, -70),
			"perfect sheet · +5 ◆", Juice.SUN)


func _on_circle_drawn() -> void:
	if Atmos.layer_index_at(muon.global_position.y) == 2:
		Tasks.complete("ozone_circle")


func _on_decayed() -> void:
	if _ended:
		return
	_ended = true
	var s: Array = muon.lifetime_sample()
	Meta.record_lifetime(s[0], s[1])
	pause_overlay.can_pause = false
	Sfx.play("decay", -2.0, 0.0)
	# No dramatic pause: decay is instantaneous — one frame you exist,
	# the next you're three other particles.
	Juice.shake(0.5)
	var burst: Node2D = DecayBurst.new()
	burst.position = muon.global_position
	burst.motion = muon.velocity
	add_child(burst)
	var alt := Atmos.altitude_at(muon.global_position.y)
	var depth := Atmos.depth_m_at(muon.global_position.y)
	var run_sparks: int = Meta.sparks - _sparks_at_start
	var age: float = muon.age_us
	var lab: float = muon.lab_us
	var deepest := _deepest
	var peak: float = muon.peak_gamma
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		end_screen.show_lose(alt, depth, deepest, run_sparks, age, lab, peak)
	)


## The finale: the muon reached LZ, 1.5 km down — deeper than any cosmic
## ray has any right to. The camera pans up to space; the discovery, and
## its enduring mystery, is revealed.
func _discover() -> void:
	_ended = true
	pause_overlay.can_pause = false
	muon.finished = true
	var s: Array = muon.lifetime_sample()
	Meta.record_lifetime(s[0], s[1])
	Meta.add_sparks(20)
	Meta.mark_discovery()
	var stage := get_tree().get_first_node_in_group("stage")
	if stage != null:
		stage.begin_discovery()
	Sfx.play("detected", 0.0, 0.0)
	Sfx.play_discovery_music()
	Juice.shake(0.3)
	# The camera rises on its own, slowly, up to space — the muon stays put
	# and drifts off below — while the epilogue reveals itself one line at a
	# time over the wistful music.
	muon.begin_epilogue_pan(15.0)
	end_screen.begin_epilogue(muon.age_us, muon.lab_us)
	# Clear the gameplay HUD away so the epilogue reads clean — the clock,
	# gauges and to-do note all fade out as the camera rises.
	var fade := create_tween().set_parallel(true)
	fade.tween_property(_hud, "modulate:a", 0.0, 2.2)
	var cl := get_tree().get_first_node_in_group("checklist")
	if cl != null:
		fade.tween_property(cl, "modulate:a", 0.0, 2.2)
