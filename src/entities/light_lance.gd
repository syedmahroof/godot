class_name LightLance
extends Area2D
## Umbral Vault. A beam of hard light that sweeps in a full continuous rotation
## around its anchor (unlike the pendulum's short swing). The lit ray is lethal —
## time your crossing for the gap between passes. Glows in the dark (unshaded).

var length := 64.0
var speed := 1.7          # radians / second
var _shape: CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	rotation = randf() * TAU
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(length, 5.0)
	_shape.shape = r
	_shape.position = Vector2(length / 2.0, 0)
	add_child(_shape)

func _process(delta: float) -> void:
	rotation += speed * delta
	for b in get_overlapping_bodies():
		if b is Player:
			(b as Player).die()
	queue_redraw()

func _draw() -> void:
	# Bright core fading along its length, drawn in local (rotated) space.
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.95, 0.7))
	var pts := PackedVector2Array([
		Vector2(0, -3.5), Vector2(length, -1.5), Vector2(length, 1.5), Vector2(0, 3.5)])
	draw_colored_polygon(pts, Color(1.0, 0.92, 0.6, 0.85))
	draw_line(Vector2(0, 0), Vector2(length, 0), Color(1, 1, 1, 0.9), 1.5)
