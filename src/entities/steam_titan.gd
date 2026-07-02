class_name SteamTitan
extends Area2D
## Steam Factory finale boss. A hulking machine that stomps across the arena and cycles
## three attacks: PISTON (twin fast horizontal shots), GEAR TOSS (arcing sawtooth shots),
## and STEAM VENT (it flares — briefly armored/invulnerable — spewing an upward fan). Hit
## it between vents (stomp head or shoot). 6 hits — the toughest boss. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.72, 0.76, 0.84)
var boss_name := "Steam Titan"     # themed per world (this piston/vent pattern is reused)
var hp := 6

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _atk := 0.0
var _phase := 0
var _venting := 0.0

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
	_atk = 1.4
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	_venting = maxf(0.0, _venting - delta)
	position = _origin + Vector2(sin(_t * 0.6) * 60.0, absf(sin(_t * 1.2)) * 5.0)
	_atk -= delta
	if _atk <= 0.0:
		_atk = maxf(1.0, 2.0 - (6 - hp) * 0.15)
		_do_attack()
		_phase = (_phase + 1) % 3
	queue_redraw()

func _do_attack() -> void:
	match _phase:
		0:
			# Piston: twin fast horizontal shots both ways.
			for d: float in [-1.0, 1.0]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(d, 0)
				b.tint = Color(0.9, 0.8, 0.5)
				b.speed = 130.0
				b.position = global_position + Vector2(d * 10.0, 0)
				get_parent().add_child(b)
			Audio.play("stomp", 0.1)
		1:
			# Gear toss: arcing shots.
			var p := _player()
			var d := -1.0 if (p and p.global_position.x < global_position.x) else 1.0
			for a: float in [-0.2, 0.15]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(d * 0.8, -0.6).rotated(a).normalized()
				b.tint = Color(0.8, 0.82, 0.86)
				b.speed = 96.0
				b.position = global_position + Vector2(0, -6)
				get_parent().add_child(b)
			Audio.play("dash", 0.1)
		2:
			# Steam vent: armor up and spew an upward fan.
			_venting = 1.0
			for a: float in [-0.6, -0.3, 0.0, 0.3, 0.6]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(sin(a), -1.0).normalized()
				b.tint = Color(0.9, 0.95, 1.0)
				b.speed = 90.0
				b.position = global_position + Vector2(0, -10)
				get_parent().add_child(b)
			Audio.play("dash", 0.14)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	if coming_down and above and _venting <= 0.0:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if _venting <= 0.0:
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
	Burst.spawn(get_parent(), global_position, Color(1, 0.9, 0.6), 38, 170.0, 0.85, 3.6)
	Audio.play("complete")
	Game.toast.emit("★ %s scrapped! ★" % boss_name)
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
	var venting := _venting > 0.0
	var body := Color(1, 1, 1) if flashing else (tint.lightened(0.15) if venting else tint)
	# Boiler torso.
	draw_rect(Rect2(-12, -4, 24, 20), body.darkened(0.25))
	draw_rect(Rect2(-12, -4, 24, 5), body.darkened(0.1))
	# Rivets.
	for rx: float in [-9.0, 0.0, 9.0]:
		draw_circle(Vector2(rx, 12), 1.4, body.darkened(0.4))
	# Head.
	draw_circle(Vector2(0, -8), 9.0, body.darkened(0.15))
	# Chimney venting steam.
	draw_rect(Rect2(-3, -18, 6, 6), body.darkened(0.3))
	if venting:
		draw_circle(Vector2(0, -22), 4.0 + sin(_t * 20.0), Color(1, 1, 1, 0.5))
	# Eyes glow hotter while venting.
	var ec := Color(1, 0.6, 0.2) if venting else Color(1, 0.85, 0.3)
	draw_circle(Vector2(-4, -8), 2.0, ec)
	draw_circle(Vector2(4, -8), 2.0, ec)
	for i in hp:
		draw_circle(Vector2(-15.0 + i * 6.0, 19.0), 1.6, tint.lightened(0.3))
