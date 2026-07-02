class_name ElectricFloor
extends Area2D
## Toxic Laboratory. An electrified floor plate: a solid tile (placed by the Level like
## a '#') that cycles safe -> warning flicker -> live (lethal) -> safe. Stand on it while
## it's live and you're fried. Cross during the safe beat. Distinct from the horizontal
## Laser: this zaps whatever stands on the plate itself.

var safe_time := 1.6
var warn_time := 0.45
var live_time := 0.8
var tint := Color(0.5, 0.9, 1.0)

var _state := 0        # 0 safe, 1 warn, 2 live
var _timer := 0.0
var _t := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 16)
	s.shape = r
	s.position = Vector2(0, -8)
	add_child(s)
	_timer = randf_range(0.2, safe_time)

func _process(delta: float) -> void:
	_t += delta
	_timer -= delta
	if _timer <= 0.0:
		match _state:
			0:
				_state = 1
				_timer = warn_time
			1:
				_state = 2
				_timer = live_time
				Audio.play("dash", 0.06)
			2:
				_state = 0
				_timer = safe_time
	if _state == 2:
		for b in get_overlapping_bodies():
			if b is Player:
				(b as Player).die()
	queue_redraw()

func _draw() -> void:
	# Emitter nodes on the plate corners.
	draw_circle(Vector2(-6, -13), 1.6, tint.darkened(0.2))
	draw_circle(Vector2(6, -13), 1.6, tint.darkened(0.2))
	if _state == 1:
		var a := 0.3 + 0.3 * sin(_t * 40.0)
		draw_line(Vector2(-6, -13), Vector2(6, -13), Color(tint.r, tint.g, tint.b, a), 1.0)
	elif _state == 2:
		# Crackling arc across the plate.
		var pts := PackedVector2Array()
		var x := -7.0
		while x <= 7.0:
			pts.append(Vector2(x, -13 + randf_range(-2.0, 2.0)))
			x += 2.0
		for i in pts.size() - 1:
			draw_line(pts[i], pts[i + 1], Color(1, 1, 1, 0.9), 1.4)
		draw_rect(Rect2(-8, -14, 16, 3), Color(tint.r, tint.g, tint.b, 0.4))
