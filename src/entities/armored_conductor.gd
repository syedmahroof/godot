class_name ArmoredConductor
extends Area2D
## Moving Train finale boss. A plated brute that charges up and down the carriage
## (armored — invulnerable and lethal to touch), then stops and throws open his hatch
## to fire a volley (vulnerable window — stomp or shoot then). He also calls a guard
## (a Charger) below half health. 5 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.7, 0.55, 0.45)
var hp := 5

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _open := false
var _state_t := 0.0
var _atk := 0.0

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
	_state_t = 2.4
	_atk = 0.6
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	_state_t -= delta
	if _state_t <= 0.0:
		_open = not _open
		_state_t = (1.6 if _open else 2.4) - (5 - hp) * 0.1
		_atk = 0.3
	if _open:
		# Hatch open: stationary, fire volleys.
		_atk -= delta
		if _atk <= 0.0:
			_atk = 0.6
			_fire()
	else:
		# Armored charge sweep.
		position = _origin + Vector2(sin(_t * 1.3) * 66.0, 0)
	queue_redraw()

func _fire() -> void:
	var p := _player()
	var dir := Vector2.DOWN
	if p:
		dir = (p.global_position - global_position).normalized()
	for a: float in [-0.2, 0.0, 0.2]:
		var b := EnemyProjectile.new()
		b.dir = dir.rotated(a)
		b.tint = Color(1.0, 0.7, 0.35)
		b.speed = 108.0
		b.position = global_position + Vector2(0, 4)
		get_parent().add_child(b)
	if hp <= 3 and randf() < 0.3:
		var c := Charger.new()
		c.tint = Color(0.7, 0.5, 0.4)
		c.position = global_position + Vector2(0, 22)
		get_parent().add_child(c)
	Audio.play("dash", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	if coming_down and above and _open:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if _open:
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
	Game.toast.emit("★ Armored Conductor derailed! ★")
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
	# Armored torso.
	draw_rect(Rect2(-12, -6, 24, 22), body.darkened(0.3))
	draw_rect(Rect2(-12, -6, 24, 5), body.darkened(0.1))
	# Bolts.
	for bx: float in [-9.0, 0.0, 9.0]:
		draw_circle(Vector2(bx, 12), 1.4, body.darkened(0.45))
	# Conductor cap.
	draw_rect(Rect2(-8, -13, 16, 5), body.darkened(0.4))
	draw_rect(Rect2(-9, -9, 18, 2), body.darkened(0.25))
	# Hatch: closed = armored plate; open = glowing vulnerable core.
	if _open:
		var g := 0.6 + 0.4 * sin(_t * 10.0)
		draw_circle(Vector2(0, 2), 5.0, Color(1.0, 0.8, 0.3, g))
		draw_circle(Vector2(0, 2), 2.5, Color(1, 1, 0.8))
	else:
		draw_rect(Rect2(-5, -2, 10, 8), body.lightened(0.15))
	# Eyes.
	draw_circle(Vector2(-4, -8), 1.6, Color(1, 0.85, 0.3))
	draw_circle(Vector2(4, -8), 1.6, Color(1, 0.85, 0.3))
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 19.0), 1.6, tint.lightened(0.3))
