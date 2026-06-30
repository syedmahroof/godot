class_name PauseMenu
extends CanvasLayer
## Overlay shown while the game tree is paused. Game sets process_mode = ALWAYS
## on this node so its buttons keep responding; everything else is frozen.

func _ready() -> void:
	layer = 25
	add_child(UIKit.make_dim())

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("PAUSED", 20))
	root.add_child(UIKit.make_label(Game.current_level_name(), 8, UIKit.DIM))
	root.add_child(_spacer(4))

	var resume := _btn(root, "Resume", Game.resume)
	_btn(root, "Restart Level", func():
		Game.resume()
		Game.reload_level())
	_btn(root, "Skip Level…", Game.request_skip)
	_btn(root, "Options", Game.open_options)
	_btn(root, "Main Menu", Game.goto_main_menu)

	resume.call_deferred("grab_focus")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Game.resume()

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := UIKit.make_button(text)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
