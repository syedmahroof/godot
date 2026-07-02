class_name Conveyor
extends Area2D
## Steam Factory. A conveyor-belt tile: a solid surface (placed by the Level like a
## '#') that drags anything standing on it. The player counts belt overlaps and drifts
## at `speed * dir`; you can still walk against it, but it shoves you toward hazards.

var speed := 46.0
var dir := 1.0            # +1 right, -1 left
var tint := Color(0.5, 0.55, 0.62)
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	s.position = Vector2(0, -8)   # straddle the tile top where the player stands
	add_child(s)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b is Player:
		(b as Player).belt_enter(dir * speed)

func _on_exit(b: Node) -> void:
	if b is Player:
		(b as Player).belt_exit()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	# Rollers scrolling in the belt direction.
	draw_rect(Rect2(-8, -8, 16, 4), tint.darkened(0.2))
	var off := fmod(_t * speed * dir, 8.0)
	for k in 4:
		var x := -8.0 + off + k * 8.0
		draw_line(Vector2(x, -7), Vector2(x - 2, -5), Color(1, 1, 1, 0.3), 1.0)
	draw_circle(Vector2(-6, -5.5), 1.6, tint.lightened(0.15))
	draw_circle(Vector2(6, -5.5), 1.6, tint.lightened(0.15))
