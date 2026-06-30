class_name GunPickup
extends Area2D
## Grants the blaster: press F / J to fire shots that pop enemies.

var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player:
		(b as Player).grant_gun()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 3.0) * 1.5
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2(0, off), 10.0, Color(0.9, 0.9, 0.5, 0.14 * glow))
	# A little blaster shape.
	draw_rect(Rect2(-5, -2 + off, 9, 4), Color(0.25, 0.25, 0.32))
	draw_rect(Rect2(3, -1 + off, 4, 2), Color(0.4, 0.4, 0.5))
	draw_rect(Rect2(-4, 1 + off, 3, 4), Color(0.2, 0.2, 0.28))
	draw_circle(Vector2(7, off), 1.4, Color(1.0, 0.9, 0.4))
