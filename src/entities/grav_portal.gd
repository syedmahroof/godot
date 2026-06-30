class_name GravPortal
extends Area2D
## A swirling portal that flips the player's gravity on contact. The signature
## toy of the final world — turns the whole room upside down. Has a short
## cooldown so you don't flicker while standing in it.

var _t := 0.0
var _cool := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	s.shape = c
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	_cool = move_toward(_cool, 0.0, delta)
	queue_redraw()

func _on_body_entered(b: Node) -> void:
	if b is Player and _cool <= 0.0:
		_cool = 0.45
		(b as Player).flip_gravity()
		Audio.play("portal")
		Burst.spawn(get_parent(), global_position, Color(0.8, 0.55, 1.0), 14, 100.0, 0.5)
		Game.toast.emit("WHOOP! Gravity flipped")

func _draw() -> void:
	var glow := 0.5 + 0.5 * sin(_t * 5.0)
	draw_circle(Vector2.ZERO, 12.0, Color(0.7, 0.5, 1.0, 0.14 * glow))
	# A couple of rotating arcs to suggest a swirl.
	for ring in 3:
		var rad := 8.0 - ring * 2.2
		var a := _t * (2.0 + ring) + ring * 2.0
		var pts := PackedVector2Array()
		for i in 9:
			var ang := a + float(i) / 8.0 * PI
			pts.append(Vector2(cos(ang), sin(ang)) * rad)
		draw_polyline(pts, Color(0.85, 0.7, 1.0, 0.9 - ring * 0.2), 1.5)
