class_name SandGuardian
extends Area2D
## Desert Ruins finale boss — the Ancient Sand Guardian, a stone sphinx. It alternates
## a raised SAND-SHIELD state (armored — invulnerable, blasts a horizontal sand gust)
## and a lowered state (vulnerable) where it lobs a spread of sand shots and calls up a
## scorpion (a Charger). Hit it only when unshielded. 5 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.86, 0.68, 0.36)
var boss_name := "Sand Guardian"   # themed per world (this pattern is reused)
var hp := 5

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _shield := false
var _state_t := 0.0
var _atk := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	s.shape = c
	add_child(s)
	_origin = position
	_state_t = 2.4
	_atk = 1.4
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	position = _origin + Vector2(sin(_t * 0.7) * 50.0, absf(sin(_t * 1.4)) * 5.0)
	_state_t -= delta
	if _state_t <= 0.0:
		_shield = not _shield
		_state_t = 2.2 if _shield else 2.4
		if _shield:
			_gust()
	_atk -= delta
	if _atk <= 0.0:
		_atk = 1.7
		if not _shield:
			_lob()
			if hp <= 3 and randf() < 0.4:
				_summon()
	queue_redraw()

func _gust() -> void:
	# Horizontal sand blasts both ways when the shield snaps up.
	for d: float in [-1.0, 1.0]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(d, 0)
		b.tint = Color(0.9, 0.75, 0.4)
		b.speed = 110.0
		b.position = global_position + Vector2(d * 10.0, 2)
		get_parent().add_child(b)
	Audio.play("dash", 0.12)

func _lob() -> void:
	for a: float in [-0.6, -0.2, 0.2, 0.6]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(sin(a), -1.0).normalized()
		b.tint = Color(0.92, 0.78, 0.45)
		b.speed = 92.0
		b.position = global_position + Vector2(0, -8)
		get_parent().add_child(b)
	Audio.play("dash", 0.1)

func _summon() -> void:
	var c := Charger.new()
	c.tint = Color(0.7, 0.5, 0.3)
	c.position = global_position + Vector2(0, 24)
	get_parent().add_child(c)
	Audio.play("star", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	if coming_down and above and not _shield:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if not _shield:
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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 36, 160.0, 0.85, 3.4)
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
	var body := Color(1, 1, 1) if flashing else tint
	# Sphinx head.
	draw_circle(Vector2(0, 2), 14.0, body.darkened(0.2))
	draw_circle(Vector2(0, 0), 13.0, body.darkened(0.05))
	# Headdress stripes.
	draw_rect(Rect2(-13, -10, 26, 4), body.darkened(0.35))
	draw_line(Vector2(-10, -6), Vector2(-13, 6), body.darkened(0.3), 2.0)
	draw_line(Vector2(10, -6), Vector2(13, 6), body.darkened(0.3), 2.0)
	# Eyes.
	draw_circle(Vector2(-5, -1), 2.2, Color(0.2, 0.6, 0.9))
	draw_circle(Vector2(5, -1), 2.2, Color(0.2, 0.6, 0.9))
	# Sand shield shimmer when armored.
	if _shield:
		var a := 0.4 + 0.2 * sin(_t * 12.0)
		draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.95, 0.8, 0.4, a), 2.5)
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 20.0), 1.7, tint.lightened(0.3))
