class_name Turret
extends Area2D
## A stationary emplacement that fires a slow, dodgeable projectile toward the
## player on a fixed interval — the game's first ranged threat. Stomp or shoot to
## destroy; touching its side is fatal.

const STOMP_BOUNCE := 210.0

var tint := Color(0.9, 0.4, 0.85)
var interval := 1.9

var _cd := 0.0
var _dead := false
var _t := 0.0
var _aim := 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(13, 12)
	s.shape = r
	s.position = Vector2(0, 1)
	add_child(s)
	_cd = randf_range(0.6, interval)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	if p:
		_aim = signf(p.global_position.x - global_position.x)
		if _aim == 0.0:
			_aim = 1.0
	_cd -= delta
	if _cd <= 0.0:
		_cd = interval
		_fire()
	queue_redraw()

func _fire() -> void:
	var b := EnemyProjectile.new()
	b.dir = Vector2(_aim, 0)
	b.tint = tint
	b.position = global_position + Vector2(_aim * 7.0, -2.0)
	get_parent().add_child(b)
	Audio.play("dash", 0.1)

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
	draw_rect(Rect2(-6, 0, 12, 7), tint.darkened(0.4))
	draw_rect(Rect2(-7, 6, 14, 2), tint.darkened(0.5))
	draw_circle(Vector2.ZERO, 5.0, tint.darkened(0.15))
	draw_rect(Rect2(0.0 if _aim > 0.0 else -8.0, -2.0, 8.0, 3.0), tint.lightened(0.2))
	var g := 0.5 + 0.5 * sin(_t * 6.0)
	draw_circle(Vector2(_aim * 7.0, -0.5), 1.6, Color(1, 1, 0.6, g))
