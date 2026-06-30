class_name Crumble
extends StaticBody2D
## A platform that collapses shortly after the player stands on it — a small
## taste of the "troll" mechanics the full design is built around.

var _touched := false

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	add_child(s)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var a := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(14, 6)
	a.shape = ar
	a.position = Vector2(0, -9)
	area.add_child(a)
	add_child(area)
	area.body_entered.connect(_on_top)

func _on_top(b: Node) -> void:
	if b is Player and not _touched:
		_touched = true
		queue_redraw()
		await get_tree().create_timer(0.35).timeout
		queue_free()

func _draw() -> void:
	var c := Color(0.62, 0.46, 0.32) if not _touched else Color(0.75, 0.32, 0.25)
	draw_rect(Rect2(-8, -8, 16, 16), c, true)
	draw_rect(Rect2(-8, -8, 16, 16), c.darkened(0.3), false, 1.0)
