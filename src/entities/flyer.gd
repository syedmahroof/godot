class_name Flyer
extends Area2D
## A flying enemy — reads as a bee, bat, fish, jellyfish or alien depending on the
## world's tint. Drifts along an elliptical path. Stomp from above or shoot it to
## pop; touching its side is fatal. In group "enemy" so bullets can hit it.

const STOMP_BOUNCE := 240.0

var tint := Color(0.95, 0.4, 0.5)
var rx := 30.0
var ry := 14.0
var speed := 1.6

var _origin := Vector2.ZERO
var _t := 0.0
var _dead := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	_origin = position
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta * speed
	position = _origin + Vector2(cos(_t) * rx, sin(_t * 1.3) * ry)
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -1.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

## Kill it (stomp or bullet).
func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.1)
	Burst.spawn(get_parent(), global_position, tint, 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.04).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	var wing := 4.0 + sin(_t * 9.0) * 2.0
	draw_line(Vector2(-4, -1), Vector2(-4 - wing, -5), Color(1, 1, 1, 0.5), 1.5)
	draw_line(Vector2(4, -1), Vector2(4 + wing, -5), Color(1, 1, 1, 0.5), 1.5)
	draw_circle(Vector2(0, 5), 6.0, Color(0, 0, 0, 0.12))
	draw_circle(Vector2.ZERO, 6.0, tint)
	draw_circle(Vector2(0, 1), 6.0, tint.darkened(0.15))
	draw_circle(Vector2(-2, -1), 1.5, Color.WHITE)
	draw_circle(Vector2(2, -1), 1.5, Color.WHITE)
	draw_circle(Vector2(-2, -1), 0.8, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(2, -1), 0.8, Color(0.1, 0.1, 0.15))
