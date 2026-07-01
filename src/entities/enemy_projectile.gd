class_name EnemyProjectile
extends Area2D
## A shot fired by an enemy (e.g. the Turret). Flies straight, kills the player on
## contact, and expires after a short life so stray shots don't linger.

var dir := Vector2.RIGHT
var speed := 88.0
var tint := Color(1.0, 0.5, 0.3)

var _life := 2.4

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 3.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if b is Player:
		(b as Player).die()

func _process(delta: float) -> void:
	position += dir * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color(tint.r, tint.g, tint.b, 0.3))
	draw_circle(Vector2.ZERO, 2.4, tint)
	draw_circle(Vector2.ZERO, 1.0, Color(1, 1, 1, 0.85))
