extends Node2D
## The muon's body sprite (faux-3D shaded ball from assets/sprites/muon.svg).
## Velocity squash is applied here; tween-driven pops own the node's scale.

const BASE_SCALE := 0.30

var applied_squash := Vector2.ONE
var body_color := Color.WHITE

var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/sprites/muon.svg")
	add_child(_sprite)


func _process(_delta: float) -> void:
	_sprite.scale = Vector2.ONE * BASE_SCALE * applied_squash
	_sprite.modulate = body_color
