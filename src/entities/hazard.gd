class_name Hazard
extends Area2D
## A lethal liquid tile — lava in caves, acid/toxic pools elsewhere. Touch the
## surface and you die. The hitbox sits a little below the top so grazing the
## very edge is survivable (Celeste-style fairness).

var tint := Color(1.0, 0.42, 0.15)
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 9)
	s.shape = r
	s.position = Vector2(0, 3)
	add_child(s)
	body_entered.connect(_on_body_entered)

func _on_body_entered(b: Node) -> void:
	if b is Player:
		b.die()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-8, 2, 16, 6), tint.darkened(0.25))
	for i in 4:
		var x := -6.0 + i * 4.0
		var bob := sin(_t * 3.0 + i * 1.7) * 1.6
		draw_circle(Vector2(x, 1.5 + bob), 3.0, tint)
		draw_circle(Vector2(x, 1.5 + bob), 1.4, tint.lightened(0.3))
