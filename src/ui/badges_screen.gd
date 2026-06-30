class_name BadgesScreen
extends CanvasLayer
## A grid of every badge. Earned badges show in gold with their name; locked ones
## are dimmed but still show the name + goal so there's always something to chase.

func _ready() -> void:
	layer = 20
	add_child(UIKit.make_backdrop())

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("BADGES", 16))
	root.add_child(UIKit.make_label("Earned %d / %d" % [Game.badge_count(), Badges.count()], 8, UIKit.GOLD))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	root.add_child(grid)

	for b in Badges.list():
		var earned: bool = Game.badges_earned.get(b.get("id", ""), false)
		grid.add_child(_card(b, earned))

	root.add_child(_spacer(2))
	var back := UIKit.make_button("Back", 120)
	back.pressed.connect(Game.goto_main_menu)
	root.add_child(back)
	back.call_deferred("grab_focus")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.goto_main_menu()

func _card(b: Dictionary, earned: bool) -> Control:
	var panel := UIKit.make_panel()
	panel.custom_minimum_size = Vector2(100, 30)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)

	var icon := "🏅" if earned else "🔒"
	var title := UIKit.make_label("%s %s" % [icon, b.get("name", "")], 8,
		UIKit.GOLD if earned else UIKit.DIM)
	box.add_child(title)

	var desc := UIKit.make_label(b.get("desc", ""), 6, UIKit.DIM if earned else Color(0.4, 0.42, 0.52))
	box.add_child(desc)
	return panel

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
