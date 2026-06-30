class_name SkipMenu
extends CanvasLayer
## "Stuck? Skip this level" dialog, opened from the pause menu. Two ways out:
## watch a (dummy) rewarded ad for free, or spend coins. Game stays paused
## behind it (this node runs with PROCESS_MODE_ALWAYS, set by Game).

func _ready() -> void:
	layer = 28
	add_child(UIKit.make_dim())

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("STUCK?", 20))
	root.add_child(UIKit.make_label("Skip \"%s\"" % Game.current_level_name(), 8, UIKit.DIM))
	root.add_child(_spacer(4))

	var ad := _btn(root, "▶  Watch Ad  —  Free", Game.skip_via_ad)
	var afford := Game.total_coins >= Game.SKIP_COST
	var pay := _btn(root, "◎  Pay %d  (have %d)" % [Game.SKIP_COST, Game.total_coins], func():
		Game.skip_via_coins())
	pay.disabled = not afford

	root.add_child(_spacer(4))
	var back := UIKit.make_button("Back", 160)
	back.pressed.connect(Game.reopen_pause_menu)
	root.add_child(back)

	ad.call_deferred("grab_focus")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.reopen_pause_menu()

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := UIKit.make_button(text, 160)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
