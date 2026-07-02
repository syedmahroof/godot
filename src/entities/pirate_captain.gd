class_name PirateCaptain
extends Area2D
## Pirate Island finale boss. A swaggering buccaneer who paces the deck and cycles:
## CANNONADE (an arc of cannonball shots), PARROT (looses a dive-bombing parrot), and
## CUTLASS RUSH (a fast lunge at the player — lethal, no stomp mid-rush). Stomp his hat
## or shoot him between rushes. 5 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.85, 0.3, 0.3)
var hp := 5

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _atk := 0.0
var _phase := 0
var _rush := 0.0
var _rush_dir := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 8.0
	c.height = 20.0
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
	if _rush > 0.0:
		_rush -= delta
		position.x += _rush_dir * 160.0 * delta
	else:
		position = _origin + Vector2(sin(_t * 0.8) * 56.0, 0)
		_atk -= delta
		if _atk <= 0.0:
			_atk = maxf(1.1, 2.0 - (5 - hp) * 0.15)
			_do_attack()
			_phase = (_phase + 1) % 3
	queue_redraw()

func _do_attack() -> void:
	match _phase:
		0:
			for a: float in [-0.6, -0.25, 0.1]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(sin(a), -0.7).normalized()
				b.tint = Color(0.2, 0.2, 0.22)
				b.speed = 96.0
				b.position = global_position + Vector2(0, -6)
				get_parent().add_child(b)
				# mirror for the other side too
				var b2 := EnemyProjectile.new()
				b2.dir = Vector2(-sin(a), -0.7).normalized()
				b2.tint = Color(0.2, 0.2, 0.22)
				b2.speed = 96.0
				b2.position = global_position + Vector2(0, -6)
				get_parent().add_child(b2)
			Audio.play("dash", 0.12)
		1:
			var w := DiveBomber.new()
			w.tint = Color(0.9, 0.7, 0.2)
			w.position = global_position + Vector2(0, -16)
			get_parent().add_child(w)
			Audio.play("star", 0.1)
		2:
			var p := _player()
			_rush_dir = signf(p.global_position.x - global_position.x) if p else -1.0
			if _rush_dir == 0.0:
				_rush_dir = 1.0
			_rush = 0.7
			Audio.play("dash", 0.14)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -8.0
	if coming_down and above and _rush <= 0.0:
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
	Game.toast.emit("★ Pirate Captain plundered! ★")
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
	# Coat.
	draw_rect(Rect2(-8, -4, 16, 18), body.darkened(0.2))
	draw_line(Vector2(0, -4), Vector2(0, 14), body.darkened(0.4), 1.0)
	# Head.
	draw_circle(Vector2(0, -8), 6.0, Color(0.95, 0.8, 0.7))
	# Tricorn hat.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -11), Vector2(9, -11), Vector2(0, -18)]), Color(0.15, 0.12, 0.14))
	draw_circle(Vector2(0, -13), 1.3, Color(0.95, 0.9, 0.8))   # skull emblem
	# Eyepatch + eye.
	draw_line(Vector2(-5, -9), Vector2(2, -7), Color(0.1, 0.1, 0.12), 1.6)
	draw_circle(Vector2(3, -8), 1.2, Color(0.1, 0.1, 0.12))
	# Cutlass (thrust while rushing).
	var cx := (_rush_dir if _rush > 0.0 else 1.0) * 10.0
	draw_line(Vector2(cx * 0.5, 2), Vector2(cx, -2), Color(0.85, 0.9, 0.95), 1.6)
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 17.0), 1.7, tint.lightened(0.35))
