class_name TileFactory
## Builds the solid-block TileSet (texture + collision) entirely in code, so the
## project has zero binary asset dependencies and opens cleanly anywhere.

const TILE := 16

static func make_solid_tileset(theme: Dictionary = {}) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1) # world collides on layer 1
	ts.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = _make_texture(theme.get("tile", Color(0.22, 0.50, 0.34)))
	source.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(source, 0)
	source.create_tile(Vector2i.ZERO)

	var data := source.get_tile_data(Vector2i.ZERO, 0)
	data.add_collision_polygon(0)
	var h := TILE / 2.0
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)
	]))
	return ts

static func _make_texture(tint: Color) -> ImageTexture:
	# A soft, slightly rounded-looking block tinted to the world's theme — a
	# brighter lip on top and a darker base give it a modern, lit feel.
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var base := tint.darkened(0.25)
	var top := tint.lightened(0.18)
	img.fill(base)
	for x in TILE:
		img.set_pixel(x, 0, top.lightened(0.1))
		img.set_pixel(x, 1, top)
		img.set_pixel(x, 2, tint)
	for y in TILE:
		img.set_pixel(0, y, base.lightened(0.10))
		img.set_pixel(TILE - 1, y, base.darkened(0.25))
		img.set_pixel(y, TILE - 1, base.darkened(0.30) if y < TILE else base)
	return ImageTexture.create_from_image(img)
