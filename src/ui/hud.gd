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
	_level.text = "%s — %s" % [world, Game.current_level_name()] if world != "" else Game.current_level_name()

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
