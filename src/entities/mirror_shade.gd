class_name MirrorShade
extends Area2D
## Umbral Vault. A phantom that shadows the player's motion mirrored across its own
## vertical axis: move right, it moves left. Lethal on contact — position yourself so
## its mirrored path runs it into a wall or hazard instead of into you.

var _player: Player
var _shape: CollisionShape2D
var _axis_x := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_axis_x = position.x
	_shape = CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 6.0
	c.height = 14.0
	_shape.shape = c
	add_child(_shape)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player and not _player.dead:
		var target := Vector2(2.0 * _axis_x - _player.global_position.x, _player.global_position.y)
		global_position = global_position.move_toward(target, 150.0 * delta)
	queue_redraw()

func _on_body(b: Node) -> void:
	if b is Player:
		(b as Player).die()

func _draw() -> void:
	draw_circle(Vector2(0, 0), 7.0, Color(0.16, 0.14, 0.28, 0.85))
	draw_circle(Vector2(0, 0), 7.0, Color(0.45, 0.40, 0.70, 0.5))
	draw_circle(Vector2(-2, -1), 1.4, Color(0.85, 0.9, 1.0))
	draw_circle(Vector2(2, -1), 1.4, Color(0.85, 0.9, 1.0))
