class_name ThemeBackground
extends CanvasLayer
## A smooth gradient sky with drifting, parallaxing soft orbs — themed per world.
## Sits behind the level (negative layer) and follows the camera with light
## parallax so each world reads as a deep, modern space instead of a flat wall.

var theme: Dictionary = {}

func _ready() -> void:
	layer = -10
	var sky := TextureRect.new()
	sky.texture = _gradient(
		theme.get("sky_top", Color(0.30, 0.50, 0.85)),
		theme.get("sky_bottom", Color(0.62, 0.80, 0.96)))
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	var orbs := _Orbs.new()
	orbs.tint = theme.get("accent", Color(1, 1, 1))
	orbs.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(orbs)

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
