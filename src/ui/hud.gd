class_name Hud
extends CanvasLayer
## Minimal in-code HUD: coins, deaths, run timer, level name, and toasts.

var _coins: Label
var _deaths: Label
var _time: Label
var _level: Label
var _toast: Label
var _toast_t := 0.0

func _ready() -> void:
	layer = 10
	_coins = _make(Vector2(4, 2))
	_deaths = _make(Vector2(4, 13))
	_time = _make(Vector2(4, 24))
	_level = _make(Vector2(4, 168))
	_toast = _make(Vector2(0, 72))
	_toast.size = Vector2(320, 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Game.hud_changed.connect(_refresh)
	Game.toast.connect(_show_toast)
	_refresh()

func _make(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 2)
	add_child(l)
	return l

func _process(delta: float) -> void:
	_time.text = "Time  %.2f" % Game.time
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t, 0.0, 1.0)
		if _toast_t <= 0.0:
			_toast.text = ""

func _refresh() -> void:
	_coins.text = "Coins  %d" % Game.run_coins
	_deaths.text = "Deaths %d" % Game.deaths
	_level.text = Game.current_level_name()

func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.0
	_toast.modulate.a = 1.0
