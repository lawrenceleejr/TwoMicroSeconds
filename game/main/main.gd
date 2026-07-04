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
const CosmicIntro := preload("res://game/fx/cosmic_intro.gd")
const TaskPop := preload("res://game/fx/task_pop.gd")
const FloatText := preload("res://game/fx/float_text.gd")

# Untyped: these expose script-defined members/methods.
var muon
var director
var end_screen
var pause_overlay

var _ended := false
var _sparks_at_start := 0


func _ready() -> void:
	if not Game.shoot_mode:
		randomize()
	Tasks.reset()
	Game.mark_run_start()
	_sparks_at_start = Meta.sparks

	add_child(AtmosphereScript.new())

	director = DirectorScript.new()
	add_child(director)

	muon = MuonScript.new()
	muon.position = Vector2(0, 220)
	add_child(muon)
	muon.decayed.connect(_on_decayed)
	muon.circle_drawn.connect(_on_circle_drawn)

	var intro: Node2D = CosmicIntro.new()
	intro.position = muon.position
	intro.beam_width = 5.0 + Meta.tier * 1.4
	intro.beam_color = Juice.SUN.lerp(Color(1.0, 0.85, 0.4), float(Meta.tier) / 6.0)
	add_child(intro)
	if Meta.is_max_tier():
		# The Oh-My-God particle arrives with authority.
		Juice.glitch(0.4, 0.7)

	# UI sits above the full-screen effect layers (relativity 70,
	# vignette 80, glitch 90) so text stays crisp and un-shifted.
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	var hud = HudScript.new()
	hud.muon = muon
	ui_layer.add_child(hud)
	ui_layer.add_child(ChecklistScript.new())
	end_screen = EndScreenScript.new()
	ui_layer.add_child(end_screen)
	pause_overlay = PauseScript.new()
	ui_layer.add_child(pause_overlay)

	Tasks.task_completed.connect(_on_task_completed)


func _process(_delta: float) -> void:
	if _ended:
		return
	if muon.alive and not muon.finished and muon.global_position.y >= Atmos.DETECT_Y:
		_win()


func _on_task_completed(task: Dictionary) -> void:
	if task["id"] == "get_detected":
		return
	Meta.add_sparks(1)
	Sfx.play("task_done", -4.0)
	Juice.hitstop(0.05, 0.1)
	Juice.shake(0.12)
	TaskPop.confetti(self, muon.global_position, 26)
	FloatText.spawn(self, muon.global_position + Vector2(0, -34), "+1 spark", Juice.MINT)


func _on_circle_drawn() -> void:
	if Atmos.layer_index_at(muon.global_position.y) == 2:
		Tasks.complete("ozone_circle")


func _on_decayed() -> void:
	if _ended:
		return
	_ended = true
	Meta.record_lifetime(muon.age_us)
	pause_overlay.can_pause = false
	Sfx.play("decay", -2.0, 0.0)
	Juice.hitstop(0.22, 0.05)
	Juice.shake(0.5)
	var burst: Node2D = DecayBurst.new()
	burst.position = muon.global_position
	add_child(burst)
	var alt := Atmos.altitude_at(muon.global_position.y)
	var run_sparks: int = Meta.sparks - _sparks_at_start
	var age: float = muon.age_us
	get_tree().create_timer(1.6).timeout.connect(func() -> void:
		end_screen.show_lose(alt, run_sparks, age)
	)


func _win() -> void:
	_ended = true
	pause_overlay.can_pause = false
	var pad := Vector2(0.0, Atmos.GROUND_Y - 40.0)
	if director.detector != null:
		pad = director.detector.global_position + Vector2(0, -14.0)
		director.detector.count()
	muon.absorb(pad)
	Tasks.complete("get_detected")
	Sfx.play("detected", 0.0, 0.0)
	Juice.shake(0.2)
	# Completion bonus, plus a fat tip for a perfect mischief sheet.
	var bonus := 3
	if Tasks.all_optional_done():
		bonus += 5
	Meta.add_sparks(bonus)
	var run_sparks: int = Meta.sparks - _sparks_at_start
	var age: float = muon.age_us
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		end_screen.show_win(run_sparks, Meta.is_max_tier(), age)
	)
