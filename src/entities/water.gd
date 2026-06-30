class_name Water
extends Area2D
## A tile of water. While the player overlaps any water tile, their controller
## switches to buoyant swimming (soft gravity, repeatable Jump strokes). One area
## per tile; the player just counts how many it's inside.

var tint := Color(0.25, 0.55, 0.9)
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	add_child(s)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b is Player:
		(b as Player).add_water(1)

func _on_exit(b: Node) -> void:
	if b is Player:
		(b as Player).add_water(-1)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var wave := sin(_t * 2.0 + position.x * 0.1) * 0.8
	draw_rect(Rect2(-8, -8 + wave, 16, 16 - wave), Color(tint.r, tint.g, tint.b, 0.42))
	draw_rect(Rect2(-8, -8 + wave, 16, 2), Color(tint.r + 0.3, tint.g + 0.25, tint.b, 0.55))
