class_name Armored
extends Area2D
## An armored beetle: patrols like a blob but its hard shell means a stomp just
## bounces you off — it survives. You must shoot it (or simply avoid it). Touching
## its side is still fatal.

const STOMP_BOUNCE := 220.0

var tint := Color(0.52, 0.56, 0.64)
var span := 30.0
var speed := 1.2

var _origin := Vector2.ZERO
var _t := 0.0
var _face := 1.0
var _dead := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 6.0
	c.height = 14.0
	s.shape = c
	add_child(s)
	_origin = position
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta * speed
	position.x = _origin.x + sin(_t) * span
	_face = signf(cos(_t))
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	if coming_down and above:
		# The shell just bounces the player — the beetle is unharmed.
		p.bounce(STOMP_BOUNCE)
	else:
		p.die()

## Only a bullet can crack it.
func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint.lightened(0.25), 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.15))
	# Smooth plated dome — reads as "hard, can't stomp".
	draw_circle(Vector2.ZERO, 7.5, tint.darkened(0.1))
	draw_arc(Vector2.ZERO, 7.5, PI, TAU, 14, tint.lightened(0.35), 1.6)
	draw_line(Vector2(0, -7), Vector2(0, 6), tint.darkened(0.4), 1.0)
	draw_line(Vector2(-5, -5), Vector2(-5, 5), tint.darkened(0.3), 0.8)
	draw_line(Vector2(5, -5), Vector2(5, 5), tint.darkened(0.3), 0.8)
	draw_circle(Vector2(_face * 2 - 1, 3), 1.2, Color.WHITE)
	draw_circle(Vector2(_face * 2 + 2, 3), 1.2, Color.WHITE)
