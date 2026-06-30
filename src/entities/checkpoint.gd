class_name Checkpoint
extends Area2D

var active := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 16)
	s.shape = r
	add_child(s)
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if b is Player and not active:
		active = true
		Audio.play("checkpoint")
		Game.set_checkpoint(global_position)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-1, -8, 2, 16), Color(0.45, 0.32, 0.22), true)
	var flag := Color(0.3, 0.9, 0.45) if active else Color(0.55, 0.55, 0.6)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -8), Vector2(9, -5), Vector2(1, -2)]), flag)
