class_name ToxicCloud
extends Area2D
## Giant Mushroom Forest. A drifting cloud of poison spores that floats along a slow
## path. Lethal to touch — time your passage for when it drifts clear. Non-solid.

var span := 30.0
var speed := 0.8
var axis := Vector2.RIGHT
var tint := Color(0.55, 0.9, 0.35)
var _origin := Vector2.ZERO
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_origin = position
	_t = randf() * TAU
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 9.0
	s.shape = c
	add_child(s)

func _process(delta: float) -> void:
	_t += delta * speed
	position = _origin + axis * sin(_t) * span + Vector2(0, cos(_t * 0.7) * 5.0)
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).die()
	queue_redraw()

func _draw() -> void:
	var puff := 1.0 + sin(_t * 3.0) * 0.1
	draw_circle(Vector2(0, 0), 10.0 * puff, Color(tint.r, tint.g, tint.b, 0.32))
	draw_circle(Vector2(-4, 2), 7.0 * puff, Color(tint.r, tint.g, tint.b, 0.4))
	draw_circle(Vector2(5, 1), 7.5 * puff, Color(tint.r, tint.g, tint.b, 0.4))
	draw_circle(Vector2(1, -4), 6.0 * puff, Color(tint.r, tint.g, tint.b, 0.35))
	# bubbling motes
	for k in 3:
		var a := _t * 2.0 + k * 2.0
		draw_circle(Vector2(cos(a) * 6.0, sin(a) * 4.0), 1.2, Color(0.8, 1.0, 0.5, 0.7))
