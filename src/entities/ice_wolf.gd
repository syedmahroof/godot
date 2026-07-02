class_name IceWolf
extends Area2D
## Frozen Peaks. A frost wolf that paces its ledge, then lunges in a fast slide when
## the player lines up in front of it on roughly the same level. Stomp from above to
## fell it; the side of a lunge is deadly. Recovers briefly after each pounce.

const STOMP_BOUNCE := 230.0

var tint := Color(0.7, 0.85, 1.0)
var span := 30.0
var patrol_speed := 34.0
var lunge_speed := 190.0

enum { PATROL, LUNGE, RECOVER }
var _state := PATROL
var _origin := Vector2.ZERO
var _face := 1.0
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
	c.height = 12.0
	s.shape = c
	add_child(s)
	_origin = position
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	match _state:
		PATROL:
			position.x += _face * patrol_speed * delta
			if position.x > _origin.x + span:
				_face = -1.0
			elif position.x < _origin.x - span:
				_face = 1.0
			if p and absf(p.global_position.y - global_position.y) < 12.0:
				var dx := p.global_position.x - global_position.x
				if signf(dx) == _face and absf(dx) < 90.0:
					_state = LUNGE
					_timer = 0.55
					Audio.play("dash", 0.1)
		LUNGE:
			position.x += _face * lunge_speed * delta
			_timer -= delta
			if _timer <= 0.0:
				_state = RECOVER
				_timer = 0.6
		RECOVER:
			_timer -= delta
			if _timer <= 0.0:
				_state = PATROL
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
	var crouch := _state == LUNGE
	var body := tint if _state != RECOVER else tint.darkened(0.15)
	draw_circle(Vector2(0, 6), 7.0, Color(0, 0, 0, 0.15))
	# Body.
	draw_rect(Rect2(-8, -3, 16, 9), body.darkened(0.2))
	# Head lunging forward.
	draw_circle(Vector2(_face * 7.0, -1 - (2 if crouch else 0)), 5.0, body)
	# Ears.
	draw_colored_polygon(PackedVector2Array([Vector2(_face * 5.0, -5), Vector2(_face * 8.0, -5), Vector2(_face * 6.5, -10)]), body.lightened(0.1))
	# Eye + snout.
	draw_circle(Vector2(_face * 8.0, -2), 1.3, Color(0.2, 0.5, 0.95))
	# Tail.
	draw_line(Vector2(-8, 0), Vector2(-8 - _face * 4.0, -3), body.darkened(0.1), 2.0)
