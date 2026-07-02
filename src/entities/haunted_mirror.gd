class_name HauntedMirror
extends Area2D
## Haunted Mansion. A cursed looking-glass. When the player draws near, a wraith steps
## out of it — it spawns a chasing Ghost (on a cooldown so it can't flood). Harmless to
## touch itself; the danger is what it releases.

var tint := Color(0.6, 0.95, 0.85)
var trigger_range := 60.0
var cooldown := 3.2
var _cd := 0.0
var _t := 0.0
var _flash := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(12, 22)
	s.shape = r
	add_child(s)

func _process(delta: float) -> void:
	_t += delta
	_cd = maxf(0.0, _cd - delta)
	_flash = maxf(0.0, _flash - delta)
	if _cd <= 0.0:
		var p := _player()
		if p and global_position.distance_to(p.global_position) < trigger_range:
			_release()
	queue_redraw()

func _release() -> void:
	_cd = cooldown
	_flash = 0.4
	var g := Ghost.new()
	g.tint = tint
	g.position = global_position + Vector2(0, -2)
	get_parent().add_child(g)
	Audio.play("dash", 0.1)

func _player() -> Player:
	var a := get_tree().get_nodes_in_group("player")
	return a[0] if not a.is_empty() else null

func _draw() -> void:
	# Ornate frame.
	draw_rect(Rect2(-7, -12, 14, 24), Color(0.5, 0.4, 0.2))
	# Glass, rippling / flaring when it releases.
	var glow := 0.25 + 0.15 * sin(_t * 3.0) + _flash
	draw_rect(Rect2(-5, -10, 10, 20), Color(tint.r, tint.g, tint.b, clampf(glow, 0.15, 0.9)))
	draw_line(Vector2(-4, -8), Vector2(3, 8), Color(1, 1, 1, 0.25), 1.0)
