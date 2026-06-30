class_name RoadMap
extends CanvasLayer
## Scrollable world-by-world roadmap. Each world is a row: a themed emblem +
## name + progress, followed by its level "stops" (cleared ✓ / current / locked,
## with star/gem pips). Scrolls vertically through all worlds; any unlocked stop
## is replayable. Up/Down change world, Left/Right change level, Enter plays,
## mouse-wheel/click also work.

var _list: _List
var _footer: Label

func _ready() -> void:
	layer = 20
	add_child(UIKit.make_backdrop())

	var title := UIKit.make_title("ROADMAP", 15)
	title.position = Vector2(0, 2)
	title.size = Vector2(320, 16)
	add_child(title)

	var prog := UIKit.make_label(_progress_text(), 7, UIKit.DIM)
	prog.position = Vector2(0, 19)
	prog.size = Vector2(320, 10)
	add_child(prog)

	_list = _List.new()
	_list.position = Vector2(2, 30)
	_list.size = Vector2(316, 120)
	_list.clip_contents = true
	_list.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_list)

	_footer = UIKit.make_label("", 8, UIKit.TEXT)
	_footer.position = Vector2(0, 152)
	_footer.size = Vector2(320, 10)
	add_child(_footer)

	var back := UIKit.make_button("Back", 70, 14)
	back.position = Vector2(4, 164)
	back.pressed.connect(Game.goto_main_menu)
	add_child(back)

	var hint := UIKit.make_label("↕ world   ↔ level   Enter play", 7, UIKit.DIM)
	hint.position = Vector2(80, 166)
	hint.size = Vector2(232, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)

func _process(_delta: float) -> void:
	if _list and _footer:
		_footer.text = _list.selected_label()

func _progress_text() -> String:
	var done := 0
	for k in Game.completed:
		if Game.completed[k]:
			done += 1
	return "%d / %d cleared    ★ %d    ◆ %d" % [done, Game.level_count(), Game.stars, Game.gems]


## The scrolling list of world rows. Drawn manually (clipped to its rect) so the
## map can have real emblems and connecting paths rather than plain buttons.
class _List extends Control:
	const ROW_H := 30.0
	const NODE_X0 := 150.0
	const NODE_DX := 30.0
	const NODE_R := 6.5

	var _groups: Array[Dictionary] = []
	var _wsel := 0
	var _lsel := 0
	var _scroll := 0.0
	var _t := 0.0
	var _font: Font

	func _ready() -> void:
		_font = ThemeDB.fallback_font
		var levels := Game.levels()
		for wi in Game.world_count():
			var inw := levels.filter(func(e): return int(e.get("world", -1)) == wi)
			if inw.is_empty():
				continue
			_groups.append({
				"wi": wi,
				"name": String(inw[0].get("world_name", "World %d" % (wi + 1))),
				"theme": inw[0].get("theme", {}),
				"levels": inw,
			})
		_select_furthest()
		set_process_unhandled_input(true)

	func _select_furthest() -> void:
		for gi in _groups.size():
			var lv: Array = _groups[gi]["levels"]
			for li in lv.size():
				if int(lv[li].get("flat_index", 0)) == Game.max_level:
					_wsel = gi
					_lsel = li
					return

	func selected_label() -> String:
		if _groups.is_empty():
			return ""
		var g: Dictionary = _groups[_wsel]
		var e: Dictionary = g["levels"][_lsel]
		var idx := int(e.get("flat_index", 0))
		if idx > Game.max_level:
			return "%s — 🔒 Locked" % g["name"]
		var bt := Game.best_time(idx)
		var ts := "  ·  %.2fs" % bt if bt > 0.0 else ""
		return "%s — %s%s" % [g["name"], String(e.get("name", "")), ts]

	# --- Input ---

	func _unhandled_input(_e: InputEvent) -> void:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
			get_viewport().set_input_as_handled()
			Game.goto_main_menu()
		elif Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("ui_up"):
			_move_world(-1)
		elif Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("ui_down"):
			_move_world(1)
		elif Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
			_lsel = maxi(0, _lsel - 1)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
			_lsel = mini((_groups[_wsel]["levels"] as Array).size() - 1, _lsel + 1)
		elif Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			_play()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			if e.button_index == MOUSE_BUTTON_WHEEL_UP:
				_move_world(-1)
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_move_world(1)
			elif e.button_index == MOUSE_BUTTON_LEFT:
				_click(e.position)

	func _move_world(step: int) -> void:
		_wsel = clampi(_wsel + step, 0, _groups.size() - 1)
		_lsel = clampi(_lsel, 0, (_groups[_wsel]["levels"] as Array).size() - 1)

	func _click(pos: Vector2) -> void:
		var row := int((pos.y + _scroll) / ROW_H)
		if row < 0 or row >= _groups.size():
			return
		var lv: Array = _groups[row]["levels"]
		for j in lv.size():
			var cx := NODE_X0 + j * NODE_DX
			var cy := row * ROW_H + ROW_H * 0.5 - _scroll
			if pos.distance_to(Vector2(cx, cy)) < NODE_R + 2.0:
				_wsel = row
				_lsel = j
				_play()
				return

	func _play() -> void:
		var idx := int(_groups[_wsel]["levels"][_lsel].get("flat_index", 0))
		if idx <= Game.max_level:
			Game.start_at(idx)

	# --- Drawing ---

	func _process(delta: float) -> void:
		_t += delta
		var content := _groups.size() * ROW_H
		var target := clampf(_wsel * ROW_H - size.y * 0.5 + ROW_H * 0.5, 0.0, maxf(0.0, content - size.y))
		_scroll = lerp(_scroll, target, clampf(12.0 * delta, 0.0, 1.0))
		queue_redraw()

	func _draw() -> void:
		for gi in _groups.size():
			var y := gi * ROW_H - _scroll
			if y + ROW_H < 0.0 or y > size.y:
				continue
			_draw_row(gi, y)

	func _draw_row(gi: int, y: float) -> void:
		var g: Dictionary = _groups[gi]
		var theme: Dictionary = g["theme"]
		var lv: Array = g["levels"]
		var first_idx := int(lv[0].get("flat_index", 0))
		var world_unlocked := first_idx <= Game.max_level
		var cy := y + ROW_H * 0.5

		# Selected world: soft highlight band.
		if gi == _wsel:
			draw_rect(Rect2(0, y + 1, size.x, ROW_H - 2), Color(1, 1, 1, 0.06))

		# Emblem.
		_draw_emblem(g["wi"], theme, Vector2(18, cy), world_unlocked)

		# Name + progress.
		var name_col: Color = UIKit.TEXT if world_unlocked else UIKit.DIM
		_text(g["name"], Vector2(32, cy - 3), 8, name_col)
		var cleared := lv.filter(func(e): return Game.completed.get(int(e.get("flat_index", -1)), false)).size()
		_text("%d/%d" % [cleared, lv.size()], Vector2(32, cy + 7), 7, UIKit.DIM)

		# Connecting path under the nodes.
		if lv.size() > 1:
			draw_line(Vector2(NODE_X0, cy), Vector2(NODE_X0 + (lv.size() - 1) * NODE_DX, cy),
				Color(1, 1, 1, 0.16), 2.0)

		# Level stops.
		for j in lv.size():
			_draw_node(lv[j], Vector2(NODE_X0 + j * NODE_DX, cy), theme, gi == _wsel and j == _lsel)

	func _draw_node(e: Dictionary, p: Vector2, theme: Dictionary, selected: bool) -> void:
		var idx := int(e.get("flat_index", 0))
		var ring: Color = theme.get("accent", UIKit.ACCENT)
		var unlocked := idx <= Game.max_level
		var cleared: bool = Game.completed.get(idx, false)

		if selected:
			var pulse := NODE_R + 3.0 + sin(_t * 6.0)
			draw_arc(p, pulse, 0.0, TAU, 20, Color(1, 1, 1, 0.9), 1.3)

		if not unlocked:
			draw_circle(p, NODE_R, Color(0.16, 0.16, 0.22))
			draw_arc(p, NODE_R, 0.0, TAU, 16, Color(0.4, 0.4, 0.5), 1.2)
			_text("🔒", p + Vector2(0, 2.5), 7, Color(0.6, 0.62, 0.72), true)
			return

		draw_circle(p, NODE_R, ring.darkened(0.5) if not cleared else ring.darkened(0.1))
		draw_arc(p, NODE_R, 0.0, TAU, 20, ring, 1.4)
		if cleared:
			_text("✓", p + Vector2(0, 3.0), 9, Color(1, 1, 1), true)
		else:
			_text(str(idx + 1), p + Vector2(0, 2.6), 7, UIKit.TEXT, true)

		if Game.stars_found.get(idx, false):
			draw_circle(p + Vector2(-3, -8), 1.5, Color(0.5, 0.92, 1.0))
		if Game.gems_found.get(idx, false):
			draw_circle(p + Vector2(3, -8), 1.5, Color(0.55, 0.95, 1.0))

	func _draw_emblem(wi: int, theme: Dictionary, c: Vector2, unlocked: bool) -> void:
		var tile: Color = theme.get("tile", Color(0.4, 0.4, 0.5))
		var accent: Color = theme.get("accent", Color.WHITE)
		if not unlocked:
			tile = tile.darkened(0.5)
			accent = accent.darkened(0.4)
		draw_circle(c, 10.0, tile.darkened(0.1))
		draw_arc(c, 10.0, 0.0, TAU, 28, accent, 1.5)
		_draw_motif(wi, c, unlocked)
		if not unlocked:
			_text("🔒", c + Vector2(0, 3.0), 8, Color(0.7, 0.72, 0.82), true)

	## A tiny distinctive glyph per world, drawn from primitives.
	func _draw_motif(wi: int, c: Vector2, unlocked: bool) -> void:
		if not unlocked:
			return
		var w := Color(1, 1, 1, 0.92)
		match wi:
			0: # Meadows — leaf
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 1), c + Vector2(0, 5), c + Vector2(-4, 1)]), Color(0.7, 1.0, 0.6))
			1: # Caverns — crystal
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(3, 0), c + Vector2(0, 5), c + Vector2(-3, 0)]), Color(1.0, 0.7, 0.95))
			2: # Gravity Lab — swirl ring
				draw_arc(c, 4.5, 0.4, TAU * 0.85, 16, w, 1.5)
			3: # Devil — horns
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 3), c + Vector2(-2, -4), c + Vector2(0, 3)]), Color(1.0, 0.5, 0.4))
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, 3), c + Vector2(2, -4), c + Vector2(4, 3)]), Color(1.0, 0.5, 0.4))
			4: # Forest — tree
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 2), c + Vector2(-4, 2)]), Color(0.5, 0.9, 0.4))
				draw_rect(Rect2(c.x - 1, c.y + 2, 2, 3), Color(0.5, 0.35, 0.2))
			5: # Desert — sun
				draw_circle(c, 3.0, Color(1.0, 0.85, 0.3))
				for k in 6:
					var a := k * TAU / 6.0
					draw_line(c + Vector2(cos(a), sin(a)) * 4.0, c + Vector2(cos(a), sin(a)) * 6.0, Color(1.0, 0.85, 0.3), 1.0)
			6: # Sea — waves
				draw_arc(c + Vector2(0, -1), 3.0, PI, TAU, 8, Color(0.6, 0.95, 1.0), 1.3)
				draw_arc(c + Vector2(0, 3), 3.0, PI, TAU, 8, Color(0.6, 0.95, 1.0), 1.3)
			7: # Underground — rocks
				draw_circle(c + Vector2(-2, 1), 2.4, Color(0.8, 0.7, 0.6))
				draw_circle(c + Vector2(2, -1), 2.0, Color(0.9, 0.8, 0.7))
			8: # Space — star
				_star(c, 5.0, 2.0, Color(1.0, 0.95, 0.6))
			9: # Ice — snowflake
				for k in 3:
					var a := k * PI / 3.0
					draw_line(c - Vector2(cos(a), sin(a)) * 5.0, c + Vector2(cos(a), sin(a)) * 5.0, w, 1.0)
			10: # Neon — bolt
				draw_colored_polygon(PackedVector2Array([c + Vector2(1, -5), c + Vector2(-2, 1), c + Vector2(0, 1), c + Vector2(-1, 5), c + Vector2(3, -2), c + Vector2(1, -2)]), Color(1.0, 0.4, 0.9))
			11: # Candy — lollipop
				draw_circle(c + Vector2(0, -2), 3.0, Color(1.0, 0.5, 0.7))
				draw_line(c + Vector2(0, 0), c + Vector2(0, 5), w, 1.0)
			12: # Haunted — ghost
				draw_circle(c + Vector2(0, -1), 3.5, w)
				draw_rect(Rect2(c.x - 3.5, c.y - 1, 7, 4), w)
				draw_circle(c + Vector2(-1.3, -1), 0.7, Color(0.2, 0.2, 0.3))
				draw_circle(c + Vector2(1.3, -1), 0.7, Color(0.2, 0.2, 0.3))
			13: # Volcano — flame
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(3, 4), c + Vector2(-3, 4)]), Color(1.0, 0.55, 0.2))
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -1), c + Vector2(1.6, 4), c + Vector2(-1.6, 4)]), Color(1.0, 0.85, 0.4))
			_:
				draw_circle(c, 3.0, w)

	func _star(c: Vector2, r: float, ri: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for k in 8:
			var a := k * PI / 4.0 - PI / 2.0
			var rr := r if k % 2 == 0 else ri
			pts.append(c + Vector2(cos(a), sin(a)) * rr)
		draw_colored_polygon(pts, col)

	func _text(s: String, center: Vector2, size_px: int, col: Color, centered := false) -> void:
		if _font == null:
			return
		var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
		var pos := center - Vector2(w * 0.5 if centered else 0.0, 0.0)
		draw_string(_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, col)
