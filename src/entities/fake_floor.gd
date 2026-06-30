class_name FakeFloor
extends StaticBody2D
## Looks exactly like a normal solid tile, feels solid for a split second — then
## vanishes the instant you put weight on it, dropping you (usually onto spikes).
## Deterministic so it's learnable on a retry, but a nasty first-time surprise.

var color := Color(0.5, 0.2, 0.2)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	add_child(s)

	# Top sensor: the moment the player rests on it, it gives way.
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var a := CollisionShape2D.new()
	var ar := RectangleShape2D.new()
	ar.size = Vector2(14, 6)
	a.shape = ar
	a.position = Vector2(0, -9)
	area.add_child(a)
	add_child(area)
	area.body_entered.connect(_on_top)

func _on_top(b: Node) -> void:
	if b is Player:
		Audio.play("portal", 0.1)
		Burst.spawn(get_parent(), global_position, color.lightened(0.1), 8, 60.0, 0.4, 1.8)
		queue_free()

func _draw() -> void:
	# Drawn to mimic TileFactory's themed block so it's indistinguishable.
	draw_rect(Rect2(-8, -8, 16, 16), color.darkened(0.25), true)
	draw_rect(Rect2(-8, -8, 16, 3), color.lightened(0.18), true)
	draw_rect(Rect2(-8, -8, 16, 16), color.darkened(0.35), false, 1.0)
