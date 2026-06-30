class_name HelmetPickup
extends Area2D
## Grants a helmet that absorbs one otherwise-fatal hit (great for caves/space).

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
		(b as Player).grant_helmet()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 3.0) * 1.5
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2(0, off), 10.0, Color(0.6, 0.9, 1.0, 0.14 * glow))
	# Dome + visor.
	draw_circle(Vector2(0, off), 6.0, Color(0.8, 0.85, 0.95))
	draw_circle(Vector2(0, off), 6.0, Color(0.55, 0.6, 0.7).lightened(0.1))
	draw_rect(Rect2(-6, off, 12, 4), Color(0.5, 0.55, 0.65))
	draw_arc(Vector2(0, 1 + off), 4.0, PI, TAU, 12, Color(0.55, 0.85, 1.0), 1.5)
