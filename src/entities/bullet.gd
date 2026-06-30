class_name Bullet
extends Area2D
## A blaster shot. Flies straight, pops the first enemy it reaches, and expires
## after a short life. Enemy hit-testing is a cheap distance check against the
## "enemy" group so it works for both ground blobs and flyers.

var dir := Vector2.RIGHT
var speed := 260.0

var _life := 1.0

func _ready() -> void:
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 2.5
	s.shape = c
	add_child(s)

func _process(delta: float) -> void:
	position += dir * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and global_position.distance_to(e.global_position) < 9.0:
			if e.has_method("hit"):
				e.hit()
			Burst.spawn(get_parent(), global_position, Color(1.0, 0.9, 0.4), 6, 60.0, 0.3)
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.9, 0.4, 0.3))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.95, 0.5))
