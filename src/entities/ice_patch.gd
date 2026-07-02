class_name IcePatch
extends Area2D
## Frozen Peaks. A slippery ice surface. The solid tile itself is placed by the Level
## (like a normal '#'); this zone sits on top of it and, while the player stands on
## it, cuts their grip so they slide. One per tile; the player counts overlaps.

var tint := Color(0.75, 0.9, 1.0)
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	s.position = Vector2(0, -8)   # straddles the tile top where the player stands
	add_child(s)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b is Player:
		(b as Player).add_ice(1)

func _on_exit(b: Node) -> void:
	if b is Player:
		(b as Player).add_ice(-1)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	# Glossy sheen over the tile.
	draw_rect(Rect2(-8, -8, 16, 16), Color(tint.r, tint.g, tint.b, 0.30))
	draw_rect(Rect2(-8, -8, 16, 3), Color(1, 1, 1, 0.45))
	var gx := -8.0 + fmod(_t * 10.0, 16.0)
	draw_line(Vector2(gx, -7), Vector2(gx - 3, -1), Color(1, 1, 1, 0.35), 1.0)
