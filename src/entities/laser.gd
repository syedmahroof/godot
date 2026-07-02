class_name Laser
extends Area2D
## Space Station. A wall-mounted emitter that fires a horizontal tripwire beam on a
## timed cycle: charge (flicker warning) → ON (lethal) → OFF. Cross during the gap.
## Horizontal axis sets it apart from the vertical Flame Jet. Beam glows (unshaded).

var length := 48.0        # beam reach to the right, in px
var on_time := 1.0
var off_time := 1.1
var warn_time := 0.4

var _shape: CollisionShape2D
var _state := 0           # 0 off, 1 charging, 2 on
var _timer := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(length, 4.0)
	_shape.shape = r
	_shape.position = Vector2(length / 2.0, 0)
	_shape.disabled = true
	add_child(_shape)
	_timer = randf_range(0.2, off_time)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		match _state:
			0:
				_state = 1
				_timer = warn_time
			1:
				_state = 2
				_timer = on_time
				_shape.disabled = false
				Audio.play("dash", 0.08)
			2:
				_state = 0
				_timer = off_time
				_shape.disabled = true
	if _state == 2:
		for b in get_overlapping_bodies():
			if b is Player:
				(b as Player).die()
	queue_redraw()

func _draw() -> void:
	# Emitter housing.
	draw_rect(Rect2(-5, -5, 6, 10), Color(0.5, 0.55, 0.62))
	draw_rect(Rect2(-5, -5, 6, 3), Color(0.7, 0.75, 0.82))
	if _state == 0:
		return
	if _state == 1:
		# Warning: thin flickering aim line.
		var a := 0.3 + 0.3 * sin(_timer * 40.0)
		draw_line(Vector2(0, 0), Vector2(length, 0), Color(1.0, 0.3, 0.3, a), 1.0)
		return
	# Live beam.
	draw_rect(Rect2(0, -3, length, 6), Color(1.0, 0.25, 0.3, 0.35))
	draw_rect(Rect2(0, -1.5, length, 3), Color(1.0, 0.5, 0.5, 0.9))
	draw_line(Vector2(0, 0), Vector2(length, 0), Color(1, 1, 1, 0.95), 1.0)
