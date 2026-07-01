class_name Exit
extends Area2D
## Reaching this completes the level — unless a World Guardian is still alive, in
## which case the door is locked (barred, with a padlock) until the boss falls.

var _t := 0.0
var _toast_cd := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(14, 26)
	s.shape = r
	s.position = Vector2(0, -5)
	add_child(s)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_t += delta
	_toast_cd = maxf(0.0, _toast_cd - delta)
	queue_redraw()

## Locked while any boss is alive (they add themselves to the "boss" group).
func _locked() -> bool:
	return not get_tree().get_nodes_in_group("boss").is_empty()

func _on_body_entered(b: Node) -> void:
	if not (b is Player):
		return
	if _locked():
		if _toast_cd <= 0.0:
			_toast_cd = 1.6
			Game.toast.emit("Defeat the Guardian first!")
			Audio.play("select", 0.1)
		return
	Burst.spawn(get_parent(), global_position + Vector2(0, -6), Color(0.85, 0.75, 1.0), 20, 120.0, 0.7, 2.4)
	Audio.play("complete")
	Game.complete_level()

func _draw() -> void:
	var locked := _locked()
	var frame: Color = Color(0.30, 0.14, 0.16) if locked else Color(0.32, 0.22, 0.42)
	var inner: Color = Color(0.5, 0.28, 0.30) if locked else Color(0.6, 0.5, 0.85)
	draw_rect(Rect2(-8, -22, 16, 30), frame, true)
	draw_rect(Rect2(-6, -19, 12, 27), inner, true)
	if locked:
		# Bars across the doorway + a little padlock.
		for i in 3:
			draw_rect(Rect2(-6, -16 + i * 8, 12, 2), Color(0.20, 0.10, 0.12))
		draw_arc(Vector2(0, -8), 2.4, PI, TAU, 8, Color(0.9, 0.78, 0.32), 1.2)
		draw_rect(Rect2(-3, -8, 6, 5), Color(0.9, 0.78, 0.32))
	else:
		var glow := 0.5 + 0.5 * sin(_t * 3.0)
		draw_circle(Vector2(0, -6), 2.5, Color(1.0, 1.0, 0.7, glow))
