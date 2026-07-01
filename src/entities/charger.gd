class_name Charger
extends Area2D
## Sits idle until the player enters its lane, then dashes fast in that direction.
## Stomp from above to pop it; touching its side while it charges is fatal. It
## adds a "reactive" threat class the patrolling blob doesn't have.

const STOMP_BOUNCE := 250.0

var tint := Color(1.0, 0.55, 0.30)

var _origin := Vector2.ZERO
var _state := 0           # 0 idle, 1 charging, 2 recover
var _dir := 1.0
var _travel := 0.0
var _timer := 0.0
var _dead := false
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	var s := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 6.0
	c.height = 14.0
	s.shape = c
	add_child(s)
	_origin = position
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	if _dead:
		return
	match _state:
		0:
			var p := _player()
			if p:
				var dy: float = absf(p.global_position.y - global_position.y)
				var dx: float = p.global_position.x - global_position.x
				if dy < 12.0 and absf(dx) < 100.0:
					_dir = signf(dx)
					if _dir == 0.0:
						_dir = 1.0
					_state = 1
					_travel = 0.0
					Audio.play("dash", 0.12)
		1:
			var step := 150.0 * delta
			position.x += _dir * step
			_travel += step
			if _travel > 110.0:
				_state = 2
				_timer = 0.9
		2:
			_timer -= delta
			if _timer <= 0.0:
				_origin = position
				_state = 0
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
	Burst.spawn(get_parent(), global_position, tint, 12, 100.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2.ZERO, 7.5, tint)
	draw_circle(Vector2(0, 1), 7.5, tint.darkened(0.15))
	var f := _dir
	# A forward horn to read the charge direction.
	draw_colored_polygon(PackedVector2Array([Vector2(f * 5, -3), Vector2(f * 11, -6), Vector2(f * 6, 0)]), Color(0.95, 0.9, 0.85))
	draw_circle(Vector2(f * 2 - 1, -1), 1.5, Color.WHITE)
	draw_circle(Vector2(f * 2 + 3, -1), 1.5, Color.WHITE)
	draw_circle(Vector2(f * 2 - 1 + f, -1), 0.9, Color(0.1, 0.1, 0.15))
	draw_circle(Vector2(f * 2 + 3 + f, -1), 0.9, Color(0.1, 0.1, 0.15))
	if _state == 1:
		draw_line(Vector2(-f * 8, -2), Vector2(-f * 13, -2), Color(1, 1, 1, 0.4), 1.0)
		draw_line(Vector2(-f * 8, 2), Vector2(-f * 13, 2), Color(1, 1, 1, 0.4), 1.0)
