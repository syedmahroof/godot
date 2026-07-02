class_name Hud
extends CanvasLayer
## In-game HUD: a top stat bar (coins / time / stars+gems / deaths), the world +
## level name, a combo popup, full-screen flashes (death/gem/flawless), and
## centred toast messages. Built in code to match the rest of the project.

var _coins: Label
var _time: Label
var _stats: Label
var _level: Label
var _combo: Label
var _toast: Label
var _badge: Label
var _flash: ColorRect
var _toast_t := 0.0
var _badge_t := 0.0
var _flash_t := 0.0

# Mobile controls
var _mobile_mode := false
var _btn_left: TouchScreenButton
var _btn_right: TouchScreenButton
var _btn_jump: TouchScreenButton
var _btn_dash: TouchScreenButton
var _btn_shoot: TouchScreenButton
var _btn_pause: TouchScreenButton
var _btn_restart: TouchScreenButton      # tap to restart the current level
var _btn_toggle: TouchScreenButton       # always-visible show/hide switch
var _controls_hidden := false

func _ready() -> void:
	layer = 10

	# Full-screen flash overlay (death/gem/flawless), drawn above the world.
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# Translucent top bar so stats stay readable over any background.
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.05, 0.09, 0.5)
	bar.size = Vector2(320, 13)
	add_child(bar)

	_coins = _make(Vector2(4, 2), HORIZONTAL_ALIGNMENT_LEFT, UIKit.GOLD)
	_time = _make(Vector2(120, 2), HORIZONTAL_ALIGNMENT_CENTER, UIKit.TEXT)
	_time.size = Vector2(80, 10)
	_stats = _make(Vector2(208, 2), HORIZONTAL_ALIGNMENT_RIGHT, Color(0.6, 0.95, 1.0))
	_stats.size = Vector2(108, 10)

	_combo = _make(Vector2(4, 14), HORIZONTAL_ALIGNMENT_LEFT, UIKit.GOLD)
	_combo.add_theme_font_size_override("font_size", 9)

	_level = _make(Vector2(4, 168), HORIZONTAL_ALIGNMENT_LEFT, UIKit.DIM)
	_level.size = Vector2(220, 10)
	var hint := _make(Vector2(232, 168), HORIZONTAL_ALIGNMENT_RIGHT, UIKit.DIM)
	hint.size = Vector2(84, 10)
	hint.text = "Esc: pause"

	_toast = _make(Vector2(0, 78), HORIZONTAL_ALIGNMENT_CENTER, UIKit.GOLD)
	_toast.size = Vector2(320, 16)
	_toast.add_theme_font_size_override("font_size", 11)

	_badge = _make(Vector2(0, 96), HORIZONTAL_ALIGNMENT_CENTER, Color(1.0, 0.86, 0.35))
	_badge.size = Vector2(320, 14)
	_badge.add_theme_font_size_override("font_size", 9)

	_mobile_mode = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
	if _mobile_mode:
		_setup_mobile_controls()

	Game.hud_changed.connect(_refresh)
	Game.toast.connect(_show_toast)
	Game.flash.connect(_show_flash)
	Game.badge_earned.connect(_show_badge)
	_refresh()

func _make(pos: Vector2, align: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("outline_size", 2)
	add_child(l)
	return l

func _process(delta: float) -> void:
	_time.text = "%.2f" % Game.time

	if Game.combo > 1:
		_combo.text = "COMBO x%d" % Game.combo
		_combo.modulate.a = clampf(Game.combo_timer, 0.0, 1.0)
		var pop := 1.0 + 0.08 * sin(Game.combo_timer * 18.0)
		_combo.scale = Vector2(pop, pop)
	else:
		_combo.text = ""

	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
		if _toast_t <= 0.0:
			_toast.text = ""

	if _badge_t > 0.0:
		_badge_t -= delta
		_badge.modulate.a = clampf(_badge_t, 0.0, 1.0)
		if _badge_t <= 0.0:
			_badge.text = ""

	if _flash_t > 0.0:
		_flash_t -= delta
		var k := clampf(_flash_t / _flash_dur, 0.0, 1.0)
		_flash.color = Color(_flash_rgb.r, _flash_rgb.g, _flash_rgb.b, _flash_peak * k)

func _refresh() -> void:
	_coins.text = "◎ %d" % Game.run_coins
	_stats.text = "★ %d   ◆ %d   ☠ %d" % [Game.stars, Game.gems, Game.deaths]
	var world := Game.current_world_name()
	var label := "%s — %s" % [world, Game.current_level_name()] if world != "" else Game.current_level_name()
	if Game.active_tool != "":
		label += "    " + Game.active_tool
	_level.text = label
	_level.size = Vector2(312, 10)

	if _mobile_mode:
		_refresh_control_visibility()

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.2
	_toast.modulate.a = 1.0

func _show_badge(name: String, desc: String) -> void:
	_badge.text = "🏅 Badge: %s — %s" % [name, desc]
	_badge_t = 3.2
	_badge.modulate.a = 1.0

var _flash_rgb := Color.WHITE
var _flash_peak := 0.5
var _flash_dur := 0.4

func _show_flash(color: Color) -> void:
	# `color.a` is the peak opacity; the flash fades from there to 0.
	_flash_rgb = Color(color.r, color.g, color.b)
	_flash_peak = color.a
	_flash_dur = 0.4
	_flash_t = _flash_dur
	_flash.color = Color(color.r, color.g, color.b, color.a)

# --- Mobile Touch Controls Implementation ---

func _setup_mobile_controls() -> void:
	# Bigger buttons, comfortably spaced. Movement on the left thumb, actions on
	# the right. Hit areas are padded well beyond the visible disc (see below).
	_btn_left = _create_touch_button("move_left", Vector2(30, 150), 18, "◀")
	_btn_right = _create_touch_button("move_right", Vector2(74, 150), 18, "▶")
	_btn_jump = _create_touch_button("jump", Vector2(292, 150), 20, "▲")
	_btn_dash = _create_touch_button("dash", Vector2(246, 150), 15, "⚡")
	_btn_shoot = _create_touch_button("shoot", Vector2(292, 106), 15, "✦")
	_btn_pause = _create_touch_button("pause", Vector2(306, 22), 9, "‖")

	# Tap to restart the current level (respawn at last checkpoint), tucked under pause.
	_btn_restart = _create_touch_button("", Vector2(306, 44), 9, "⟳")
	_btn_restart.pressed.connect(func(): Game.reload_level())

	# Always-visible switch to hide/show the on-screen pad (bottom centre so it
	# never sits under a thumb during play).
	_btn_toggle = _create_touch_button("", Vector2(160, 171), 8, "☰")
	_btn_toggle.pressed.connect(func():
		Game.set_touch_controls_hidden(not Game.touch_controls_hidden))

	Game.touch_controls_changed.connect(_apply_controls_hidden)
	_controls_hidden = Game.touch_controls_hidden
	_refresh_control_visibility()

## Show/hide the pad (called by the toggle and when the setting changes).
func _apply_controls_hidden(hidden: bool) -> void:
	_controls_hidden = hidden
	_refresh_control_visibility()

## Reconcile every button's visibility with the hidden flag and ability unlocks.
## The toggle switch itself always stays on screen so the pad can be recalled.
func _refresh_control_visibility() -> void:
	if not _mobile_mode:
		return
	var show := not _controls_hidden
	if _btn_left: _btn_left.visible = show
	if _btn_right: _btn_right.visible = show
	if _btn_jump: _btn_jump.visible = show
	if _btn_pause: _btn_pause.visible = show
	if _btn_restart: _btn_restart.visible = show
	if _btn_dash: _btn_dash.visible = show and Game.dash_unlocked
	if _btn_shoot:
		var has_gun := false
		var p = get_tree().get_first_node_in_group("player")
		if p and p.has_gun:
			has_gun = true
		_btn_shoot.visible = show and has_gun
	if _btn_toggle:
		_btn_toggle.visible = true
		_btn_toggle.modulate.a = 0.9 if _controls_hidden else 0.55

## A round touch button. The visible disc and label are centred child nodes and
## the CircleShape2D hit area is centred on the same point and padded outward, so
## the whole comfortable circle (not just the icon) responds to a tap.
func _create_touch_button(action: String, pos: Vector2, radius: float, label_text: String) -> TouchScreenButton:
	var btn := TouchScreenButton.new()
	if action != "":
		btn.action = action
	btn.position = pos

	var shape := CircleShape2D.new()
	shape.radius = radius + 8.0
	btn.shape = shape

	var vis := Sprite2D.new()
	vis.texture = _create_circle_texture(radius, Color(1.0, 1.0, 1.0, 0.16))
	btn.add_child(vis)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size = Vector2(radius * 2.0, radius * 2.0)
	lbl.position = Vector2(-radius, -radius)
	lbl.add_theme_font_size_override("font_size", maxi(8, roundi(radius * 0.8)))
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	lbl.add_theme_constant_override("outline_size", 2)
	btn.add_child(lbl)

	# Smooth press feedback: brighten the disc and give a gentle pop.
	btn.pressed.connect(func():
		vis.modulate = Color(1.5, 1.5, 1.5, 1.0)
		var tw := create_tween()
		tw.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.06))
	btn.released.connect(func():
		vis.modulate = Color(1, 1, 1, 1)
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.14))

	add_child(btn)
	return btn

## A soft translucent disc with a slightly brighter rim, anti-aliased at the edge.
func _create_circle_texture(radius: float, color: Color) -> ImageTexture:
	var size := int(ceil(radius * 2.0))
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var dx := x - radius + 0.5
			var dy := y - radius + 0.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist > radius:
				continue
			var a := color.a
			# Feather the outer edge for a smooth silhouette.
			if dist > radius - 1.5:
				a *= clampf((radius - dist) / 1.5, 0.0, 1.0)
			# Brighter ring just inside the rim.
			elif dist > radius - 2.8:
				a = clampf(color.a * 2.6, 0.0, 1.0)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	return ImageTexture.create_from_image(img)
