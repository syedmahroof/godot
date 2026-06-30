class_name MovingPlatform
extends AnimatableBody2D
## A platform that slides back and forth along one axis, carrying the player.
## Built as an AnimatableBody2D with sync_to_physics so riders move with it.
## `axis` and `span` are set by the level parser from the grid character.

var axis := Vector2.RIGHT
var span := 36.0          # travel distance (pixels) to each side of the origin
var speed := 1.6          # radians/sec of the sine sweep

var _origin := Vector2.ZERO
var _t := 0.0
var _glow := 0.0

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	process_priority = -1
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(28, 8)
	s.shape = r
	add_child(s)
	_origin = position
	# Random phase so a row of platforms doesn't move in lockstep.
	_t = randf() * TAU

func _physics_process(delta: float) -> void:
	_t += delta * speed
	position = _origin + axis * sin(_t) * span
	_glow += delta
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color(0.55, 0.75, 1.0, 0.08))
	var body := Rect2(-14, -4, 28, 8)
	draw_rect(body, Color(0.42, 0.52, 0.78), true)
	draw_rect(Rect2(-14, -4, 28, 2), Color(0.62, 0.74, 1.0), true)
	draw_rect(body, Color(0.7, 0.8, 1.0, 0.6), false, 1.0)
