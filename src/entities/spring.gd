class_name Spring
extends Area2D
## A bounce pad. Landing on it launches the player high — the most addictive
## little toy in the game. Squashes on contact and pops back.

const BOUNCE := 360.0

var _t := 0.0
var _press := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 8)
	s.shape = r
	s.position = Vector2(0, 4)
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	_press = move_toward(_press, 0.0, delta * 4.0)
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player:
		var p := b as Player
		# Only fling when actually coming down onto it.
		if p.velocity.y * p.gravity_sign >= -10.0:
			p.bounce(BOUNCE)
			_press = 1.0
			Audio.play("bounce", 0.05)
			Burst.spawn(get_parent(), global_position, Color(0.4, 1.0, 0.7), 10, 90.0, 0.4)

func _draw() -> void:
	var squish := _press * 4.0
	var glow := 0.4 + 0.3 * sin(_t * 6.0)
	# Soft glow.
	draw_circle(Vector2(0, 6), 10.0, Color(0.4, 1.0, 0.7, 0.12 * glow))
	# Base.
	draw_rect(Rect2(-7, 6, 14, 4), Color(0.18, 0.22, 0.30), true)
	# Springy top, compresses when pressed.
	var top := Rect2(-6, 0 + squish, 12, 6 - squish)
	draw_rect(top, Color(0.35, 0.95, 0.65), true)
	draw_rect(top, Color(0.6, 1.0, 0.85), false, 1.0)
