class_name MagmaGolem
extends Area2D
## Volcano Core finale boss. A lumbering rock brute that alternates a glowing HOT
## state (armored — invulnerable, radiates a fireball fan) and a cooled crust state
## (dark — vulnerable to stomp/shoot). Also lobs arcing lava globs. Time your hits to
## the cool windows. 4 hits. Locks the exit.

const STOMP_BOUNCE := 240.0

var tint := Color(1.0, 0.5, 0.2)
var boss_name := "Magma Golem"     # themed per world (this hot/cool pattern is reused)
var hp := 4

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _hot := false
var _state_t := 0.0
var _atk := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 12.0
	s.shape = c
	add_child(s)
	_origin = position
	_state_t = 2.2
	_atk = 1.3
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	position = _origin + Vector2(sin(_t * 0.7) * 44.0, absf(sin(_t * 1.4)) * 4.0)
	_state_t -= delta
	if _state_t <= 0.0:
		_hot = not _hot
		_state_t = 2.4 if _hot else 2.0
		if _hot:
			_erupt()
	_atk -= delta
	if _atk <= 0.0:
		_atk = 1.6
		_lob()
	queue_redraw()

func _erupt() -> void:
	# Fan of fireballs upward when it flares hot.
	for a: float in [-0.5, -0.2, 0.2, 0.5]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(sin(a), -1.0).normalized()
		b.tint = Color(1.0, 0.6, 0.2)
		b.speed = 95.0
		b.position = global_position + Vector2(0, -8)
		get_parent().add_child(b)
	Audio.play("dash", 0.12)

func _lob() -> void:
	var p := _player()
	var d := -1.0 if (p and p.global_position.x < global_position.x) else 1.0
	var b := EnemyProjectile.new()
	b.dir = Vector2(d * 0.8, -0.6).normalized()
	b.tint = Color(1.0, 0.45, 0.15)
	b.speed = 88.0
	b.position = global_position + Vector2(d * 6.0, -4.0)
	get_parent().add_child(b)
	Audio.play("dash", 0.08)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -4.0
	if coming_down and above and not _hot:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if not _hot:
		_damage()

func _damage() -> void:
	if _dead or _invuln > 0.0:
		return
	hp -= 1
	_invuln = 0.6
	_hitflash = 0.25
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 14, 110.0, 0.45)
	if hp <= 0:
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("boss")
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 36, 160.0, 0.8, 3.4)
	Audio.play("complete")
	Game.toast.emit("★ %s crumbled! ★" % boss_name)
	queue_redraw()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var flashing := _hitflash > 0.0 and int(_hitflash * 30.0) % 2 == 0
	var crust := Color(0.28, 0.22, 0.24)
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	var body := Color(1, 1, 1) if flashing else (tint if _hot else crust)
	draw_circle(Vector2(0, 4), 12.0, Color(0, 0, 0, 0.18))
	draw_circle(Vector2(0, 0), 12.0, body.darkened(0.1))
	# Molten cracks that brighten when hot.
	var seam := tint.lightened(0.1) if _hot else tint.darkened(0.1)
	var sa := (0.9 if _hot else 0.35) * (0.6 + 0.4 * glow)
	seam.a = sa
	draw_line(Vector2(-8, -2), Vector2(-2, 4), seam, 1.6)
	draw_line(Vector2(2, -4), Vector2(7, 3), seam, 1.6)
	draw_line(Vector2(-3, 6), Vector2(4, 8), seam, 1.4)
	# Eyes.
	var ec := Color(1, 0.9, 0.4) if _hot else Color(0.9, 0.4, 0.2)
	draw_circle(Vector2(-4, -3), 2.0, ec)
	draw_circle(Vector2(4, -3), 2.0, ec)
	for i in hp:
		draw_circle(Vector2(-9.0 + i * 6.0, -15.0), 1.7, tint.lightened(0.2))
