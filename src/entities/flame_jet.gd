class_name FlameJet
extends Area2D
## A floor vent that erupts a column of fire on a cycle: dormant (safe) → sparks
## (warning) → flames (lethal) → dormant. Only lethal while actually firing, and
## the warning sparks telegraph it, so it's a timing challenge rather than a
## coin-flip. Fires upward from the cell.

const CYCLE := 2.2

var height := 30.0

var _t := 0.0
var _shape: CollisionShape2D
var _on := false
var _warn := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, height)
	_shape.shape = r
	_shape.position = Vector2(0, -height * 0.5 + 4.0)
	add_child(_shape)
	_t = randf() * CYCLE

func _process(delta: float) -> void:
	_t = fmod(_t + delta, CYCLE)
	var f := _t / CYCLE
	_warn = f > 0.45 and f < 0.55
	_on = f >= 0.55 and f < 0.9
	if _on:
		for b in get_overlapping_bodies():
			if b is Player:
				(b as Player).die()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-5, 4, 10, 4), Color(0.3, 0.3, 0.34))          # nozzle
	if _warn:
		for k in 4:
			draw_circle(Vector2(randf_range(-3, 3), 2.0 - randf() * 4.0), 1.0, Color(1.0, 0.7, 0.2, 0.85))
	if _on:
		var h := height
		var base := Color(1.0, 0.48, 0.14, 0.9)
		var tip := Color(1.0, 0.85, 0.42, 0.9)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-5, 4), Vector2(5, 4), Vector2(3, 4 - h * 0.6), Vector2(0, 4 - h), Vector2(-3, 4 - h * 0.6)]), base)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-3, 4), Vector2(3, 4), Vector2(0, 4 - h * 0.7)]), tip)
