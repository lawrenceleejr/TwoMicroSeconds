extends "res://game/world/props/prop_base.gd"
## The CMS counting point, 100 m down at LHC Point 5 — now presented as
## REAL 3D geometry by the stage (see cms_rig.gd). This node is the
## gameplay-plane marker: it owns the win position and the celebratory
## confetti, but draws nothing itself (the 3D rig is the detector you see).

const TaskPop := preload("res://game/fx/task_pop.gd")

var _celebrate := 0.0


func _setup() -> void:
	z_index = 3
	# No sprite: the visible detector is the stage's 3D rig.


func count() -> void:
	_celebrate = 5.0
	# Confetti bursts up out of the beam spot, over the diving muon.
	TaskPop.confetti(get_parent(), global_position + Vector2(0, -40), 46)
	Sfx.play("detected", 0.0, 0.0)
