class_name Skeleton
extends Area2D
## Haunted Mansion. A shambling skeleton that paces its floor and lobs an arcing bone
## toward the player on a timer. Stomp from above to clatter it apart; a side touch is
## fatal.

const STOMP_BOUNCE := 220.0

var tint := Color(0.85, 0.86, 0.78)
var span := 30.0
var speed := 26.0

var _origin := Vector2.ZERO
var _face := 1.0
var _cd := 0.0
var _dead := false
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 5.0
	c.height = 14.0
	s.shape = c
	add_child(s)
	_origin = position
	_cd = randf_range(1.0, 2.2)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	position.x += _face * speed * delta
	if position.x > _origin.x + span:
		_face = -1.0
	elif position.x < _origin.x - span:
		_face = 1.0
	var p := _player()
	if p:
		_face = signf(p.global_position.x - global_position.x) if absf(p.global_position.x - global_position.x) > 4.0 else _face
	_cd -= delta
	if _cd <= 0.0:
		_cd = 2.0
		_throw(p)
	queue_redraw()

func _throw(p: Player) -> void:
	var d := _face
	if p:
		d = signf(p.global_position.x - global_position.x)
		if d == 0.0:
			d = _face
	var b := EnemyProjectile.new()
	b.dir = Vector2(d * 0.85, -0.5).normalized()
	b.tint = Color(0.9, 0.9, 0.82)
	b.speed = 96.0
	b.position = global_position + Vector2(d * 5.0, -6.0)
	get_parent().add_child(b)
	Audio.play("dash", 0.08)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var body := tint
	# Skull.
	draw_circle(Vector2(0, -4), 5.0, body)
	draw_circle(Vector2(-1.8, -4), 1.3, Color(0.1, 0.1, 0.12))
	draw_circle(Vector2(1.8, -4), 1.3, Color(0.1, 0.1, 0.12))
	# Ribcage.
	draw_rect(Rect2(-3, 1, 6, 7), body.darkened(0.1))
	for k in 3:
		draw_line(Vector2(-3, 2.0 + k * 2.0), Vector2(3, 2.0 + k * 2.0), body.darkened(0.35), 1.0)
	# Arm holding a bone.
	draw_line(Vector2(0, 2), Vector2(_face * 6.0, 0), body, 1.6)
	draw_circle(Vector2(_face * 7.0, 0), 1.6, body.lightened(0.1))
