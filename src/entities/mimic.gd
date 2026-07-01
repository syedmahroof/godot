class_name Mimic
extends Area2D
## Disguised as a shiny coin — until you get close, when it bares teeth and bites.
## Touching it is fatal, but a well-timed stomp from above pops it (and a bullet
## works too). Perfect cruelty for the troll worlds.

const STOMP_BOUNCE := 230.0

var _alert := 0.0
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
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	var p := _player()
	if p and global_position.distance_to(p.global_position) < 22.0:
		_alert = minf(1.0, _alert + delta * 4.0)
	else:
		_alert = maxf(0.0, _alert - delta * 2.0)
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
	Burst.spawn(get_parent(), global_position, Color(1.0, 0.84, 0.25), 12, 95.0, 0.45)
	queue_redraw()
	await get_tree().create_timer(0.05).timeout
	queue_free()

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	if _dead:
		return
	var gold := Color(1.0, 0.84, 0.25)
	draw_circle(Vector2.ZERO, 5.5, gold.darkened(0.1))
	draw_circle(Vector2.ZERO, 3.4, gold.lightened(0.25))
	if _alert > 0.05:
		var a := _alert
		draw_colored_polygon(PackedVector2Array([
			Vector2(-4, 1), Vector2(4, 1), Vector2(3, 1 + 3 * a), Vector2(-3, 1 + 3 * a)]), Color(0.2, 0.05, 0.05, a))
		for k in 4:
			var tx := -3.0 + k * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(tx - 0.8, 1), Vector2(tx + 0.8, 1), Vector2(tx, 1 + 2.5 * a)]), Color(1, 1, 1, a))
		draw_circle(Vector2(-2, -2), 1.2, Color(0.9, 0.1, 0.1, a))
		draw_circle(Vector2(2, -2), 1.2, Color(0.9, 0.1, 0.1, a))
