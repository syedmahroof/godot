class_name AvatarSelect
extends CanvasLayer
## Pick the player character. Avatars unlock as secret stars are collected;
## locked ones show their star cost. Left/right (or the on-screen arrows) browse,
## Select confirms the highlighted avatar.

var _index := 0
var _preview: _Preview
var _name: Label
var _status: Label
var _select_btn: Button

func _ready() -> void:
	layer = 20
	add_child(UIKit.make_backdrop())
	_index = Game.avatar_index

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	UIKit.center(root)
	add_child(root)

	root.add_child(UIKit.make_title("AVATAR", 16))
	root.add_child(UIKit.make_label("★ %d collected" % Game.stars, 8, UIKit.GOLD))

	# Browser row:  <   [preview]   >
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	var left := UIKit.make_button("<", 18, 28)
	left.pressed.connect(func(): _step(-1))
	row.add_child(left)

	_preview = _Preview.new()
	_preview.custom_minimum_size = Vector2(40, 40)
	row.add_child(_preview)

	var right := UIKit.make_button(">", 18, 28)
	right.pressed.connect(func(): _step(1))
	row.add_child(right)

	_name = UIKit.make_label("", 12, UIKit.TEXT)
	root.add_child(_name)
	_status = UIKit.make_label("", 8, UIKit.DIM)
	root.add_child(_status)

	_select_btn = UIKit.make_button("Select", 110)
	_select_btn.pressed.connect(_confirm)
	root.add_child(_select_btn)

	var back := UIKit.make_button("Back", 110)
	back.pressed.connect(Game.goto_main_menu)
	root.add_child(back)

	_refresh()
	_select_btn.call_deferred("grab_focus")

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.goto_main_menu()
	elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_step(-1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_step(1)

func _step(dir: int) -> void:
	_index = wrapi(_index + dir, 0, Avatars.count())
	_refresh()

func _refresh() -> void:
	var av := Avatars.get_avatar(_index)
	var unlocked := Avatars.is_unlocked(_index, Game.stars)
	_preview.set_avatar(av, unlocked)
	_name.text = av.get("name", "?")
	if not unlocked:
		_status.text = "Locked — needs ★ %d" % int(av.get("cost", 0))
		_status.add_theme_color_override("font_color", UIKit.DANGER)
		_select_btn.disabled = true
		_select_btn.text = "Locked"
	elif _index == Game.avatar_index:
		_status.text = "Equipped"
		_status.add_theme_color_override("font_color", UIKit.GOLD)
		_select_btn.disabled = false
		_select_btn.text = "Equipped"
	else:
		_status.text = "Unlocked"
		_status.add_theme_color_override("font_color", UIKit.DIM)
		_select_btn.disabled = false
		_select_btn.text = "Select"

func _confirm() -> void:
	if Avatars.is_unlocked(_index, Game.stars):
		Game.set_avatar(_index)
		Game.toast.emit("Avatar: %s" % Avatars.get_avatar(_index).get("name", ""))
		_refresh()


## Draws the highlighted avatar large and gently bobbing; greys it out if locked.
class _Preview extends Control:
	var _av := {}
	var _unlocked := true
	var _t := 0.0

	func set_avatar(av: Dictionary, unlocked: bool) -> void:
		_av = av
		_unlocked = unlocked
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if _av.is_empty():
			return
		var center := size * 0.5 + Vector2(0, sin(_t * 3.0) * 1.5)
		draw_set_transform(center, 0.0, Vector2(2.0, 2.0))
		if _unlocked:
			PlayerSkin.draw_avatar(self, _av, 1, false)
		else:
			# Silhouette for locked avatars.
			var dark := {"body": Color(0.18, 0.18, 0.24), "shape": _av.get("shape", "block")}
			PlayerSkin.draw_avatar(self, dark, 1, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
