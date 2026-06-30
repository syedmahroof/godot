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
	source.texture = _make_texture(theme)
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

static func _make_texture(theme: Dictionary) -> ImageTexture:
	var tint: Color = theme.get("tile", Color(0.22, 0.50, 0.34))
	var style: String = theme.get("tile_style", "default")
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	
	match style:
		"meadow":
			# Grassy turf with dirt base
			var dirt := tint.darkened(0.15)
			var grass: Color = theme.get("accent", Color(0.5, 0.8, 0.3))
			img.fill(dirt)
			# Grass top border
			for x in TILE:
				img.set_pixel(x, 0, grass.lightened(0.1))
				img.set_pixel(x, 1, grass)
				img.set_pixel(x, 2, grass.darkened(0.15))
			# Grass details
			for x in TILE:
				if x % 3 == 0:
					img.set_pixel(x, 3, grass.darkened(0.3))
				img.set_pixel(0, TILE - 1, dirt.darkened(0.3))
				img.set_pixel(TILE - 1, TILE - 1, dirt.darkened(0.3))
		"caverns":
			# Rocky cracked stone
			var base := tint.darkened(0.1)
			var crack := tint.darkened(0.4)
			var highlight := tint.lightened(0.15)
			img.fill(base)
			for x in TILE:
				img.set_pixel(x, 0, highlight)
				img.set_pixel(x, TILE - 1, crack)
			for y in TILE:
				img.set_pixel(0, y, highlight)
				img.set_pixel(TILE - 1, y, crack)
			img.set_pixel(4, 4, crack)
			img.set_pixel(5, 5, crack)
			img.set_pixel(10, 11, crack)
			img.set_pixel(11, 10, crack)
			img.set_pixel(12, 11, highlight)
		"lab":
			# Glowing grid sci-fi panels
			var base := tint.darkened(0.2)
			var neon: Color = theme.get("accent", Color(0.0, 1.0, 0.8))
			img.fill(base)
			for x in TILE:
				img.set_pixel(x, 0, neon)
				img.set_pixel(x, TILE - 1, neon.darkened(0.3))
			for y in TILE:
				img.set_pixel(0, y, neon)
				img.set_pixel(TILE - 1, y, neon.darkened(0.3))
			img.set_pixel(TILE / 2, TILE / 2, neon)
		"forest":
			# Wood bark with mossy spots
			var wood := tint.darkened(0.2)
			var moss := Color(0.2, 0.45, 0.22)
			img.fill(wood)
			for x in TILE:
				img.set_pixel(x, 0, moss)
				img.set_pixel(x, 1, moss.darkened(0.15))
			img.set_pixel(4, 4, wood.darkened(0.4))
			img.set_pixel(4, 5, wood.darkened(0.4))
			img.set_pixel(10, 8, wood.darkened(0.4))
			img.set_pixel(10, 9, wood.darkened(0.4))
		"dunes":
			# Wave-cresting desert sand dunes
			var base := tint.darkened(0.1)
			var highlight := tint.lightened(0.2)
			var shadow := tint.darkened(0.3)
			img.fill(base)
			for x in TILE:
				var crest_y = int(1.0 + sin(x * PI / 8.0))
				for y in crest_y + 1:
					img.set_pixel(x, y, highlight)
				img.set_pixel(x, crest_y + 1, base)
				img.set_pixel(x, TILE - 1, shadow)
		"ice":
			# Slick ice blocks with highlight shines
			var base := tint.lightened(0.1)
			var glare := Color(1.0, 1.0, 1.0, 0.8)
			img.fill(base)
			for i in range(2, 8):
				img.set_pixel(i, i, glare)
			var border := tint.darkened(0.2)
			for x in TILE:
				img.set_pixel(x, 0, border)
				img.set_pixel(x, TILE - 1, border)
			for y in TILE:
				img.set_pixel(0, y, border)
				img.set_pixel(TILE - 1, y, border)
		"depths":
			# Sunken deep-sea blocks
			var base := tint.darkened(0.2)
			var highlight := tint.lightened(0.15)
			var shadow := tint.darkened(0.4)
			img.fill(base)
			for x in TILE:
				img.set_pixel(x, 0, highlight)
				img.set_pixel(x, TILE - 1, shadow)
			for y in TILE:
				img.set_pixel(0, y, highlight)
				img.set_pixel(TILE - 1, y, shadow)
			img.set_pixel(3, 5, highlight)
			img.set_pixel(11, 12, highlight)
		_:
			# Default standard rounded lit blocks
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
