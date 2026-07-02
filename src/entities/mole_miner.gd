class_name MoleMiner
extends Area2D
## Forgotten Tunnels finale boss — the Tunnel King. A whack-a-mole fight: he surfaces
## (vulnerable — stomp or shoot), hurls rock shots, then BURROWS (invulnerable, hidden)
## and erupts under the player's feet after a telegraph mound. 4 hits. Locks the exit.

const STOMP_BOUNCE := 240.0
const SURFACE_Y := 0.0

var tint := Color(0.7, 0.5, 0.32)
var hp := 4

enum { SURFACE, THROW, BURROW, WARN }
var _state := SURFACE
var _timer := 0.0
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _ground_y := 0.0
var _shape: CollisionShape2D
var _warn_x := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("boss")
	_shape = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 11.0
	_shape.shape = c
	add_child(_shape)
	_ground_y = position.y
	_timer = 2.4
	body_entered.connect(_on_body_entered)

func _surfaced() -> bool:
	return _state == SURFACE or _state == THROW

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	_timer -= delta
	match _state:
		SURFACE:
			position.y = _ground_y
			if _timer <= 0.0:
				_state = THROW
				_timer = 0.3
				_throw()
		THROW:
			if _timer <= 0.0:
				_state = BURROW
				_timer = 0.7
				Burst.spawn(get_parent(), global_position, tint.darkened(0.2), 12, 90.0, 0.4)
		BURROW:
			position.y = _ground_y + 26.0     # hidden below the floor
			_shape.disabled = true
			if _timer <= 0.0:
				var p := _player()
				_warn_x = p.global_position.x if p else global_position.x
				_state = WARN
				_timer = 0.6
		WARN:
			position.x = move_toward(position.x, _warn_x, 200.0 * delta)
			if _timer <= 0.0:
				_state = SURFACE
				_timer = maxf(1.4, 2.4 - (4 - hp) * 0.3)
				_shape.disabled = false
				position.y = _ground_y
				Audio.play("stomp", 0.12)
				Burst.spawn(get_parent(), Vector2(position.x, _ground_y), tint, 16, 120.0, 0.5)
				# Erupting debris.
				for a: float in [-0.4, 0.0, 0.4]:
					var b := EnemyProjectile.new()
					b.dir = Vector2(sin(a), -1.0).normalized()
					b.tint = tint.lightened(0.1)
					b.speed = 100.0
					b.position = global_position + Vector2(0, -8)
					get_parent().add_child(b)
	queue_redraw()

func _throw() -> void:
	var p := _player()
	var d := -1.0 if (p and p.global_position.x < global_position.x) else 1.0
	for a: float in [-0.15, 0.25]:
		var b := EnemyProjectile.new()
		b.dir = Vector2(d, -0.5).rotated(a)
		b.tint = tint
		b.speed = 90.0
		b.position = global_position + Vector2(d * 6.0, -6.0)
		get_parent().add_child(b)
	Audio.play("dash", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player) or not _surfaced():
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -4.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if _surfaced():
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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 34, 150.0, 0.75, 3.2)
	Audio.play("complete")
	Game.toast.emit("★ Tunnel King buried! ★")
	queue_redraw()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	if _state == WARN:
		# Telegraph mound where he'll erupt.
		var w := 8.0 + sin(_t * 30.0) * 2.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(-w, _ground_y - position.y), Vector2(w, _ground_y - position.y),
			Vector2(0, _ground_y - position.y - 6.0)]), tint.darkened(0.25))
		return
	if _state == BURROW:
		return
	var flashing := _hitflash > 0.0 and int(_hitflash * 30.0) % 2 == 0
	var body := Color(1, 1, 1) if flashing else tint
	draw_circle(Vector2(0, 3), 11.0, body.darkened(0.15))
	draw_circle(Vector2(0, 0), 10.0, body)
	# Digging claws.
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 2), Vector2(-6, -2), Vector2(-5, 6)]), body.lightened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(10, 2), Vector2(6, -2), Vector2(5, 6)]), body.lightened(0.15))
	# Snout + goggles.
	draw_circle(Vector2(0, 2), 3.0, Color(0.95, 0.7, 0.6))
	draw_circle(Vector2(-4, -3), 2.4, Color(0.2, 0.25, 0.3))
	draw_circle(Vector2(4, -3), 2.4, Color(0.2, 0.25, 0.3))
	draw_circle(Vector2(-4, -3), 1.0, Color(1, 1, 0.7))
	draw_circle(Vector2(4, -3), 1.0, Color(1, 1, 0.7))
	for i in hp:
		draw_circle(Vector2(-9.0 + i * 6.0, -14.0), 1.7, tint.lightened(0.3))
