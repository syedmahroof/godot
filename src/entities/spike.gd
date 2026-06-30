class_name Spike
extends Area2D
## Instant-death hazard. The hitbox is intentionally smaller than the drawing so
## near-misses feel fair (Celeste-style forgiveness).

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	poly.points = PackedVector2Array([Vector2(-5, 7), Vector2(5, 7), Vector2(0, -1)])
	s.shape = poly
	add_child(s)
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if b is Player:
		b.die()

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 8), Vector2(0, 8), Vector2(-3.5, -5)]), Color(0.82, 0.86, 0.92))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 8), Vector2(7, 8), Vector2(3.5, -5)]), Color(0.7, 0.75, 0.85))
