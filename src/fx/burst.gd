class_name Burst
extends Node2D
## A one-shot particle burst that draws a spray of soft dots flying outward and
## fading, then frees itself. The whole game's "juice" runs through this: coin
## pops, landing dust, stomps, deaths. Pure draw calls — no assets.

var _color := Color.WHITE
var _count := 8
var _speed := 70.0
var _life := 0.45
var _grav := 220.0
var _size := 2.0

var _parts: Array[Dictionary] = []
var _t := 0.0

## Spawn a burst at a world position. `parent` should be a node that outlives the
## emitter (e.g. the Level), since the source entity often frees itself.
static func spawn(parent: Node, pos: Vector2, color: Color, count := 8, speed := 70.0, life := 0.45, size := 2.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var b := Burst.new()
	b._color = color
	b._count = count
	b._speed = speed
	b._life = life
	b._size = size
	b.position = pos
	parent.add_child(b)

func _ready() -> void:
	z_index = 50
	for i in _count:
		var ang := randf() * TAU
		var spd := _speed * randf_range(0.4, 1.0)
		_parts.append({
			"p": Vector2.ZERO,
			"v": Vector2(cos(ang), sin(ang) - 0.6) * spd,
			"r": _size * randf_range(0.6, 1.3),
		})

func _process(delta: float) -> void:
	_t += delta
	if _t >= _life:
		queue_free()
		return
	for part in _parts:
		part.v.y += _grav * delta
		part.p += part.v * delta
	queue_redraw()

func _draw() -> void:
	var fade := 1.0 - (_t / _life)
	var col := Color(_color.r, _color.g, _color.b, fade)
	for part in _parts:
		draw_circle(part.p, part.r * fade, col)
