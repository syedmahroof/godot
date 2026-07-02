class_name Gloomhound
extends Area2D
## Umbral Vault. The inverse of a Wisp: it sleeps harmlessly in light but hunts in
## shadow, creeping toward the player and killing on contact. Keep it bathed in the
## wide lantern beam to pass — which drains your ability to hide from Wisps nearby.

var _player: Player
var _shape: CollisionShape2D
var _face := 1.0
var lit := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 6.0
	c.height = 12.0
	_shape.shape = c
	add_child(_shape)
	body_entered.connect(_on_body)

func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
	if _player and not _player.dead:
		var d := global_position.distance_to(_player.global_position)
		lit = _player.dark and d < _player.light_r
		if not lit:
			var dir := signf(_player.global_position.x - global_position.x)
			if dir != 0.0:
				_face = dir
			position.x += _face * 46.0 * delta
	queue_redraw()

func _on_body(b: Node) -> void:
	if b is Player and not lit:
		(b as Player).die()

func _draw() -> void:
	var col := Color(0.30, 0.55, 0.42) if lit else Color(0.75, 0.20, 0.28)
	draw_circle(Vector2(0, 6), 6.0, Color(0, 0, 0, 0.2))
	draw_rect(Rect2(-6, -4, 12, 10), col)
	# glowing eyes, brighter when hunting
	var e := 0.5 if lit else 1.0
	draw_circle(Vector2(2.0 * _face - 2.0, -1), 1.4, Color(1.0, 0.85, 0.3, e))
	draw_circle(Vector2(2.0 * _face + 2.0, -1), 1.4, Color(1.0, 0.85, 0.3, e))
