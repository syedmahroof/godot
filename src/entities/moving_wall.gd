class_name MovingWall
extends Area2D
## Haunted Mansion. A haunted stone slab that slides out to seal a corridor, holds,
## then grinds back — cross during the gap. Lethal to touch while it moves through you.
## A horizontal sliding crush, distinct from the vertical Crusher and the tracked
## Sawblade. Height ~2.5 tiles.

var reach := 40.0           # how far it slides from its rest position
var axis := Vector2.RIGHT
var _origin := Vector2.ZERO
var _x := 0.0
var _state := 0            # 0 wait, 1 close, 2 hold, 3 open
var _timer := 0.0
var _shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_origin = position
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 40)
	_shape.shape = r
	add_child(_shape)
	_timer = randf_range(0.5, 1.6)

func _process(delta: float) -> void:
	match _state:
		0:
			_timer -= delta
			if _timer <= 0.0:
				_state = 1
		1:
			_x = move_toward(_x, reach, delta * 150.0)
			if _x >= reach:
				_state = 2
				_timer = 0.7
				Audio.play("stomp", 0.1)
		2:
			_timer -= delta
			if _timer <= 0.0:
				_state = 3
		3:
			_x = move_toward(_x, 0.0, delta * 90.0)
			if _x <= 0.0:
				_state = 0
				_timer = randf_range(0.8, 1.8)
	position = _origin + axis * _x
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).die()
	queue_redraw()

func _draw() -> void:
	var col := Color(0.34, 0.30, 0.38)
	draw_rect(Rect2(-6, -20, 12, 40), col)
	draw_rect(Rect2(-6, -20, 12, 40), col.lightened(0.12))
	# brick seams
	for k in 5:
		draw_line(Vector2(-6, -18.0 + k * 8.0), Vector2(6, -18.0 + k * 8.0), col.darkened(0.3), 1.0)
	draw_line(Vector2(0, -20), Vector2(0, 20), col.darkened(0.3), 1.0)
