class_name ThemeBackground
extends CanvasLayer
## A smooth gradient sky with drifting, parallaxing soft orbs — themed per world.
## Sits behind the level (negative layer) and follows the camera with light
## parallax so each world reads as a deep, modern space instead of a flat wall.

var theme: Dictionary = {}
var scene := ""   # per-level scenery id (e.g. "kerala"), used by the India world

func _ready() -> void:
	layer = -10
	# Sky gradient from the world theme, optionally overridden per region so each
	# India level reads with its own light (cool alpine blue, hot desert amber…).
	var top: Color = theme.get("sky_top", Color(0.30, 0.50, 0.85))
	var bottom: Color = theme.get("sky_bottom", Color(0.62, 0.80, 0.96))
	match scene:
		"kerala":    top = Color(0.98, 0.60, 0.28); bottom = Color(0.97, 0.87, 0.58)
		"rajasthan": top = Color(0.97, 0.46, 0.16); bottom = Color(0.98, 0.78, 0.40)
		"himalaya":  top = Color(0.26, 0.40, 0.68); bottom = Color(0.88, 0.74, 0.74)
		"bengal":    top = Color(0.32, 0.26, 0.52); bottom = Color(0.96, 0.66, 0.52)

	var sky := TextureRect.new()
	sky.texture = _gradient(top, bottom)
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	var orbs := _Orbs.new()
	orbs.tint = theme.get("accent", Color(1, 1, 1))
	orbs.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(orbs)

	# Optional culturally-themed scenery layer (e.g. the India tribute world). The
	# per-level `scene` picks region-specific scenery (Kerala, Rajasthan, etc.).
	if String(theme.get("bg_style", "")) == "india":
		var scape := _IndiaScape.new()
		scape.scene = scene
		scape.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(scape)

func _gradient(top: Color, bottom: Color) -> ImageTexture:
	var h := 180
	var img := Image.create(2, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var c := top.lerp(bottom, float(y) / float(h - 1))
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)


## Big, low-alpha blobs that drift and parallax against the camera.
class _Orbs extends Control:
	var tint := Color.WHITE
	var _orbs: Array[Dictionary] = []
	var _t := 0.0
	var _camx := 0.0

	func _ready() -> void:
		for i in 6:
			_orbs.append({
				"x": randf() * 360.0,
				"y": randf() * 150.0,
				"r": randf_range(14.0, 34.0),
				"par": randf_range(0.06, 0.22),
			})

	func _process(delta: float) -> void:
		_t += delta
		var cam := get_viewport().get_camera_2d()
		if cam:
			_camx = cam.global_position.x
		queue_redraw()

	func _draw() -> void:
		for o in _orbs:
			var x: float = fposmod(o.x - _camx * o.par + sin(_t * 0.25 + o.r) * 5.0, 360.0) - 20.0
			var y: float = o.y + cos(_t * 0.2 + o.r) * 4.0
			var r: float = o.r
			draw_circle(Vector2(x, y), r, Color(tint.r, tint.g, tint.b, 0.10))
			draw_circle(Vector2(x, y), r * 0.55, Color(tint.r, tint.g, tint.b, 0.08))


## India tribute scenery, parallaxing gently behind the level and drawn purely
## from primitives (no assets). Each region gets its own tiled silhouette scene:
##   kerala    — coconut palms, green hills, a houseboat on the backwaters
##   rajasthan — sand dunes, a Hawa-Mahal-style palace, a camel
##   himalaya  — layered snow peaks with pine forest and a hilltop stupa
##   bengal    — the Howrah cantilever bridge, a domed memorial and river boats
class _IndiaScape extends Control:
	const PANEL_W := 170.0
	var scene := ""
	var _t := 0.0
	var _camx := 0.0

	func _process(delta: float) -> void:
		_t += delta
		var cam := get_viewport().get_camera_2d()
		if cam:
			_camx = cam.global_position.x
		queue_redraw()

	func _draw() -> void:
		# Warm setting sun shared by every region.
		var sun := Vector2(238, 40)
		draw_circle(sun, 24.0, Color(1.0, 0.78, 0.36, 0.22))
		draw_circle(sun, 16.0, Color(1.0, 0.84, 0.48, 0.40))
		draw_circle(sun, 11.0, Color(1.0, 0.90, 0.62, 0.55))

		# Tile the region scene across the screen with a slow parallax drift.
		var off := fposmod(-_camx * 0.12, PANEL_W)
		for k in range(-1, 3):
			var x0 := off + k * PANEL_W
			match scene:
				"kerala": _kerala(x0)
				"rajasthan": _rajasthan(x0)
				"himalaya": _himalaya(x0)
				"bengal": _bengal(x0)
				_: _monuments(x0)

	# --- South: Kerala backwaters ---
	func _kerala(x0: float) -> void:
		var gy := 150.0
		var g1 := Color(0.09, 0.20, 0.11, 0.60)
		var g2 := Color(0.12, 0.25, 0.14, 0.55)
		draw_rect(Rect2(x0 - 2, gy, PANEL_W + 4, 40), g1)
		# Rolling green hills poking above the waterline.
		draw_circle(Vector2(x0 + 34, gy + 16), 30.0, g2)
		draw_circle(Vector2(x0 + 118, gy + 18), 36.0, g2)
		# A traditional houseboat (kettuvallam).
		_houseboat(Vector2(x0 + 150, gy - 3), g1)
		# Groves of coconut palms.
		_palm(Vector2(x0 + 14, gy), g1)
		_palm(Vector2(x0 + 26, gy + 2), g1)
		_palm(Vector2(x0 + 70, gy - 1), g1)
		_palm(Vector2(x0 + 90, gy + 1), g1)
		# Backwater shimmer.
		for sx: float in [x0 + 40, x0 + 108, x0 + 132]:
			draw_line(Vector2(sx, gy + 30), Vector2(sx + 10, gy + 30), Color(0.5, 0.9, 0.85, 0.18), 1.0)

	# --- West: Rajasthan desert ---
	func _rajasthan(x0: float) -> void:
		var gy := 150.0
		var sand := Color(0.44, 0.25, 0.13, 0.5)
		var stone := Color(0.34, 0.16, 0.10, 0.62)
		var window := Color(0.20, 0.09, 0.06, 0.7)
		draw_rect(Rect2(x0 - 2, gy, PANEL_W + 4, 40), sand)
		# Dunes.
		draw_circle(Vector2(x0 + 46, gy + 22), 40.0, Color(0.50, 0.30, 0.16, 0.45))
		draw_circle(Vector2(x0 + 132, gy + 24), 46.0, sand)
		# Hawa-Mahal-style palace facade.
		var px := x0 + 82
		draw_rect(Rect2(px - 30, gy - 24, 60, 24), stone)
		for i in 7:
			draw_rect(Rect2(px - 30 + i * 9, gy - 28, 5, 4), stone)   # crenellations
		for r in 2:
			for c in 5:
				draw_rect(Rect2(px - 24 + c * 11, gy - 20 + r * 9, 5, 6), window)  # arched windows
		draw_circle(Vector2(px, gy - 27), 6.0, stone)
		draw_circle(Vector2(px - 20, gy - 26), 4.0, stone)
		draw_circle(Vector2(px + 20, gy - 26), 4.0, stone)
		# A camel plodding across the sand.
		_camel(Vector2(x0 + 22, gy), stone)

	# --- North: Himalayan heights ---
	func _himalaya(x0: float) -> void:
		var gy := 150.0
		var back := Color(0.52, 0.42, 0.54, 0.5)
		var front := Color(0.32, 0.26, 0.40, 0.62)
		var snow := Color(0.94, 0.95, 1.0, 0.75)
		var pine := Color(0.13, 0.22, 0.16, 0.62)
		draw_rect(Rect2(x0 - 2, gy, PANEL_W + 4, 40), front)
		# Distant range.
		_peak(x0 + 30, gy, 40, 48, back, snow)
		_peak(x0 + 92, gy, 52, 60, back, snow)
		_peak(x0 + 150, gy, 44, 52, back, snow)
		# Nearer, darker peaks.
		_peak(x0 + 62, gy, 30, 34, front, snow)
		_peak(x0 + 122, gy, 34, 38, front, snow)
		# A little hilltop stupa.
		draw_rect(Rect2(x0 + 20, gy - 12, 8, 12), front)
		draw_circle(Vector2(x0 + 24, gy - 14), 4.0, snow)
		# Pine forest along the base.
		for pxf: float in [x0 + 10, x0 + 40, x0 + 78, x0 + 104, x0 + 140, x0 + 158]:
			_pine(Vector2(pxf, gy), pine)

	# --- East: Bengal rivers ---
	func _bengal(x0: float) -> void:
		var gy := 150.0
		var ground := Color(0.16, 0.12, 0.20, 0.6)
		var steel := Color(0.22, 0.15, 0.22, 0.66)
		draw_rect(Rect2(x0 - 2, gy, PANEL_W + 4, 40), ground)
		# A domed memorial (Victoria Memorial) at the left.
		draw_rect(Rect2(x0 + 8, gy - 14, 18, 14), steel)
		draw_circle(Vector2(x0 + 17, gy - 16), 7.0, Color(0.42, 0.30, 0.36, 0.6))
		draw_line(Vector2(x0 + 17, gy - 22), Vector2(x0 + 17, gy - 26), steel, 1.0)
		# The Howrah cantilever bridge.
		var bx0 := x0 + 44.0
		var bx1 := x0 + 120.0
		var ty := gy - 32.0
		var mid := (bx0 + bx1) * 0.5
		draw_rect(Rect2(bx0 - 3, ty, 6, 32), steel)
		draw_rect(Rect2(bx1 - 3, ty, 6, 32), steel)
		draw_rect(Rect2(bx0 - 20, gy - 6, (bx1 - bx0) + 40, 2), steel)   # deck
		draw_line(Vector2(bx0, ty), Vector2(mid, gy - 16), steel, 1.4)
		draw_line(Vector2(bx1, ty), Vector2(mid, gy - 16), steel, 1.4)
		draw_line(Vector2(bx0, ty), Vector2(bx0 - 20, gy - 6), steel, 1.2)
		draw_line(Vector2(bx1, ty), Vector2(bx1 + 20, gy - 6), steel, 1.2)
		draw_line(Vector2(bx0, ty), Vector2(bx0, gy - 6), steel, 1.0)
		draw_line(Vector2(bx1, ty), Vector2(bx1, gy - 6), steel, 1.0)
		# A couple of river boats.
		_boat(Vector2(x0 + 150, gy + 4), steel)
		_boat(Vector2(x0 + 96, gy + 8), steel)

	# --- Shared building blocks ---

	func _palm(base: Vector2, col: Color) -> void:
		var top := base + Vector2(-3.0, -17.0)
		draw_line(base, top, col, 2.0)
		for da: float in [-1.3, -0.7, -0.1, 0.5, 1.1]:
			var ang := -PI * 0.5 + da
			draw_line(top, top + Vector2(cos(ang), sin(ang)) * 9.0, col, 1.4)

	func _houseboat(p: Vector2, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-15, 0), p + Vector2(15, 0), p + Vector2(11, 5), p + Vector2(-11, 5)]), col)  # hull
		draw_rect(Rect2(p.x - 10, p.y - 5, 20, 5), col)                                               # cabin
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-11, -5), p + Vector2(11, -5), p + Vector2(0, -11)]), col)                    # thatched roof

	func _camel(p: Vector2, col: Color) -> void:
		draw_rect(Rect2(p.x - 8, p.y - 6, 16, 4), col)                 # body
		draw_circle(p + Vector2(-2.5, -7), 3.0, col)                  # front hump
		draw_circle(p + Vector2(3, -7), 3.0, col)                     # rear hump
		draw_line(p + Vector2(8, -5), p + Vector2(12, -12), col, 2.0) # neck
		draw_circle(p + Vector2(12, -12), 1.8, col)                   # head
		for lx: float in [-6, -2, 3, 7]:
			draw_line(p + Vector2(lx, -2), p + Vector2(lx, 2), col, 1.2)  # legs

	func _peak(cx: float, gy: float, halfw: float, h: float, col: Color, snow: Color) -> void:
		var apex := Vector2(cx, gy - h)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - halfw, gy), apex, Vector2(cx + halfw, gy)]), col)
		var cap := h * 0.32
		var slope := halfw * (cap / h)
		draw_colored_polygon(PackedVector2Array([
			apex, Vector2(cx - slope, gy - h + cap), Vector2(cx + slope, gy - h + cap)]), snow)

	func _pine(base: Vector2, col: Color) -> void:
		draw_rect(Rect2(base.x - 0.6, base.y - 2, 1.2, 2), col)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-3, -2), base + Vector2(3, -2), base + Vector2(0, -8)]), col)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-2.4, -5), base + Vector2(2.4, -5), base + Vector2(0, -10)]), col)

	func _boat(p: Vector2, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(-8, 0), p + Vector2(8, 0), p + Vector2(5, 4), p + Vector2(-5, 4)]), col)  # hull
		draw_line(p, p + Vector2(0, -10), col, 1.0)                                               # mast
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -10), p + Vector2(0, -1), p + Vector2(7, -3)]), col)                   # sail

	# Fallback: the original mixed monument skyline.
	func _monuments(x0: float) -> void:
		var gy := 150.0
		var col := Color(0.30, 0.11, 0.13, 0.62)
		var dome := Color(0.55, 0.22, 0.24, 0.62)
		draw_rect(Rect2(x0 - 2, gy, PANEL_W + 4, 40), col)
		var gx := x0 + 20.0
		for i in 4:
			var wdt := 18.0 - i * 3.2
			draw_rect(Rect2(gx - wdt * 0.5, gy - 7.0 - i * 7.0, wdt, 7.0), col)
		draw_colored_polygon(PackedVector2Array([
			Vector2(gx - 5, gy - 35), Vector2(gx + 5, gy - 35), Vector2(gx, gy - 42)]), col)
		var tx := x0 + 84.0
		for mx: float in [tx - 24.0, tx + 24.0]:
			draw_rect(Rect2(mx - 2, gy - 34, 4, 34), col)
			draw_circle(Vector2(mx, gy - 35), 3.0, dome)
		draw_rect(Rect2(tx - 16, gy - 16, 32, 16), col)
		draw_circle(Vector2(tx, gy - 18), 10.0, dome)
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx - 8, gy - 22), Vector2(tx + 8, gy - 22), Vector2(tx, gy - 34)]), dome)
		_palm(Vector2(x0 + 134.0, gy), col)
