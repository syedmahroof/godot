class_name Level
extends Node2D
## Parses an ASCII grid (see levels.gd) into a tilemap + entities, then spawns
## the player and a following camera. Self-contained: freeing the Level frees
## everything in it, which is what makes the instant-respawn rebuild cheap.
##
## Legend:
##   #  solid tile      P  player spawn    E  exit door
##   C  coin            S  secret star     ^  spikes (hazard)
##   K  checkpoint      X  crumbling platform

var data: Dictionary = {}
var spawn_point := Vector2.ZERO
var player: Player
var camera: GameCamera

var _cols := 0
var _rows := 0

func _ready() -> void:
	if not data.is_empty():
		build()

func build() -> void:
	var grid: Array = data.get("grid", [])
	_rows = grid.size()
	_cols = 0
	for line in grid:
		_cols = maxi(_cols, line.length())

	var theme: Dictionary = data.get("theme", {})

	# Themed parallax sky behind everything.
	var bg := ThemeBackground.new()
	bg.theme = theme
	bg.scene = String(data.get("bg_scene", ""))
	add_child(bg)

	var t := TileFactory.TILE
	var layer := TileMapLayer.new()
	layer.tile_set = TileFactory.make_solid_tileset(theme)
	add_child(layer)

	for row in _rows:
		var line: String = grid[row]
		for col in line.length():
			var ch := line[col]
			var center := Vector2(col * t + t / 2.0, row * t + t / 2.0)
			match ch:
				"#":
					layer.set_cell(Vector2i(col, row), 0, Vector2i.ZERO)
				"P":
					spawn_point = center
				"C":
					_add(Coin.new(), center)
				"S":
					_add(Star.new(), center)
				"^":
					_add(Spike.new(), center)
				"K":
					_add(Checkpoint.new(), center)
				"E":
					_add(Exit.new(), center)
				"X":
					_add(Crumble.new(), center)
				"O":
					_add(Spring.new(), center)
				"G":
					_add(Gem.new(), center)
				"B":
					_add(Enemy.new(), center)
				"@":
					_add(GravPortal.new(), center)
				"-":
					var hp := MovingPlatform.new()
					hp.axis = Vector2.RIGHT
					_add(hp, center)
				"|":
					var vp := MovingPlatform.new()
					vp.axis = Vector2.DOWN
					_add(vp, center)
				"v":
					_add(TrapSpike.new(), center)
				"f":
					var ff := FakeFloor.new()
					ff.color = theme.get("tile", Color(0.5, 0.2, 0.2))
					_add(ff, center)
				"!":
					var fb := FallingBlock.new()
					fb.color = theme.get("tile", Color(0.5, 0.2, 0.2))
					_add(fb, center)
				"?":
					_add(FakeExit.new(), center)
				"~":
					var w := Water.new()
					w.tint = theme.get("accent", Color(0.25, 0.55, 0.9))
					_add(w, center)
				"L":
					_add(Hazard.new(), center)
				"M":
					var fl := Flyer.new()
					fl.tint = theme.get("accent", Color(0.95, 0.4, 0.5))
					_add(fl, center)
				"s":
					var sp := Spider.new()
					sp.tint = theme.get("accent", Color(0.9, 0.2, 0.4))
					_add(sp, center)
				"=":
					_add(Sawblade.new(), center)
				"y":
					_add(Pendulum.new(), center)
				"x":
					_add(Crusher.new(), center)
				"j":
					_add(FlameJet.new(), center)
				"R":
					var cg := Charger.new()
					cg.tint = theme.get("accent", Color(1.0, 0.55, 0.3))
					_add(cg, center)
				"A":
					_add(Armored.new(), center)
				"T":
					var tu := Turret.new()
					tu.tint = theme.get("accent", Color(0.9, 0.4, 0.85))
					_add(tu, center)
				"W":
					var db := DiveBomber.new()
					db.tint = theme.get("accent", Color(0.72, 0.86, 1.0))
					_add(db, center)
				"m":
					_add(Mimic.new(), center)
				"g":
					var gh := Ghost.new()
					gh.tint = theme.get("accent", Color(0.72, 0.96, 0.76))
					_add(gh, center)
				"F":
					var pf := Pufferfish.new()
					pf.tint = theme.get("accent", Color(0.5, 0.9, 1.0))
					_add(pf, center)
				"Z":
					var sz := Splitter.new()
					sz.tint = theme.get("accent", Color(0.6, 0.95, 0.55))
					_add(sz, center)
				"Y":
					var bo := Boss.new()
					bo.tint = theme.get("accent", Color(1.0, 0.4, 0.4))
					_add(bo, center)
				"J":
					_add(JetpackPickup.new(), center)
				"U":
					_add(GunPickup.new(), center)
				"H":
					_add(HelmetPickup.new(), center)

	player = Player.new()
	player.position = spawn_point
	add_child(player)

	camera = GameCamera.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _cols * t
	camera.limit_bottom = _rows * t
	player.add_child(camera)
	camera.make_current()

	player.landed.connect(_on_player_landed)
	player.died.connect(_on_player_died)

func _add(node: Node2D, pos: Vector2) -> void:
	node.position = pos
	add_child(node)

func _on_player_landed(strength: float) -> void:
	if strength > 0.6:
		camera.shake(2.5)

func _on_player_died() -> void:
	camera.shake(6.0)

func _physics_process(_delta: float) -> void:
	# Falling out of the world is fatal.
	if player and is_instance_valid(player) and not player.dead:
		if player.global_position.y > (_rows + 3) * TileFactory.TILE:
			player.die()
