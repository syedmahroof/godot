class_name TileFactory
## Builds the solid-block TileSet (texture + collision) entirely in code, so the
## project has zero binary asset dependencies and opens cleanly anywhere.

const TILE := 16

static func make_solid_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1) # world collides on layer 1
	ts.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = _make_texture()
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

static func _make_texture() -> ImageTexture:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var base := Color(0.18, 0.20, 0.28)
	var top := Color(0.30, 0.34, 0.46)
	img.fill(base)
	for x in TILE:
		img.set_pixel(x, 0, top)
		img.set_pixel(x, 1, top.darkened(0.12))
	for y in TILE:
		img.set_pixel(0, y, base.lightened(0.06))
		img.set_pixel(TILE - 1, y, base.darkened(0.22))
	return ImageTexture.create_from_image(img)
