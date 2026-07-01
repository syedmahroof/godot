class_name DiveBomber
extends Area2D
## Hovers overhead, then swoops down at the player's position and pulls back up.
## Stomp from above or shoot to pop; a side/underside hit while it dives is fatal.

const STOMP_BOUNCE := 240.0

var tint := Color(0.72, 0.86, 1.0)

var _origin := Vector2.ZERO
var _state := 0           # 0 hover, 1 dive, 2 return
var _t := 0.0
var _target := Vector2.ZERO
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
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	match _state:
		0:
			position = _origin + Vector2(sin(_t * 1.2) * 10.0, sin(_t * 2.0) * 2.0)
			var p := _player()
			if p and absf(p.global_position.x - global_position.x) < 26.0 \
					and p.global_position.y > global_position.y:
				_state = 1
				_target = Vector2(p.global_position.x, _origin.y + 70.0)
				Audio.play("dash", 0.08)
		1:
			position = position.move_toward(_target, 220.0 * delta)
			if position.distance_to(_target) < 3.0:
				_state = 2
		2:
			position = position.move_toward(_origin, 70.0 * delta)
			if position.distance_to(_origin) < 2.0:
				_state = 0
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -1.0
	if coming_down and above:
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

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
	var col := tint if _state != 1 else Color(1.0, 0.5, 0.4)   # reddens while diving
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -1), Vector2(-11, -5), Vector2(-4, 3)]), col.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(3, -1), Vector2(11, -5), Vector2(4, 3)]), col.darkened(0.1))
	draw_circle(Vector2(0, 5), 5.0, Color(0, 0, 0, 0.12))
	draw_circle(Vector2.ZERO, 5.5, col)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 4), Vector2(2, 4), Vector2(0, 9)]), Color(1, 0.8, 0.3))
	draw_circle(Vector2(-2, -1), 1.3, Color.WHITE)
	draw_circle(Vector2(2, -1), 1.3, Color.WHITE)
	draw_circle(Vector2(-2, -1), 0.7, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(2, -1), 0.7, Color(0.1, 0.1, 0.15))
