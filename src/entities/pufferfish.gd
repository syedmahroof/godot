class_name Pufferfish
extends Area2D
## Drifts along a lazy path and periodically inflates spikes. While deflated it's a
## normal stompable enemy; while inflated ANY contact is fatal and a stomp just
## bounces you (spiky all over). A shot kills it in either state.

const STOMP_BOUNCE := 220.0

var tint := Color(0.5, 0.9, 1.0)
var rx := 20.0
var ry := 8.0
var speed := 1.0

var _origin := Vector2.ZERO
var _t := 0.0
var _puff := 0.0
var _cycle := 0.0
var _inflated := false
var _dead := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	_origin = position
	_t = randf() * TAU
	_cycle = randf() * 3.5
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta * speed
	position = _origin + Vector2(cos(_t) * rx, sin(_t * 1.3) * ry)
	_cycle += delta
	_inflated = fmod(_cycle, 3.5) > 2.0     # ~2s calm, ~1.5s spiky
	_puff = move_toward(_puff, 1.0 if _inflated else 0.0, delta * 4.0)
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	if _inflated:
		# Spiky all over — no safe way to touch it.
		p.die()
		return
	if _stomping(p):
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

func _stomping(p: Player) -> bool:
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -1.0
	return coming_down and above

func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.1)
	Burst.spawn(get_parent(), global_position, tint, 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.04).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var r := 5.5 + _puff * 2.5
	draw_circle(Vector2(0, 5), 5.0, Color(0, 0, 0, 0.12))
	draw_circle(Vector2.ZERO, r, tint)
	draw_circle(Vector2(0, 1), r, tint.darkened(0.15))
	if _puff > 0.05:
		for k in 8:
			var a := k * TAU / 8.0
			var d := Vector2(cos(a), sin(a))
			draw_colored_polygon(PackedVector2Array([
				d.rotated(-0.25) * r, d.rotated(0.25) * r, d * (r + 3.0 * _puff)]), Color(0.9, 0.95, 1.0))
	draw_circle(Vector2(-2, -1), 1.3, Color.WHITE)
	draw_circle(Vector2(2, -1), 1.3, Color.WHITE)
	draw_circle(Vector2(-2, -1), 0.7, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(2, -1), 0.7, Color(0.1, 0.1, 0.15))
