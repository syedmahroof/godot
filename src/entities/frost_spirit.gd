class_name FrostSpirit
extends Area2D
## Frozen Peaks. A drifting frost wraith that slowly homes toward the player, bobbing,
## and every so often exhales a slow frost shot at them. Lethal on contact; stomp from
## above to dispel it.

const STOMP_BOUNCE := 240.0

var tint := Color(0.7, 0.92, 1.0)
var _t := 0.0
var _cd := 0.0
var _dead := false
var _drift := Vector2.ZERO

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	_cd = randf_range(1.2, 2.4)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	if p:
		var to := (p.global_position - global_position)
		_drift = _drift.move_toward(to.normalized() * 26.0, 40.0 * delta)
	position += _drift * delta
	position.y += sin(_t * 3.0) * 0.3
	_cd -= delta
	if _cd <= 0.0:
		_cd = 2.2
		_breathe(p)
	queue_redraw()

func _breathe(p: Player) -> void:
	var dir := Vector2.DOWN
	if p:
		dir = (p.global_position - global_position).normalized()
	var b := EnemyProjectile.new()
	b.dir = dir
	b.tint = Color(0.6, 0.9, 1.0)
	b.speed = 78.0
	b.position = global_position
	get_parent().add_child(b)
	Audio.play("dash", 0.08)

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 12, 90.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var a := 0.7 + 0.3 * sin(_t * 4.0)
	# Wispy tail.
	draw_circle(Vector2(0, 5), 5.0, Color(tint.r, tint.g, tint.b, 0.25 * a))
	draw_circle(Vector2(0, 2), 6.0, Color(tint.r, tint.g, tint.b, 0.5 * a))
	draw_circle(Vector2(0, -1), 6.5, Color(tint.r, tint.g, tint.b, 0.85))
	# Hollow eyes.
	draw_circle(Vector2(-2.2, -2), 1.5, Color(0.15, 0.35, 0.65))
	draw_circle(Vector2(2.2, -2), 1.5, Color(0.15, 0.35, 0.65))
