class_name Ghost
extends Area2D
## Slowly chases the player and drifts through walls. Alternates between a SOLID
## phase (opaque, deadly, and vulnerable to stomp/shots) and a PHASED phase
## (translucent, harmless, and untouchable) — so it's a timing dance, not an
## unavoidable hit.

var tint := Color(0.72, 0.96, 0.76)
var speed := 22.0

var _solid := true
var _timer := 0.0
var _dead := false
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	_timer = randf_range(1.2, 2.0)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	_timer -= delta
	if _timer <= 0.0:
		_solid = not _solid
		_timer = 1.5
	var p := _player()
	if p:
		position += (p.global_position - global_position).normalized() * speed * delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not _solid or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -1.0
	if coming_down and above:
		p.bounce(220.0)
		hit()
	else:
		p.die()

func hit() -> void:
	if _dead or not _solid:   # only killable while solid
		return
	_dead = true
	Audio.play("stomp", 0.1)
	Burst.spawn(get_parent(), global_position, tint, 12, 90.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.04).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var a := 0.92 if _solid else 0.28
	var col := Color(tint.r, tint.g, tint.b, a)
	draw_circle(Vector2(0, -1), 6.0, col)
	draw_rect(Rect2(-6, -1, 12, 6), col)
	for k in 3:
		draw_circle(Vector2(-4.0 + k * 4.0, 5.0), 2.0, col)
	draw_circle(Vector2(-2, -1), 1.2, Color(0.1, 0.1, 0.2, a))
	draw_circle(Vector2(2, -1), 1.2, Color(0.1, 0.1, 0.2, a))
