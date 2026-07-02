class_name LivingPlant
extends Area2D
## Whispering Woods finale boss — the Verdant Horror. A rooted carnivorous plant:
## its bulb head sways side to side and bobs (stomp it when it dips) while it spits
## arcing spore shots and occasionally sprouts a crawling seedling. 4 hits. Rooted,
## so it never chases — but its head is the only safe place to land. Locks the exit.

const STOMP_BOUNCE := 250.0

var tint := Color(0.4, 0.8, 0.35)
var hp := 4
var stem_len := 34.0        # drawn downward from the head to the ground

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
	c.radius = 11.0
	s.shape = c
	add_child(s)
	_origin = position
	_atk = 1.8
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	var sway := 26.0 + (4 - hp) * 3.0
	position = _origin + Vector2(sin(_t * 1.1) * sway, sin(_t * 2.0) * 7.0)
	_atk -= delta
	if _atk <= 0.0:
		_atk = maxf(1.2, 2.2 - (4 - hp) * 0.2)
		_do_attack()
		_phase = (_phase + 1) % 2
	queue_redraw()

func _do_attack() -> void:
	if _phase == 0:
		# Arc of spores fanning upward that fall back across the arena.
		for a: float in [-0.8, -0.4, 0.0, 0.4, 0.8]:
			var b := EnemyProjectile.new()
			b.dir = Vector2(sin(a), -0.9).normalized()
			b.tint = tint.lightened(0.15)
			b.speed = 88.0
			b.position = global_position + Vector2(0, -6)
			get_parent().add_child(b)
		Audio.play("dash", 0.1)
	else:
		# Sprout a seedling that patrols the arena floor.
		var e := Enemy.new()
		e.position = global_position + Vector2(0, stem_len - 4)
		get_parent().add_child(e)
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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 34, 150.0, 0.75, 3.2)
	Audio.play("complete")
	Game.toast.emit("★ Verdant Horror felled! ★")
	queue_redraw()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	var flashing := _hitflash > 0.0 and int(_hitflash * 30.0) % 2 == 0
	var body := Color(1, 1, 1) if flashing else tint
	# Stem down to the ground (curves with the sway).
	var base := Vector2(-sin(_t * 1.1) * 10.0, stem_len)
	draw_line(Vector2(0, 4), base, tint.darkened(0.3), 4.0)
	draw_line(Vector2(0, 4), base, tint.darkened(0.15), 2.0)
	# Leaves along the stem.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 16), Vector2(-11, 12), Vector2(-2, 22)]), tint.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 20), Vector2(11, 16), Vector2(2, 26)]), tint.darkened(0.1))
	# Bulb head (the maw).
	draw_circle(Vector2.ZERO, 11.0, body.darkened(0.15))
	draw_circle(Vector2(0, 1), 11.0, body.darkened(0.3))
	# Jagged mouth.
	for k in 5:
		var cx := -7.0 + k * 3.5
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 1.6, -1), Vector2(cx + 1.6, -1), Vector2(cx, 5)]), Color(0.95, 0.95, 0.9))
	# Eyes.
	draw_circle(Vector2(-4, -5), 1.8, Color(1, 0.9, 0.3))
	draw_circle(Vector2(4, -5), 1.8, Color(1, 0.9, 0.3))
	for i in hp:
		draw_circle(Vector2(-9.0 + i * 6.0, -15.0), 1.7, tint.lightened(0.3))
