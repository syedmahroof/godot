class_name Enemy
extends Area2D
## A goofy patrolling blob. Touch it from the side and you die; stomp it from
## above and it pops (and bounces you). Patrols on a smooth sine path so its
## bounds are predictable and fair.

const STOMP_BOUNCE := 250.0

var span := 34.0
var speed := 1.4
var _origin := Vector2.ZERO
var _t := 0.0
var _face := 1.0
var _dead := false
var _blink := 0.0

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
	_blink += delta
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
	# Stomp: player above the blob and descending (relative to gravity).
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	if coming_down and above:
		_pop(p)
	else:
		p.die()

func _pop(p: Player) -> void:
	p.bounce(STOMP_BOUNCE)
	hit()

## Kill it (stomp or bullet).
func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, Color(0.95, 0.45, 0.55), 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	var wob := sin(_blink * 8.0) * 0.6
	# Soft shadow glow.
	draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.15))
	# Body.
	var body := Color(0.93, 0.36, 0.45)
	draw_circle(Vector2(0, 0 + wob), 7.0, body)
	draw_circle(Vector2(0, 1 + wob), 7.0, body.darkened(0.15))
	# Cute angry eyes looking the way it walks.
	var ex := 2.0 * _face
	draw_circle(Vector2(ex - 2.0, -1 + wob), 1.6, Color.WHITE)
	draw_circle(Vector2(ex + 2.0, -1 + wob), 1.6, Color.WHITE)
	draw_circle(Vector2(ex - 2.0 + _face, -1 + wob), 0.9, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(ex + 2.0 + _face, -1 + wob), 0.9, Color(0.1, 0.1, 0.15))
