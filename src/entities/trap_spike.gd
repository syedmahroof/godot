class_name TrapSpike
extends Area2D
## A hidden spike that stays flush with the ground until you're right on top of
## it, then snaps up to skewer you. The arming delay is randomised a little so
## even a memorised run can still catch you out — peak Level-Devil cruelty.

var _triggered := false
var _armed := false
var _up := 0.0
var _delay := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var poly := ConvexPolygonShape2D.new()
	poly.points = PackedVector2Array([Vector2(-6, 8), Vector2(6, 8), Vector2(0, -2)])
	s.shape = poly
	add_child(s)
	_delay = randf_range(0.0, 0.12)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _triggered:
		var p := _player()
		if p and absf(p.global_position.x - global_position.x) < 11.0 \
				and (p.global_position.y - global_position.y) < 3.0:
			_triggered = true
	elif not _armed:
		_delay -= delta
		if _delay <= 0.0:
			_armed = true
			Audio.play("stomp", 0.1)
	if _armed and _up < 1.0:
		_up = move_toward(_up, 1.0, delta * 14.0)
		if _up > 0.35:
			for b in get_overlapping_bodies():
				if b is Player:
					(b as Player).die()
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _armed and b is Player:
		b.die()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	# A faint base plate is the only hint while hidden.
	draw_rect(Rect2(-7, 6, 14, 3), Color(0.28, 0.10, 0.12))
	if _up > 0.01:
		var h := 11.0 * _up
		for k in 3:
			var cx := -4.0 + k * 4.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 2.0, 8), Vector2(cx + 2.0, 8), Vector2(cx, 8 - h),
			]), Color(0.9, 0.32, 0.32))
