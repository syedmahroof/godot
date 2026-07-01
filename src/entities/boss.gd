class_name Boss
extends Area2D
## A reusable "World Guardian" mini-boss. Sweeps across the top of the arena,
## bobbing down, and periodically fires a downward spread of shots. Takes several
## hits (stomp from above or shoot) with a brief invulnerability + flash between
## hits; on defeat it bursts, cheers, and clears out. Tinted per world.

const STOMP_BOUNCE := 260.0

var tint := Color(1.0, 0.4, 0.4)
var hp := 3

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _atk := 0.0
var _dead := false
var _hitflash := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")     # the exit stays locked while any boss is alive
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 13.0
	s.shape = c
	add_child(s)
	_origin = position
	_atk = 2.0

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	position = _origin + Vector2(sin(_t * 0.9) * 70.0, absf(sin(_t * 1.8)) * 20.0)
	_atk -= delta
	if _atk <= 0.0:
		_atk = 2.6
		_attack()
	queue_redraw()

func _attack() -> void:
	for a: float in [-0.5, 0.0, 0.5]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(sin(a), cos(a) * 0.8 + 0.4).normalized()
		b.tint = tint
		b.speed = 80.0
		b.position = global_position + Vector2(0, 10)
		get_parent().add_child(b)
	Audio.play("dash", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

## Bullets call this.
func hit() -> void:
	_damage()

func _damage() -> void:
	if _dead or _invuln > 0.0:
		return
	hp -= 1
	_invuln = 0.8
	_hitflash = 0.25
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 12, 100.0, 0.45)
	if hp <= 0:
		_die()

func _die() -> void:
	if _dead:
		return
	_dead = true
	remove_from_group("boss")     # unlock the exit the instant it falls
	Burst.spawn(get_parent(), global_position, tint.lightened(0.25), 30, 150.0, 0.7, 3.0)
	Audio.play("complete")
	Game.toast.emit("★ Guardian defeated! ★")
	queue_redraw()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	var flashing := _hitflash > 0.0 and int(_hitflash * 30.0) % 2 == 0
	var body := Color(1, 1, 1) if flashing else tint
	draw_circle(Vector2(0, 12), 13.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2.ZERO, 13.0, body.darkened(0.1))
	draw_circle(Vector2(0, 2), 13.0, body.darkened(0.28))
	# Jagged crown.
	for k in 5:
		var cx := -8.0 + k * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 2, -9), Vector2(cx + 2, -9), Vector2(cx, -16)]), body.lightened(0.25))
	# Angry eyes.
	draw_circle(Vector2(-4, -2), 2.4, Color.WHITE)
	draw_circle(Vector2(4, -2), 2.4, Color.WHITE)
	draw_circle(Vector2(-4, -2), 1.3, Color(0.1, 0.05, 0.1))
	draw_circle(Vector2(4, -2), 1.3, Color(0.1, 0.05, 0.1))
	# HP pips.
	for i in hp:
		draw_circle(Vector2(-6.0 + i * 6.0, 17.0), 1.8, Color(1, 0.35, 0.35))
