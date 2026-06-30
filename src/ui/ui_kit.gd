class_name UIKit
## Shared look-and-feel for every menu screen. Building Controls in code is a bit
## verbose, so the styling lives here once: a small palette plus factory helpers
## for titles, labels, buttons and panels. Designed for the 320x180 viewport.

# --- Palette ---
const BG := Color(0.06, 0.07, 0.11)
const BG_BOTTOM := Color(0.10, 0.08, 0.16)
const PANEL := Color(0.13, 0.14, 0.22, 0.94)
const PANEL_EDGE := Color(0.32, 0.34, 0.54)
const ACCENT := Color(0.62, 0.55, 0.95)
const GOLD := Color(1.0, 0.84, 0.25)
const TEXT := Color(0.93, 0.94, 1.0)
const DIM := Color(0.58, 0.60, 0.72)
const DANGER := Color(0.92, 0.42, 0.40)

## A vertical gradient backdrop that fills the whole screen.
static func make_backdrop() -> TextureRect:
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, BG)
	img.set_pixel(1, 0, BG)
	img.set_pixel(0, 1, BG_BOTTOM)
	img.set_pixel(1, 1, BG_BOTTOM)
	var tr := TextureRect.new()
	tr.texture = ImageTexture.create_from_image(img)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	return tr

## A translucent dim used behind pause/overlay menus.
static func make_dim() -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.04, 0.04, 0.07, 0.72)
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	return c

static func make_title(text: String, size := 22) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	return l

static func make_label(text: String, size := 9, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("outline_size", 2)
	return l

## A styled menu button. Hover/focus share the accent fill so keyboard and mouse
## navigation read the same.
static func make_button(text: String, width := 150, height := 16) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, height)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", BG)
	b.add_theme_color_override("font_focus_color", BG)
	b.add_theme_color_override("font_pressed_color", BG)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.46, 0.55))

	b.add_theme_stylebox_override("normal", _box(PANEL, PANEL_EDGE))
	b.add_theme_stylebox_override("hover", _box(ACCENT, ACCENT.lightened(0.2)))
	b.add_theme_stylebox_override("focus", _box(ACCENT, GOLD))
	b.add_theme_stylebox_override("pressed", _box(ACCENT.darkened(0.15), GOLD))
	b.add_theme_stylebox_override("disabled", _box(Color(0.10, 0.10, 0.15, 0.9), Color(0.2, 0.2, 0.28)))
	b.pressed.connect(func(): Audio.play("select"))
	return b

## A framed container box (used for panels / cards).
static func make_panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(PANEL, PANEL_EDGE, 4, 2))
	return p

static func _box(fill: Color, edge: Color, radius := 3, border := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	return s

## Centers a control node on screen within a CanvasLayer.
static func center(node: Control) -> void:
	node.set_anchors_preset(Control.PRESET_CENTER)
	node.grow_horizontal = Control.GROW_DIRECTION_BOTH
	node.grow_vertical = Control.GROW_DIRECTION_BOTH
