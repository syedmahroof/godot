class_name MushroomKing
extends Area2D
## Giant Mushroom Forest finale boss. A giant fungus that bounds around the arena in big
## hops, and on every landing bursts a ring of toxic spores and sometimes sprouts a
## little mushroom minion (an Enemy). Stomp its cap or shoot it — it's vulnerable any
## time, but landing on a hopping target is the trick. 5 hits. Locks the exit.

const STOMP_BOUNCE := 260.0

var tint := Color(0.7, 0.4, 0.85)
var boss_name := "Mushroom King"   # themed per world (this hop pattern is reused)
var hp := 5

var _ground_y := 0.0
var _vy := 0.0
var _on_ground := true
var _wait := 0.0
var _dir := 1.0
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false

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
	_ground_y = position.y
	_wait = 1.0
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	if _on_ground:
		_wait -= delta
		if _wait <= 0.0:
			var p := _player()
			_dir = signf(p.global_position.x - global_position.x) if p else -_dir
			if _dir == 0.0:
				_dir = 1.0
			_vy = -230.0
			_on_ground = false
			Audio.play("jump", 0.08)
	else:
		_vy += 480.0 * delta
		position.y += _vy * delta
		position.x += _dir * 62.0 * delta
		if position.y >= _ground_y:
			position.y = _ground_y
			_on_ground = true
			_wait = maxf(0.5, 1.0 - (5 - hp) * 0.1)
			_land()
	queue_redraw()

func _land() -> void:
	# Ring of spores on impact.
	var n := 6
	for i in n:
		var ang := PI + (PI * i / (n - 1))   # upward hemisphere
		var b := EnemyProjectile.new()
		b.dir = Vector2(cos(ang), sin(ang))
		b.tint = Color(0.6, 0.95, 0.4)
		b.speed = 82.0
		b.position = global_position + Vector2(0, -4)
		get_parent().add_child(b)
	if hp <= 3 and randf() < 0.4:
		var e := Enemy.new()
		e.position = global_position + Vector2(_dir * 10.0, 0)
		get_parent().add_child(e)
	Burst.spawn(get_parent(), global_position + Vector2(0, 8), Color(0.6, 0.95, 0.4), 10, 90.0, 0.4)
	Audio.play("stomp", 0.1)

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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 36, 160.0, 0.85, 3.4)
	Audio.play("complete")
	Game.toast.emit("★ %s toppled! ★" % boss_name)
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
	var cap := Color(1, 1, 1) if flashing else tint
	# Stalk.
	draw_rect(Rect2(-5, 2, 10, 12), Color(0.95, 0.92, 0.8))
	# Cap.
	draw_circle(Vector2(0, 0), 14.0, cap.darkened(0.1))
	draw_circle(Vector2(0, -3), 13.0, cap)
	# Cap spots.
	for sp: Vector2 in [Vector2(-6, -2), Vector2(6, -3), Vector2(0, -7), Vector2(-3, 2)]:
		draw_circle(sp, 2.0, Color(1, 1, 0.9, 0.85))
	# Eyes on the stalk.
	draw_circle(Vector2(-3, 6), 1.6, Color(0.1, 0.1, 0.12))
	draw_circle(Vector2(3, 6), 1.6, Color(0.1, 0.1, 0.12))
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 17.0), 1.7, tint.lightened(0.35))
