class_name Leviathan
extends Area2D
## Sunken Depths finale boss. A great sea serpent that swims a broad sine arc across
## the flooded arena, periodically lunging down at the player and spitting water jets.
## Stomp its head when the arc dips low, or shoot it. 4 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.3, 0.75, 0.95)
var hp := 4

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _atk := 0.0
var _lunge := 0.0

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
	_atk = 1.5
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	_lunge = maxf(0.0, _lunge - delta)
	var sweep := 66.0 + (4 - hp) * 5.0
	var dip := absf(sin(_t * 1.3)) * 30.0
	if _lunge > 0.0:
		dip += 26.0 * (_lunge / 0.6)     # extra plunge toward the floor
	position = _origin + Vector2(sin(_t * 0.7) * sweep, dip)
	_atk -= delta
	if _atk <= 0.0:
		_atk = maxf(1.0, 1.9 - (4 - hp) * 0.2)
		if randf() < 0.5:
			_lunge = 0.6
		_spit()
	queue_redraw()

func _spit() -> void:
	var p := _player()
	var dir := Vector2.DOWN
	if p:
		dir = (p.global_position - global_position).normalized()
	for a: float in [-0.2, 0.0, 0.2]:
		var b := EnemyProjectile.new()
		b.dir = dir.rotated(a)
		b.tint = Color(0.5, 0.85, 1.0)
		b.speed = 92.0
		b.position = global_position + Vector2(0, 6)
		get_parent().add_child(b)
	Audio.play("dash", 0.1)

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
	Game.toast.emit("★ Leviathan vanquished! ★")
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
	# Trailing coils behind the head.
	for k in range(1, 5):
		var off := Vector2(-sin(_t * 0.7 + k * 0.5) * 8.0 * k, cos(_t * 1.3 + k * 0.6) * 4.0 + k * 2.0)
		draw_circle(off, 9.0 - k * 1.2, body.darkened(0.2 + k * 0.05))
	# Head.
	draw_circle(Vector2(0, 0), 12.0, body.darkened(0.1))
	draw_circle(Vector2(0, 2), 12.0, body.darkened(0.24))
	# Fins.
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -4), Vector2(-16, -10), Vector2(-8, -8)]), body.lightened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(10, -4), Vector2(16, -10), Vector2(8, -8)]), body.lightened(0.15))
	# Eyes.
	draw_circle(Vector2(-4, -2), 2.0, Color(1, 0.85, 0.3))
	draw_circle(Vector2(4, -2), 2.0, Color(1, 0.85, 0.3))
	draw_circle(Vector2(-4, -2), 1.0, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(4, -2), 1.0, Color(0.1, 0.1, 0.15))
	for i in hp:
		draw_circle(Vector2(-9.0 + i * 6.0, 15.0), 1.7, tint.lightened(0.35))
