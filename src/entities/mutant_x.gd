class_name MutantX
extends Area2D
## Toxic Laboratory finale boss — Experiment X, an unstable blob. It creeps across the
## arena and cycles: ACID SPRAY (downward spread), SPLIT (spawns a Splitter slime), and
## ENRAGE (a fast lunge toward the player — lethal, can't be stomped mid-charge). Stomp
## or shoot between charges. 5 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.6, 0.95, 0.35)
var hp := 5

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _atk := 0.0
var _phase := 0
var _charge := 0.0
var _charge_dir := 0.0

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
	_atk = 1.4
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	if _charge > 0.0:
		_charge -= delta
		position.x += _charge_dir * 150.0 * delta
	else:
		position = _origin + Vector2(sin(_t * 0.7) * 52.0, absf(sin(_t * 1.5)) * 6.0)
		_atk -= delta
		if _atk <= 0.0:
			_atk = maxf(1.1, 2.0 - (5 - hp) * 0.15)
			_do_attack()
			_phase = (_phase + 1) % 3
	queue_redraw()

func _do_attack() -> void:
	match _phase:
		0:
			for a: float in [-0.5, -0.15, 0.15, 0.5]:
				var b := EnemyProjectile.new()
				b.dir = Vector2(sin(a), cos(a) * 0.6 + 0.5).normalized()
				b.tint = Color(0.65, 1.0, 0.35)
				b.speed = 88.0
				b.position = global_position + Vector2(0, 8)
				get_parent().add_child(b)
			Audio.play("dash", 0.1)
		1:
			var z := Splitter.new()
			z.tint = Color(0.55, 0.9, 0.4)
			z.position = global_position + Vector2(0, 16)
			get_parent().add_child(z)
			Audio.play("star", 0.1)
		2:
			var p := _player()
			_charge_dir = signf(p.global_position.x - global_position.x) if p else -1.0
			if _charge_dir == 0.0:
				_charge_dir = 1.0
			_charge = 0.7
			Audio.play("dash", 0.14)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	# Can't be stomped while charging.
	if coming_down and above and _charge <= 0.0:
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
	Game.toast.emit("★ Experiment X neutralized! ★")
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
	var enraged := _charge > 0.0
	var body := Color(1, 1, 1) if flashing else (tint.lightened(0.15) if enraged else tint)
	# Wobbling blob.
	var wob := sin(_t * 8.0) * 1.5
	draw_circle(Vector2(0, 6), 13.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2(0, wob), 13.0, body.darkened(0.15))
	draw_circle(Vector2(0, 1 + wob), 13.0, body.darkened(0.3))
	# Bubbling nuclei.
	for k in 4:
		var a := _t * 1.5 + k * 1.6
		draw_circle(Vector2(cos(a) * 6.0, sin(a) * 4.0 + wob), 2.0, Color(0.9, 1.0, 0.5, 0.7))
	# Mutant eyes (extra one when enraged).
	draw_circle(Vector2(-5, -2 + wob), 2.4, Color.WHITE)
	draw_circle(Vector2(5, -2 + wob), 2.4, Color.WHITE)
	draw_circle(Vector2(-5, -2 + wob), 1.2, Color(0.8, 0.1, 0.2))
	draw_circle(Vector2(5, -2 + wob), 1.2, Color(0.8, 0.1, 0.2))
	if enraged:
		draw_circle(Vector2(0, -7 + wob), 1.8, Color(0.8, 0.1, 0.2))
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 18.0), 1.7, tint.lightened(0.35))
