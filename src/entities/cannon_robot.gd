class_name CannonRobot
extends Area2D
## Space Station. A stationary robot that locks on, flashes a wind-up, then fires a
## three-way spread (angled up / straight / down) toward the player. Stomp or shoot
## to scrap it; touching its side is fatal. Distinct from the Turret's single shot.

const STOMP_BOUNCE := 210.0

var tint := Color(0.7, 0.82, 1.0)
var interval := 2.3

var _cd := 0.0
var _warn := 0.0
var _dead := false
var _t := 0.0
var _aim := 1.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(13, 13)
	s.shape = r
	add_child(s)
	_cd = randf_range(0.8, interval)
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
	if _warn > 0.0:
		_warn -= delta
		if _warn <= 0.0:
			_fire()
	elif _cd <= 0.0:
		_cd = interval
		_warn = 0.5     # telegraph before the volley
	queue_redraw()

func _fire() -> void:
	for a: float in [-0.45, 0.0, 0.45]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(_aim, 0).rotated(a * _aim)
		b.tint = tint
		b.speed = 96.0
		b.position = global_position + Vector2(_aim * 7.0, -1.0)
		get_parent().add_child(b)
	Audio.play("dash", 0.12)

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
	Burst.spawn(get_parent(), global_position, tint, 14, 100.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var charging := _warn > 0.0 and int(_warn * 20.0) % 2 == 0
	var body := Color(1, 1, 1) if charging else tint.darkened(0.1)
	draw_rect(Rect2(-6, -6, 12, 12), body.darkened(0.35))
	draw_rect(Rect2(-6, -6, 12, 3), body.darkened(0.15))
	# tri-barrel muzzle
	var mx := _aim * 6.0
	for oy: float in [-3.0, 0.0, 3.0]:
		draw_rect(Rect2(mx if _aim > 0.0 else mx - 4.0, oy - 1.0, 4.0, 2.0), body.lightened(0.2))
	var g := 0.5 + 0.5 * sin(_t * 6.0)
	draw_circle(Vector2(0, -1), 2.0, Color(1, 0.9, 0.4, g if not charging else 1.0))
