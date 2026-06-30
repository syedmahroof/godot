class_name RoadMap
extends CanvasLayer
## A serpentine "world map" of every level: a winding path of node stops showing
## what's cleared (✓ + ★/◆), what's playable now, and what's still locked. Any
## unlocked stop is replayable. Drawn directly (no per-node buttons) with manual
## left/right selection plus mouse clicks, so the path can look like a real map.

func _ready() -> void:
	layer = 20
	add_child(UIKit.make_backdrop())
	var map := _Map.new()
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(map)

	var back := UIKit.make_button("Back", 70, 14)
	back.position = Vector2(6, 162)
	back.pressed.connect(Game.goto_main_menu)
	add_child(back)


## The interactive map surface.
class _Map extends Control:
	const COLS := 5

	var _pos: Array[Vector2] = []
	var _sel := 0
	var _t := 0.0
	var _font: Font

	func _ready() -> void:
		_font = ThemeDB.fallback_font
		_layout()
		_sel = clampi(Game.max_level, 0, Game.level_count() - 1)
		set_process_unhandled_input(true)

	func _layout() -> void:
		var n := Game.level_count()
		var rows := int(ceil(float(n) / COLS))
		var xs: Array[float] = []
		for c in COLS:
			xs.append(34.0 + c * (252.0 / float(COLS - 1)))
		var ys: Array[float] = []
		for r in rows:
			ys.append(50.0 + r * (96.0 / float(maxi(rows - 1, 1))))
		_pos.clear()
		for i in n:
			var r := i / COLS
			var c := i % COLS
			if r % 2 == 1:
				c = COLS - 1 - c       # serpentine: reverse odd rows
			_pos.append(Vector2(xs[c], ys[r]))

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _unhandled_input(_e: InputEvent) -> void:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
			get_viewport().set_input_as_handled()
			Game.goto_main_menu()
		elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
			_move(-1)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
			_move(1)
		elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
			_move(-COLS)
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
			_move(COLS)
		elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_play()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			for i in _pos.size():
				if e.position.distance_to(_pos[i]) < 12.0 and i <= Game.max_level:
					_sel = i
					_play()
					return

	func _move(step: int) -> void:
		var target := clampi(_sel + step, 0, Game.level_count() - 1)
		# Don't let the cursor land on a locked stop.
		_sel = mini(target, Game.max_level)

	func _play() -> void:
		if _sel <= Game.max_level:
			Game.start_at(_sel)

	func _draw() -> void:
		# Title + hint.
		_text("ROADMAP", Vector2(160, 18), 16, UIKit.GOLD, true)

		# Connecting path.
		if _pos.size() > 1:
			draw_polyline(PackedVector2Array(_pos), Color(1, 1, 1, 0.18), 3.0)

		var levels := Game.levels()
		for i in _pos.size():
			_draw_node(i, levels[i])

		# Selected level name.
		if _sel < levels.size():
			var e: Dictionary = levels[_sel]
			var nm: String = "%s — %s" % [e.get("world_name", ""), e.get("name", "")]
			_text(nm, Vector2(160, 158), 9, UIKit.TEXT, true)

	func _draw_node(i: int, e: Dictionary) -> void:
		var p: Vector2 = _pos[i]
		var theme: Dictionary = e.get("theme", {})
		var ring: Color = theme.get("accent", UIKit.ACCENT)
		var unlocked := i <= Game.max_level
		var cleared: bool = Game.completed.get(i, false)

		# Selection halo.
		if i == _sel:
			var pulse := 12.0 + 2.0 * sin(_t * 6.0)
			draw_arc(p, pulse, 0.0, TAU, 24, Color(1, 1, 1, 0.9), 1.5)

		if not unlocked:
			draw_circle(p, 9.0, Color(0.16, 0.16, 0.22))
			draw_arc(p, 9.0, 0.0, TAU, 20, Color(0.4, 0.4, 0.5), 1.5)
			_text("🔒", p + Vector2(0, 3), 9, Color(0.6, 0.62, 0.72), true)
			return

		# Body.
		draw_circle(p, 9.0, ring.darkened(0.5) if not cleared else ring.darkened(0.1))
		draw_arc(p, 9.0, 0.0, TAU, 24, ring, 1.6)
		if cleared:
			_text("✓", p + Vector2(0, 3.5), 11, Color(1, 1, 1), true)
		else:
			_text(str(i + 1), p + Vector2(0, 3.0), 8, UIKit.TEXT, true)

		# Collectible pips above the node.
		if Game.stars_found.get(i, false):
			draw_circle(p + Vector2(-4, -12), 1.8, Color(0.5, 0.92, 1.0))
		if Game.gems_found.get(i, false):
			draw_circle(p + Vector2(4, -12), 1.8, Color(0.55, 0.95, 1.0))

	func _text(s: String, center: Vector2, size: int, col: Color, centered := false) -> void:
		if _font == null:
			return
		var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos := center - Vector2(w * 0.5 if centered else 0.0, 0.0)
		draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
