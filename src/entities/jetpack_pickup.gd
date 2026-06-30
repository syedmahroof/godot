class_name JetpackPickup
extends Area2D
## Grants the jetpack: hold Jump to fly. Floats and glows until grabbed.

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
		(b as Player).grant_jetpack()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 3.0) * 1.5
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2(0, off), 10.0, Color(1.0, 0.6, 0.3, 0.14 * glow))
	# Two tanks + a flame.
	draw_rect(Rect2(-4, -5 + off, 3, 9), Color(0.85, 0.5, 0.3))
	draw_rect(Rect2(1, -5 + off, 3, 9), Color(0.85, 0.5, 0.3))
	draw_rect(Rect2(-4, -5 + off, 8, 2), Color(0.95, 0.7, 0.4))
	var f := 2.0 + sin(_t * 14.0) * 1.2
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2.5, 4 + off), Vector2(2.5, 4 + off), Vector2(0, 4 + f + off),
	]), Color(1.0, 0.8, 0.3))
