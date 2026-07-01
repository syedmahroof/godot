class_name Splitter
extends Area2D
## A slime that, when stomped or shot, splits into two smaller, faster slimes
## instead of dying. The minis die normally. Escalates a fight the way a single
## blob never could. `size_level` 0 = big, 1 = small.

const STOMP_BOUNCE := 240.0

var tint := Color(0.6, 0.95, 0.55)
var size_level := 0
var span := 30.0
var speed := 1.4

var _origin := Vector2.ZERO
var _t := 0.0
var _dead := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 6.0 if size_level == 0 else 4.0
	c.height = 14.0 if size_level == 0 else 9.0
	s.shape = c
	add_child(s)
	_origin = position
	_t = randf() * TAU
	if size_level == 1:
		speed = 2.4
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta * speed
	position.x = _origin.x + sin(_t) * span
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
	Burst.spawn(get_parent(), global_position, tint, 10, 90.0, 0.4)
	if size_level == 0:
		for s: float in [-1.0, 1.0]:
			var mini := Splitter.new()
			mini.size_level = 1
			mini.span = 16.0
			mini.tint = tint
			mini.position = position + Vector2(s * 6.0, 0.0)
			get_parent().add_child(mini)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _draw() -> void:
	if _dead:
		return
	var r := 7.0 if size_level == 0 else 4.5
	draw_circle(Vector2(0, r * 0.85), r, Color(0, 0, 0, 0.15))
	draw_circle(Vector2.ZERO, r, tint)
	draw_circle(Vector2(0, 1), r, tint.darkened(0.15))
	draw_circle(Vector2(-r * 0.3, -1), r * 0.22, Color.WHITE)
	draw_circle(Vector2(r * 0.3, -1), r * 0.22, Color.WHITE)
	draw_circle(Vector2(-r * 0.3, -1), r * 0.12, Color(0.1, 0.15, 0.1))
	draw_circle(Vector2(r * 0.3, -1), r * 0.12, Color(0.1, 0.15, 0.1))
