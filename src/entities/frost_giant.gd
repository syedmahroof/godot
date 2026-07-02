class_name FrostGiant
extends Area2D
## Frosty Peaks finale boss. A towering ice brute rooted to the arena floor: it rains
## icicles over the player, slams the ground to send shockwaves skating along the
## floor both ways, and bellows up a snow flyer. Stomp its head (it bobs) or shoot.
## 5 hits — the tankiest guardian yet. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.75, 0.88, 1.0)
var hp := 5
var stem_len := 30.0

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _atk := 0.0
var _phase := 0
var _dead := false
var _hitflash := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 13.0
	s.shape = c
	add_child(s)
	_origin = position
	_atk = 1.6
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	position = _origin + Vector2(sin(_t * 0.8) * 28.0, sin(_t * 1.6) * 5.0)
	_atk -= delta
	if _atk <= 0.0:
		_atk = maxf(1.2, 2.3 - (5 - hp) * 0.2)
		_do_attack()
		_phase = (_phase + 1) % 3

	queue_redraw()

func _do_attack() -> void:
	match _phase:
		0:
			# Icicle rain above the player.
			var p := _player()
			var px := p.global_position.x if p else global_position.x
			for dx: float in [-16.0, 0.0, 16.0]:
				var b := EnemyProjectile.new()
				b.dir = Vector2.DOWN
				b.tint = Color(0.8, 0.92, 1.0)
				b.speed = 120.0
				b.position = Vector2(px + dx, global_position.y - 64.0)
				get_parent().add_child(b)
			Audio.play("dash", 0.1)
		1:
			# Ground-slam shockwaves both ways along the floor.
			for d: float in [-1.0, 1.0]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(d, 0)
				b.tint = Color(0.7, 0.85, 1.0)
				b.speed = 90.0
				b.position = global_position + Vector2(d * 8.0, stem_len - 4.0)
				get_parent().add_child(b)
			Audio.play("stomp", 0.12)
		2:
			var f := Flyer.new()
			f.tint = Color(0.9, 0.97, 1.0)
			f.position = global_position + Vector2(0, -18)
			get_parent().add_child(f)
			Audio.play("star", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -5.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	_damage()

func _damage() -> void:
	if _dead or _invuln > 0.0:
		return
	hp -= 1
	_invuln = 0.7
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
	Game.toast.emit("★ Frost Giant shattered! ★")
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
	# Bulky torso down to the floor.
	draw_rect(Rect2(-10, 6, 20, stem_len - 4), body.darkened(0.28))
	draw_rect(Rect2(-8, 6, 16, stem_len - 4), body.darkened(0.15))
	# Head.
	draw_circle(Vector2(0, 0), 13.0, body.darkened(0.1))
	draw_circle(Vector2(0, 2), 13.0, body.darkened(0.24))
	# Ice horns.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -8), Vector2(-5, -6), Vector2(-13, -18)]), body.lightened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(9, -8), Vector2(5, -6), Vector2(13, -18)]), body.lightened(0.25))
	# Eyes.
	draw_circle(Vector2(-4, -1), 2.0, Color(0.2, 0.5, 0.9))
	draw_circle(Vector2(4, -1), 2.0, Color(0.2, 0.5, 0.9))
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, -16.0), 1.7, Color(0.7, 0.9, 1.0))
