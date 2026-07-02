class_name CursedDoll
extends Area2D
## Haunted Mansion. Sits perfectly still like a harmless toy — until the player comes
## close, when it wakes and hops after them in little lunges. Stomp it while it's mid-
## rest between hops; a side touch is fatal either way once woken. Dormant = harmless.

const STOMP_BOUNCE := 210.0

var tint := Color(0.85, 0.5, 0.6)
var wake_range := 46.0
var _awake := false
var _hop_cd := 0.0
var _vy := 0.0
var _on_ground := true
var _base_y := 0.0
var _dead := false
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 5.0
	c.height = 12.0
	s.shape = c
	add_child(s)
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	if not _awake:
		if p and global_position.distance_to(p.global_position) < wake_range:
			_awake = true
			_hop_cd = 0.3
			Audio.play("dash", 0.06)
		queue_redraw()
		return
	# Simple hop arc handled manually (no physics body).
	_hop_cd -= delta
	if _on_ground and _hop_cd <= 0.0:
		_vy = -150.0
		_on_ground = false
		if p:
			position.x += signf(p.global_position.x - global_position.x) * 3.0
	if not _on_ground:
		_vy += 520.0 * delta
		position.y += _vy * delta
		if p:
			position.x = move_toward(position.x, p.global_position.x, 60.0 * delta)
		if position.y >= _base_y:
			position.y = _base_y
			_vy = 0.0
			_on_ground = true
			_hop_cd = 0.5
	queue_redraw()

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
	Burst.spawn(get_parent(), global_position, tint, 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var body := tint if _awake else tint.darkened(0.25)
	# Dress.
	draw_colored_polygon(PackedVector2Array([Vector2(-5, 6), Vector2(5, 6), Vector2(2, -1), Vector2(-2, -1)]), body.darkened(0.1))
	# Head.
	draw_circle(Vector2(0, -4), 4.5, Color(0.95, 0.88, 0.82))
	# Eyes: dark dots, glowing red when awake.
	var ec := Color(1, 0.2, 0.25) if _awake else Color(0.2, 0.15, 0.18)
	draw_circle(Vector2(-1.7, -4.5), 1.1, ec)
	draw_circle(Vector2(1.7, -4.5), 1.1, ec)
	# Crack.
	draw_line(Vector2(0, -7), Vector2(1, -3), Color(0.4, 0.3, 0.3), 0.8)
