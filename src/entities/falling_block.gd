class_name FallingBlock
extends Area2D
## A heavy block that hangs overhead and slams straight down the moment you walk
## into the column beneath it. Touch it while it's falling and you're flat.

var color := Color(0.5, 0.2, 0.2)

var _falling := false
var _vel := 0.0
var _start_y := 0.0
var _shake := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(15, 15)
	s.shape = r
	add_child(s)
	_start_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _falling:
		var p := _player()
		if p and absf(p.global_position.x - global_position.x) < 9.0 \
				and p.global_position.y > global_position.y:
			_falling = true
			_shake = 0.12
	else:
		_vel += 1100.0 * delta
		position.y += _vel * delta
		if position.y - _start_y > 220.0:
			queue_free()
	if _shake > 0.0:
		_shake -= delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _falling and b is Player:
		b.die()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	var j := Vector2(randf_range(-1, 1), 0) * (1.0 if _shake > 0.0 else 0.0)
	var rect := Rect2(-7.5 + j.x, -7.5, 15, 15)
	draw_rect(rect, color.darkened(0.1), true)
	draw_rect(rect, color.lightened(0.2), false, 1.0)
	# A grumpy face so you know it means business.
	draw_rect(Rect2(-4 + j.x, -3, 2, 2), Color(0.1, 0.05, 0.06), true)
	draw_rect(Rect2(2 + j.x, -3, 2, 2), Color(0.1, 0.05, 0.06), true)
	draw_rect(Rect2(-3 + j.x, 2, 6, 1.5), Color(0.1, 0.05, 0.06), true)
