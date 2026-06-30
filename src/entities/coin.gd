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
		Game.add_coin()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 4.0) * 1.5
	draw_circle(Vector2(0, off), 4.0, Color(1.0, 0.84, 0.2))
	draw_circle(Vector2(0, off), 2.0, Color(1.0, 0.95, 0.6))
