class_name Star
extends Area2D
## Secret collectible. One per level, usually tucked off the main path.

var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player:
		Burst.spawn(get_parent(), global_position, Color(0.5, 0.92, 1.0), 14, 100.0, 0.6, 2.2)
		Audio.play("star")
		Game.add_star()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 3.0) * 1.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6 + off), Vector2(5, off), Vector2(0, 6 + off), Vector2(-5, off)
	]), Color(0.45, 0.9, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -3 + off), Vector2(2.5, off), Vector2(0, 3 + off), Vector2(-2.5, off)
	]), Color(0.85, 0.98, 1.0))
