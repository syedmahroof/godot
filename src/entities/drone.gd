class_name Drone
extends Area2D
## Space Station. A hovering alien drone that bobs in place and slowly drifts to
## line up with the player's column, then holds — a patient area-denial floater.
## Lethal on contact; stomp from above to pop it.

const STOMP_BOUNCE := 240.0

var tint := Color(0.55, 1.0, 0.75)
var range_x := 40.0        # how far it will drift to track the player
var _origin := Vector2.ZERO
var _t := 0.0
var _dead := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	add_to_group("enemy")
	_origin = position
	_t = randf() * TAU
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	var tx := _origin.x
	if p:
		tx = clampf(p.global_position.x, _origin.x - range_x, _origin.x + range_x)
	position.x = move_toward(position.x, tx, 34.0 * delta)
	position.y = _origin.y + sin(_t * 2.2) * 5.0
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
	var g := 0.6 + 0.4 * sin(_t * 5.0)
	draw_circle(Vector2(0, 7), 6.0, Color(0, 0, 0, 0.15))
	draw_circle(Vector2(0, 0), 6.5, tint.darkened(0.3))
	draw_circle(Vector2(0, -1), 4.5, tint)
	draw_circle(Vector2(0, -1), 2.2, Color(1, 1, 1, g))       # single scanning eye
	# rotor blur
	draw_line(Vector2(-8, -5), Vector2(8, -5), Color(1, 1, 1, 0.25 * g), 1.0)
