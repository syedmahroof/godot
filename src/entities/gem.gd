class_name Gem
extends Area2D
## A chunky bonus gem — one per level, worth a pile of coins and a bragging-rights
## counter. Spins, glows, and throws a satisfying burst when grabbed.

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
		Burst.spawn(get_parent(), global_position, Color(0.6, 0.95, 1.0), 16, 110.0, 0.6, 2.4)
		Audio.play("gem")
		Game.add_gem()
		queue_free()

func _draw() -> void:
	var off := sin(_t * 3.0) * 1.5
	var glow := 0.5 + 0.5 * sin(_t * 4.0)
	draw_circle(Vector2(0, off), 11.0, Color(0.5, 0.9, 1.0, 0.14 * glow))
	# Faceted gem shape.
	var w := 5.5
	var top := -7.0 + off
	var mid := 0.0 + off
	var bot := 7.0 + off
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, top), Vector2(w, mid), Vector2(0, bot), Vector2(-w, mid),
	]), Color(0.45, 0.85, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, top), Vector2(w, mid), Vector2(0, mid),
	]), Color(0.75, 0.95, 1.0))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, top), Vector2(-w, mid), Vector2(0, mid),
	]), Color(0.6, 0.9, 1.0))
