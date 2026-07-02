class_name Wisp
extends Area2D
## Umbral Vault. A floating spirit that is harmless in shadow but wakes and lunges
## at the player the moment it is caught in the lantern's light — so widening your
## beam near one is a mistake. Avoid by keeping the light narrow as you slip past.

var _player: Player
var _origin := Vector2.ZERO
var _t := 0.0
var _shape: CollisionShape2D
var lit := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_origin = position
	_t = randf() * TAU
	_shape = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	_shape.shape = c
	add_child(_shape)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	_t += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player and not _player.dead:
		var d := global_position.distance_to(_player.global_position)
		lit = _player.dark and d < _player.light_r
		if lit:
			global_position = global_position.move_toward(_player.global_position, 52.0 * delta)
		else:
			position = _origin + Vector2(sin(_t) * 4.0, cos(_t * 0.8) * 6.0)
	queue_redraw()

func _on_body(b: Node) -> void:
	if b is Player and lit:
		(b as Player).die()

func _draw() -> void:
	var a := 0.95 if lit else 0.55
	var col := Color(1.0, 0.55, 0.45, a) if lit else Color(0.6, 0.78, 1.0, a)
	draw_circle(Vector2(0, 0), 6.5, col.darkened(0.2))
	draw_circle(Vector2(0, 0), 4.0, col)
	draw_circle(Vector2(0, 0), 2.0, Color(1, 1, 1, a))
