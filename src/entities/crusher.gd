class_name Crusher
extends Area2D
## A spiked block that periodically slams straight down, holds, then grinds back
## up — walk under it between slams. Lethal while extended. A random start phase
## keeps a row of crushers from moving in lockstep.

var drop := 40.0          # how far it slams below its rest cell

var _shape: CollisionShape2D
var _y := 0.0
var _state := 0           # 0 wait, 1 slam, 2 hold, 3 retract
var _timer := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 12)
	_shape.shape = r
	add_child(_shape)
	_timer = randf_range(0.4, 1.8)

func _process(delta: float) -> void:
	match _state:
		0:
			_timer -= delta
			if _timer <= 0.0:
				_state = 1
		1:
			_y = move_toward(_y, drop, delta * 280.0)
			if _y >= drop:
				_state = 2
				_timer = 0.35
				Audio.play("stomp", 0.1)
		2:
			_timer -= delta
			if _timer <= 0.0:
				_state = 3
		3:
			_y = move_toward(_y, 0.0, delta * 70.0)
			if _y <= 0.0:
				_state = 0
				_timer = randf_range(0.9, 1.9)
	_shape.position = Vector2(0, _y)
	if _y > 6.0:
		for b in get_overlapping_bodies():
			if b is Player:
				(b as Player).die()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(0, -8), Vector2(0, drop + 8), Color(1, 1, 1, 0.05), 8.0)  # guide rail
	var col := Color(0.42, 0.42, 0.5)
	var top := _y - 8.0
	draw_rect(Rect2(-7, top, 14, 12), col)
	draw_rect(Rect2(-7, top, 14, 3), col.lightened(0.25))
	for k in 3:
		var cx := -4.0 + k * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 2, _y + 4), Vector2(cx + 2, _y + 4), Vector2(cx, _y + 9)]), Color(0.76, 0.79, 0.86))
