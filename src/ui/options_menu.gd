class_name OptionsMenu
extends CanvasLayer
## Settings: screen shake, fullscreen, and a guarded save reset. Reachable from
## both the main menu and the pause menu, so Back returns to whichever is
## appropriate (pause if a game is running, otherwise the home screen).

var _shake_btn: Button
var _full_btn: Button
var _sound_btn: Button
var _reset_btn: Button
var _confirm_reset := false

const _SOUND_STEPS := [0.0, 0.34, 0.67, 1.0]
const _SOUND_LABELS := ["OFF", "LOW", "MED", "HIGH"]

func _ready() -> void:
	layer = 30
	# Keep working even when the tree is paused (opened from the pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UIKit.make_dim() if Game.state == Game.State.PLAYING else UIKit.make_backdrop())

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("OPTIONS", 18))
	root.add_child(_spacer(4))

	_shake_btn = _btn(root, "", func():
		Game.set_screen_shake(not Game.screen_shake)
		_refresh())
	_full_btn = _btn(root, "", func():
		Game.set_fullscreen(not Game.fullscreen)
		_refresh())
	_sound_btn = _btn(root, "", func():
		Game.set_sfx_volume(_next_sound())
		_refresh())
	root.add_child(_spacer(4))
	_reset_btn = _btn(root, "", _on_reset)

	root.add_child(_spacer(4))
	var back := UIKit.make_button("Back", 150)
	back.pressed.connect(_back)
	root.add_child(back)

	_refresh()
	_shake_btn.call_deferred("grab_focus")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		_back()

func _refresh() -> void:
	_shake_btn.text = "Screen Shake:  %s" % _onoff(Game.screen_shake)
	_full_btn.text = "Fullscreen:  %s" % _onoff(Game.fullscreen)
	_sound_btn.text = "Sound:  %s" % _SOUND_LABELS[_sound_index()]
	_reset_btn.text = "Erase Save — Confirm?" if _confirm_reset else "Erase Save"
	_reset_btn.add_theme_color_override("font_color", UIKit.DANGER if _confirm_reset else UIKit.TEXT)

func _onoff(v: bool) -> String:
	return "ON" if v else "OFF"

func _sound_index() -> int:
	# Nearest configured step to the current volume.
	var best := 0
	var best_d := 9.0
	for i in _SOUND_STEPS.size():
		var d: float = absf(_SOUND_STEPS[i] - Game.sfx_volume)
		if d < best_d:
			best_d = d
			best = i
	return best

func _next_sound() -> float:
	return _SOUND_STEPS[(_sound_index() + 1) % _SOUND_STEPS.size()]

func _on_reset() -> void:
	if _confirm_reset:
		Game.reset_save()
		_confirm_reset = false
	else:
		_confirm_reset = true
	_refresh()

func _back() -> void:
	# Returning to the pause menu (if mid-game) or the main menu otherwise.
	if Game.state == Game.State.PLAYING:
		Game.reopen_pause_menu()
	else:
		Game.goto_main_menu()

func _btn(parent: Node, text: String, cb: Callable) -> Button:
	var b := UIKit.make_button(text, 150)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
