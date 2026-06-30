class_name Coin
extends Area2D

var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 5.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player:
		Burst.spawn(get_parent(), global_position, Color(1.0, 0.86, 0.3), 7, 70.0, 0.4, 1.6)
		Audio.play("coin", 0.12)
		Game.add_coin()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 4.0) * 1.5
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2(0, off), 7.0, Color(1.0, 0.86, 0.3, 0.14 * glow))
	draw_circle(Vector2(0, off), 4.0, Color(1.0, 0.84, 0.2))
	draw_circle(Vector2(0, off), 2.0, Color(1.0, 0.95, 0.6))
