class_name PlayerSkin
extends Node2D
## Draws the player and handles squash & stretch. Kept separate so scaling the
## visual never touches the collision shape.

var _scale := Vector2.ONE

func squash(s: Vector2) -> void:
	_scale = s

func _process(delta: float) -> void:
	_scale = _scale.lerp(Vector2.ONE, clampf(14.0 * delta, 0.0, 1.0))
	scale = _scale
	queue_redraw()

func _draw() -> void:
	var p := get_parent() as Player
	var body_col := Color(0.96, 0.78, 0.25)
	if p and p._dash_time > 0.0:
		body_col = Color(0.45, 0.85, 1.0)
	draw_rect(Rect2(-5, -7, 10, 14), body_col, true)
	draw_rect(Rect2(-5, -7, 10, 14), body_col.darkened(0.35), false, 1.0)
	var eye_x := 2 * (p.facing if p else 1)
	draw_rect(Rect2(eye_x - 1, -3, 2, 3), Color(0.1, 0.1, 0.15), true)
