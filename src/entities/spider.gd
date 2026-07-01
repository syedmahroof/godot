class_name Spider
extends Area2D
## A ceiling spider that hangs and drops down rapidly when the player walks under it,
## then climbs back up slowly. Drawn with a silk thread. Can be stomped or shot.

const STOMP_BOUNCE := 220.0

var tint := Color(0.9, 0.2, 0.4)

var _origin := Vector2.ZERO
var _state := 0 # 0: hanging, 1: dropping, 2: waiting at bottom, 3: climbing back up
var _vel := 0.0
var _wait := 0.0
var _dead := false
var _blink := 0.0
var _drop_height := 100.0 # how far down it drops

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
	_blink += delta
	if _dead:
		return
	
	match _state:
		0: # hanging, check player presence
			var p := _player()
			if p and absf(p.global_position.x - global_position.x) < 20.0 \
					and p.global_position.y > global_position.y \
					and p.global_position.y - global_position.y < _drop_height + 30.0:
				_state = 1
				_vel = 0.0
				Audio.play("stomp", 0.05) # warning sound
		1: # dropping rapidly
			_vel += 900.0 * delta
			position.y += _vel * delta
			if position.y - _origin.y >= _drop_height:
				position.y = _origin.y + _drop_height
				_state = 2
				_wait = 0.8
		2: # waiting at bottom
			_wait -= delta
			if _wait <= 0.0:
				_state = 3
		3: # climbing up slowly
			position.y = move_toward(position.y, _origin.y, delta * 40.0)
			if position.y <= _origin.y:
				position.y = _origin.y
				_state = 0
				
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if _dead or not (b is Player):
		return
	var p := b as Player
	# Stomp: player above the spider and descending.
	var coming_down := p.velocity.y * p.gravity_sign > 20.0
	var above := (p.global_position.y - global_position.y) * p.gravity_sign < -2.0
	if coming_down and above:
		_pop(p)
	else:
		p.die()

func _pop(p: Player) -> void:
	p.bounce(STOMP_BOUNCE)
	hit()

func hit() -> void:
	if _dead:
		return
	_dead = true
	Audio.play("stomp", 0.08)
	Burst.spawn(get_parent(), global_position, tint, 12, 80.0, 0.4)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	
	# Draw web thread from origin (rel to self)
	var thread_start := _origin - position
	draw_line(thread_start, Vector2.ZERO, Color(0.9, 0.9, 0.9, 0.7), 1.0)
	
	# Draw spider body
	# Legs
	var w := sin(_blink * 14.0) * 2.0
	# Left legs
	draw_line(Vector2.ZERO, Vector2(-9, -4 + w), Color.BLACK, 1.2)
	draw_line(Vector2.ZERO, Vector2(-10, 0 + w), Color.BLACK, 1.2)
	draw_line(Vector2.ZERO, Vector2(-8, 4 + w), Color.BLACK, 1.2)
	# Right legs
	draw_line(Vector2.ZERO, Vector2(9, -4 - w), Color.BLACK, 1.2)
	draw_line(Vector2.ZERO, Vector2(10, 0 - w), Color.BLACK, 1.2)
	draw_line(Vector2.ZERO, Vector2(8, 4 - w), Color.BLACK, 1.2)
	
	# Main body orb
	draw_circle(Vector2(0, 0), 6.5, Color.BLACK)
	draw_circle(Vector2(0, 0), 5.0, tint)
	draw_circle(Vector2(0, -1), 3.0, tint.lightened(0.2))
	
	# Head
	draw_circle(Vector2(0, 4), 3.5, Color.BLACK)
	
	# Angry small eyes
	draw_circle(Vector2(-1.2, 4.5), 0.7, Color.YELLOW)
	draw_circle(Vector2(1.2, 4.5), 0.7, Color.YELLOW)
