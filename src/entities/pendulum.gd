class_name Pendulum
extends Area2D
## A blade swinging from a fixed pivot (the grid cell). The blade hangs below and
## sweeps side to side; touching the blade end is fatal. The collision shape is
## re-positioned to the blade each frame, so lethality is tested via overlap.

var length := 26.0        # rod length (pixels)
var amp := 0.95           # max swing angle from vertical (radians)
var speed := 2.0

var _t := 0.0
var _shape: CollisionShape2D
var _blade := Vector2.DOWN * 26.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	_shape.shape = c
	add_child(_shape)
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta * speed
	var ang := sin(_t) * amp
	_blade = Vector2(sin(ang), cos(ang)) * length
	_shape.position = _blade
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).die()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 2.0, Color(0.5, 0.5, 0.56))          # pivot
	draw_line(Vector2.ZERO, _blade, Color(0.4, 0.4, 0.47), 1.5)    # rod
	var col := Color(0.82, 0.84, 0.92)
	draw_circle(_blade, 6.5, col.darkened(0.25))                  # blade hub
	draw_colored_polygon(PackedVector2Array([
		_blade + Vector2(-7.5, 0), _blade + Vector2(7.5, 0), _blade + Vector2(0, 6.5)]), col)
