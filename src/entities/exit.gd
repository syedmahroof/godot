class_name Exit
extends Area2D
## Reaching this completes the level.

var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 26)
	s.shape = r
	s.position = Vector2(0, -5)
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player:
		Game.complete_level()

func _draw() -> void:
	draw_rect(Rect2(-8, -22, 16, 30), Color(0.32, 0.22, 0.42), true)
	draw_rect(Rect2(-6, -19, 12, 27), Color(0.6, 0.5, 0.85), true)
	var glow := 0.5 + 0.5 * sin(_t * 3.0)
	draw_circle(Vector2(0, -6), 2.5, Color(1.0, 1.0, 0.7, glow))
