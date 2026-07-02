class_name QuicksandZone
extends Area2D
## Desert Ruins. A pool of quicksand: a solid tile (placed by the Level like a '#') you
## can stand on, but it drags at your movement and — if you linger too long — swallows
## you. Hop across; never stop. The player counts overlaps and runs its own sink timer.

var tint := Color(0.78, 0.62, 0.34)
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	s.position = Vector2(0, -8)
	add_child(s)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(b: Node) -> void:
	if b is Player:
		(b as Player).add_sand(1)

func _on_exit(b: Node) -> void:
	if b is Player:
		(b as Player).add_sand(-1)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-8, -8, 16, 12), Color(tint.r, tint.g, tint.b, 0.85))
	# Slow gloopy ripples.
	for k in 3:
		var y := -6.0 + sin(_t * 1.5 + k) * 1.2
		draw_line(Vector2(-7, y + k * 3.0), Vector2(7, y + k * 3.0), tint.darkened(0.2), 1.0)
