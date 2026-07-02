class_name PhantomKing
extends Area2D
## Haunted Mansion finale boss. A spectre that phases between SOLID (opaque, vulnerable,
## attacks) and ETHEREAL (translucent, invulnerable, drifts). It blinks to a new spot
## when it re-solidifies, fires a spectral spread, and sometimes looses a Ghost. Hit it
## only during solid windows (stomp or shoot). 5 hits. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.6, 0.95, 0.85)
var boss_name := "Phantom King"    # themed per world (this blink pattern is reused)
var hp := 5

var _origin := Vector2.ZERO
var _t := 0.0
var _invuln := 0.0
var _hitflash := 0.0
var _dead := false
var _solid := true
var _state_t := 0.0
var _atk := 0.0
var _range := 90.0

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
	_state_t = 2.0
	_atk = 1.2
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	# Gentle bob; drifts more while ethereal.
	var bob := sin(_t * 2.0) * 4.0
	if _solid:
		position.y = _origin.y + bob
	else:
		position += Vector2(sin(_t * 1.3) * 22.0, cos(_t * 1.7) * 16.0) * delta
	_state_t -= delta
	if _state_t <= 0.0:
		_solid = not _solid
		_state_t = (2.2 if _solid else 1.5) - (5 - hp) * 0.1
		if _solid:
			_blink()
	if _solid:
		_atk -= delta
		if _atk <= 0.0:
			_atk = maxf(0.9, 1.6 - (5 - hp) * 0.12)
			_attack()
	queue_redraw()

func _blink() -> void:
	# Teleport to a fresh spot around the arena, then attack from there.
	position = _origin + Vector2(randf_range(-_range, _range), randf_range(-14.0, 20.0))
	Burst.spawn(get_parent(), global_position, tint, 12, 90.0, 0.4)
	Audio.play("dash", 0.1)

func _attack() -> void:
	var p := _player()
	var base := Vector2.DOWN
	if p:
		base = (p.global_position - global_position).normalized()
	for a: float in [-0.35, 0.0, 0.35]:
		var b := EnemyProjectile.new()
		b.dir = base.rotated(a)
		b.tint = tint
		b.speed = 92.0
		b.position = global_position
		get_parent().add_child(b)
	if hp <= 3 and randf() < 0.4:
		var g := Ghost.new()
		g.tint = tint.darkened(0.1)
		g.position = global_position + Vector2(0, 6)
		get_parent().add_child(g)
	Audio.play("dash", 0.1)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	# While ethereal it can't hurt you and you can't hit it — you pass through.
	if not _solid:
		return
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -6.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		_damage()
	else:
		p.die()

func hit() -> void:
	if _solid:
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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 36, 160.0, 0.8, 3.4)
	Audio.play("complete")
	Game.toast.emit("★ %s banished! ★" % boss_name)
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
	var alpha := 1.0 if _solid else 0.35
	var body := Color(1, 1, 1, alpha) if flashing else Color(tint.r, tint.g, tint.b, alpha)
	# Wavy spectral robe.
	var pts := PackedVector2Array()
	pts.append(Vector2(-12, -6))
	pts.append(Vector2(12, -6))
	for k in range(5, -1, -1):
		var x := -12.0 + k * 4.8
		pts.append(Vector2(x, 14 + sin(_t * 6.0 + k) * 2.0))
	draw_colored_polygon(pts, Color(body.r, body.g, body.b, alpha * 0.85))
	# Head/hood.
	draw_circle(Vector2(0, -6), 10.0, Color(body.r, body.g, body.b, alpha))
	# Crown.
	for k in 3:
		var cx := -6.0 + k * 6.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 2, -13), Vector2(cx + 2, -13), Vector2(cx, -20)]), Color(1, 0.85, 0.3, alpha))
	# Hollow eyes.
	draw_circle(Vector2(-4, -6), 2.0, Color(0.9, 0.2, 0.3, alpha))
	draw_circle(Vector2(4, -6), 2.0, Color(0.9, 0.2, 0.3, alpha))
	if _solid:
		for i in hp:
			draw_circle(Vector2(-12.0 + i * 6.0, -23.0), 1.7, tint.lightened(0.3))
