class_name GiantSpider
extends Area2D
## Haunted Hollow finale boss — the Broodmother. Hangs from the ceiling on a thread,
## drifting side to side. Periodically drops straight down at the player (telegraphed),
## hangs low for a beat (stomp window), then reels back up. Spits web shots and drops
## small spiders. 4 hits (stomp when low, or shoot). Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.5, 0.42, 0.6)
var hp := 4

enum { HANG, WARN, DROP, LOW, RISE }
var _state := HANG
var _timer := 0.0
var _t := 0.0
var _top_y := 0.0
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
	c.radius = 12.0
	s.shape = c
	add_child(s)
	_top_y = position.y
	_timer = 2.0
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	_timer -= delta
	match _state:
		HANG:
			position.x = _origin_x() + sin(_t * 0.9) * 46.0
			position.y = _top_y + sin(_t * 1.8) * 4.0
			if _timer <= 0.0:
				# Line up over the player before dropping.
				var p := _player()
				if p:
					position.x = p.global_position.x
				_state = WARN
				_timer = 0.55
				if randf() < 0.5:
					_spit()
		WARN:
			if _timer <= 0.0:
				_state = DROP
		DROP:
			position.y = move_toward(position.y, _top_y + 74.0, 320.0 * delta)
			if position.y >= _top_y + 74.0:
				_state = LOW
				_timer = 0.7
				if randf() < 0.6:
					_drop_spider()
		LOW:
			if _timer <= 0.0:
				_state = RISE
		RISE:
			position.y = move_toward(position.y, _top_y, 120.0 * delta)
			if position.y <= _top_y + 0.5:
				_state = HANG
				_timer = maxf(1.0, 1.9 - (4 - hp) * 0.22)
	queue_redraw()

func _origin_x() -> float:
	return position.x   # sways around wherever it currently is

func _spit() -> void:
	var p := _player()
	var dir := Vector2.DOWN
	if p:
		dir = (p.global_position - global_position).normalized()
	var b := EnemyProjectile.new()
	b.dir = dir
	b.tint = Color(0.9, 0.95, 1.0)
	b.speed = 96.0
	b.position = global_position + Vector2(0, 8)
	get_parent().add_child(b)
	Audio.play("dash", 0.1)

func _drop_spider() -> void:
	var s := Spider.new()
	s.position = global_position + Vector2(0, 12)
	get_parent().add_child(s)
	Audio.play("star", 0.08)

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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 34, 150.0, 0.75, 3.2)
	Audio.play("complete")
	Game.toast.emit("★ Broodmother slain! ★")
	queue_redraw()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	# Thread up to the ceiling.
	draw_line(Vector2(0, -8), Vector2(0, _top_y - position.y - 4.0), Color(0.9, 0.9, 1.0, 0.35), 1.0)
	var flashing := _hitflash > 0.0 and int(_hitflash * 30.0) % 2 == 0
	var body := Color(1, 1, 1) if flashing else tint
	# Legs.
	for k in 4:
		var yy := -3.0 + k * 3.0
		var sp := 12.0 + sin(_t * 6.0 + k) * 2.0
		draw_line(Vector2(0, yy), Vector2(-sp, yy + 5), body.darkened(0.3), 1.6)
		draw_line(Vector2(0, yy), Vector2(sp, yy + 5), body.darkened(0.3), 1.6)
	# Abdomen + head.
	draw_circle(Vector2(0, 4), 12.0, body.darkened(0.2))
	draw_circle(Vector2(0, -3), 7.0, body)
	# Cluster of eyes.
	for e: Vector2 in [Vector2(-3, -4), Vector2(3, -4), Vector2(-1.5, -1), Vector2(1.5, -1)]:
		draw_circle(e, 1.3, Color(1, 0.3, 0.4))
	for i in hp:
		draw_circle(Vector2(-9.0 + i * 6.0, 16.0), 1.7, tint.lightened(0.35))
