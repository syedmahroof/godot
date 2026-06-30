class_name MainMenu
extends CanvasLayer
## The home screen: title, an animated star/coin backdrop, and the primary menu.
## Continue is disabled until there is saved progress to resume.

func _ready() -> void:
	layer = 20
	add_child(UIKit.make_backdrop())

	# Drifting decorative particles drawn on their own node.
	var particles := _Particles.new()
	particles.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(particles)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("DAVE'S", 26))
	var sub := UIKit.make_title("DEVILISH DESCENT", 11)
	sub.add_theme_color_override("font_color", UIKit.ACCENT)
	root.add_child(sub)

	var stats := UIKit.make_label("★ %d    ◆ %d    ◎ %d    ☠ %d" % [Game.stars, Game.gems, Game.total_coins, Game.deaths], 8, UIKit.DIM)
	root.add_child(stats)
	root.add_child(_spacer(4))

	var first: Button = null
	if Game.has_progress():
		var cont := _btn(root, "Continue  (Lv %d)" % (Game.max_level + 1), Game.continue_game)
		first = cont
	var ng := _btn(root, "New Game", Game.new_game)
	first = first if first else ng
	_btn(root, "Level Select", Game.open_level_select)
	_btn(root, "Avatar", Game.open_avatar_select)
	_btn(root, "Badges", Game.open_badges)
	_btn(root, "Options", Game.open_options)
	_btn(root, "Quit", func(): get_tree().quit())

	root.add_child(_spacer(2))
	root.add_child(UIKit.make_label("Arrows / WASD to move  ·  Space to jump", 7, UIKit.DIM))

	if first:
		first.call_deferred("grab_focus")

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := UIKit.make_button(text, 150, 13)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Lightweight floating-coin/star ambience for the title screen.
class _Particles extends Control:
	var _items: Array[Dictionary] = []

	func _ready() -> void:
		for i in 16:
			_items.append({
				"p": Vector2(randf() * 320.0, randf() * 180.0),
				"v": randf_range(4.0, 14.0),
				"r": randf_range(1.0, 2.5),
				"star": randf() < 0.4,
			})

	func _process(delta: float) -> void:
		for it in _items:
			it.p.y -= it.v * delta
			if it.p.y < -4.0:
				it.p.y = 184.0
				it.p.x = randf() * 320.0
		queue_redraw()

	func _draw() -> void:
		for it in _items:
			if it.star:
				draw_colored_polygon(PackedVector2Array([
					it.p + Vector2(0, -it.r), it.p + Vector2(it.r, 0),
					it.p + Vector2(0, it.r), it.p + Vector2(-it.r, 0),
				]), Color(0.45, 0.9, 1.0, 0.5))
			else:
				draw_circle(it.p, it.r, Color(1.0, 0.84, 0.25, 0.4))
