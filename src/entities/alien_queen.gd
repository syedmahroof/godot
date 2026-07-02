class_name AlienQueen
extends Area2D
## Space Station finale mini-boss. Hovers across the arena and cycles three attacks
## that escalate as her health drops:
##   0) radial ring burst of shots
##   1) summon a hovering Drone beneath her
##   2) aimed 3-shot volley at the player
## 5 hits (stomp from above or shoot); sides are lethal. Locks the exit (group
## "boss") until she falls. Tinted alien-green/violet.

const STOMP_BOUNCE := 250.0

var tint := Color(0.6, 1.0, 0.7)
var boss_name := "Alien Queen"     # themed per world (this summon/radial pattern is reused)
var hp := 5

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
	c.radius = 14.0
	s.shape = c
	add_child(s)
	_origin = position
	_atk = 1.6
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_invuln = maxf(0.0, _invuln - delta)
	_hitflash = maxf(0.0, _hitflash - delta)
	# Wider, faster sweep as she takes damage.
	var reach := 80.0 + (5 - hp) * 6.0
	position = _origin + Vector2(sin(_t * 0.8) * reach, absf(sin(_t * 1.6)) * 22.0)
	_atk -= delta
	if _atk <= 0.0:
		_atk = maxf(1.1, 2.4 - (5 - hp) * 0.25)
		_do_attack()
		_phase = (_phase + 1) % 3
	queue_redraw()

func _do_attack() -> void:
	match _phase:
		0:
			# Radial ring.
			var n := 8
			for i in n:
				var ang := TAU * i / n
				var b := EnemyProjectile.new()
				b.dir = Vector2(cos(ang), sin(ang))
				b.tint = tint
				b.speed = 74.0
				b.position = global_position
				get_parent().add_child(b)
			Audio.play("dash", 0.12)
		1:
			# Summon a drone below her.
			var d := Drone.new()
			d.tint = tint.lightened(0.1)
			d.position = global_position + Vector2(0, 22)
			get_parent().add_child(d)
			Audio.play("star", 0.1)
		2:
			# Aimed volley at the player.
			var p := _player()
			var dir := Vector2.DOWN
			if p:
				dir = (p.global_position - global_position).normalized()
			for a: float in [-0.25, 0.0, 0.25]:
				var b := EnemyProjectile.new()
				b.dir = dir.rotated(a)
				b.tint = tint
				b.speed = 100.0
				b.position = global_position + Vector2(0, 8)
				get_parent().add_child(b)
			Audio.play("dash", 0.12)

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
	Burst.spawn(get_parent(), global_position, tint.lightened(0.3), 34, 160.0, 0.75, 3.2)
	Audio.play("complete")
	Game.toast.emit("★ %s destroyed! ★" % boss_name)
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
	draw_circle(Vector2(0, 13), 14.0, Color(0, 0, 0, 0.15))
	# Bulbous head + carapace.
	draw_circle(Vector2.ZERO, 14.0, body.darkened(0.15))
	draw_circle(Vector2(0, 3), 14.0, body.darkened(0.32))
	draw_circle(Vector2(0, -3), 9.0, body.lightened(0.1))
	# Twin antennae.
	draw_line(Vector2(-5, -10), Vector2(-9, -18), body.lightened(0.2), 1.6)
	draw_line(Vector2(5, -10), Vector2(9, -18), body.lightened(0.2), 1.6)
	draw_circle(Vector2(-9, -18), 1.6, Color(1, 0.9, 0.4))
	draw_circle(Vector2(9, -18), 1.6, Color(1, 0.9, 0.4))
	# Compound eyes.
	draw_circle(Vector2(-5, -3), 2.6, Color(0.1, 0.05, 0.12))
	draw_circle(Vector2(5, -3), 2.6, Color(0.1, 0.05, 0.12))
	draw_circle(Vector2(-5, -4), 0.9, Color(1, 0.5, 0.6))
	draw_circle(Vector2(5, -4), 0.9, Color(1, 0.5, 0.6))
	# HP pips.
	for i in hp:
		draw_circle(Vector2(-12.0 + i * 6.0, 19.0), 1.7, Color(0.6, 1.0, 0.6))
