class_name Snowman
extends Area2D
## Frozen Peaks. Stands idle (stompable), then curls into a giant snowball and rolls
## along the ground toward the player — lethal to touch while rolling — before packing
## back into a snowman. Whack it during the idle beat; dodge it while it rolls.

const STOMP_BOUNCE := 220.0

var tint := Color(0.92, 0.96, 1.0)
var roll_speed := 96.0

enum { IDLE, ROLL }
var _state := IDLE
var _timer := 0.0
var _dir := 1.0
var _spin := 0.0
var _dead := false
var _shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	_shape = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	_shape.shape = c
	add_child(_shape)
	_timer = randf_range(1.6, 2.4)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_timer -= delta
	match _state:
		IDLE:
			if _timer <= 0.0:
				var p := _player()
				_dir = -1.0 if (p and p.global_position.x < global_position.x) else 1.0
				_state = ROLL
				_timer = 1.8
				Audio.play("dash", 0.08)
		ROLL:
			position.x += _dir * roll_speed * delta
			_spin += _dir * delta * 10.0
			if _timer <= 0.0:
				_state = IDLE
				_timer = randf_range(1.6, 2.6)
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	# Only vulnerable to a stomp while standing idle; the rolling ball flattens you.
	if _state == IDLE and coming_down and above:
		p.bounce(STOMP_BOUNCE)
		hit()
	else:
		p.die()

func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 14, 100.0, 0.5)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	if _state == ROLL:
		draw_circle(Vector2(0, 6), 8.0, Color(0, 0, 0, 0.15))
		draw_circle(Vector2.ZERO, 8.0, tint)
		draw_circle(Vector2.ZERO, 8.0, tint.darkened(0.08))
		# spin marks
		for k in 3:
			var a := _spin + k * TAU / 3.0
			draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * 6.0, Color(0.7, 0.8, 0.9, 0.6), 1.2)
		return
	# Snowman: two stacked balls.
	draw_circle(Vector2(0, 8), 7.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2(0, 5), 6.5, tint)
	draw_circle(Vector2(0, -3), 5.0, tint)
	draw_circle(Vector2(-1.6, -4), 0.9, Color(0.15, 0.15, 0.2))
	draw_circle(Vector2(1.6, -4), 0.9, Color(0.15, 0.15, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -2), Vector2(4, -1), Vector2(0, 0)]), Color(1.0, 0.6, 0.2))
