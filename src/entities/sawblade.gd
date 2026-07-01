class_name Sawblade
extends Area2D
## A buzzsaw that slides back and forth along a track and spins for menace.
## Lethal on contact. The level parser sets `axis`/`span` for the travel; default
## is a horizontal sweep. Like the other moving traps it checks overlaps each
## frame (rather than relying on body_entered) since it teleports along its path.

var axis := Vector2.RIGHT
var span := 40.0          # travel distance to each side of the origin
var speed := 1.8          # radians/sec of the sine sweep

var _origin := Vector2.ZERO
var _t := 0.0
var _spin := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	_origin = position
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta * speed
	_spin += delta * 12.0
	position = _origin + axis * sin(_t) * span
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).die()
	queue_redraw()

func _draw() -> void:
	var col := Color(0.76, 0.79, 0.86)
	draw_circle(Vector2.ZERO, 7.5, col.darkened(0.4))
	for k in 8:
		var a := _spin + k * TAU / 8.0
		var d := Vector2(cos(a), sin(a))
		draw_colored_polygon(PackedVector2Array([
			d.rotated(-0.28) * 6.0, d.rotated(0.28) * 6.0, d * 9.5]), col)
	draw_circle(Vector2.ZERO, 5.0, col)
	draw_circle(Vector2.ZERO, 1.6, Color(0.2, 0.2, 0.26))
