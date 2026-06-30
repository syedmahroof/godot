class_name Avatars
## Selectable player avatars. Each is pure data (colours + a shape hint + an
## optional accent "hat"); PlayerSkin reads the active entry and draws it, so no
## image assets are needed. Later avatars are gated behind collected stars to
## give the secret stars a purpose.

## Returns the avatar table. Built in a function because Color constructors are
## not constant expressions, so this can't be a plain `const`.
static func list() -> Array[Dictionary]:
	return [
		{"name": "Dave",   "body": Color(0.96, 0.78, 0.25), "dash": Color(0.45, 0.85, 1.0), "shape": "block", "hat": Color(0, 0, 0, 0), "cost": 0},
		{"name": "Mint",   "body": Color(0.40, 0.90, 0.62), "dash": Color(1.0, 0.85, 0.45), "shape": "round", "hat": Color(0, 0, 0, 0), "cost": 0},
		{"name": "Rosa",   "body": Color(0.95, 0.45, 0.62), "dash": Color(0.55, 0.95, 1.0), "shape": "block", "hat": Color(0.98, 0.85, 0.35), "cost": 1},
		{"name": "Sky",    "body": Color(0.42, 0.66, 0.98), "dash": Color(1.0, 0.95, 0.6),  "shape": "tall",  "hat": Color(0, 0, 0, 0), "cost": 2},
		{"name": "Ember",  "body": Color(0.98, 0.50, 0.28), "dash": Color(0.6, 0.9, 1.0),   "shape": "block", "hat": Color(0.95, 0.95, 1.0), "cost": 4},
		{"name": "Void",   "body": Color(0.30, 0.28, 0.42), "dash": Color(0.85, 0.55, 1.0), "shape": "tall",  "hat": Color(0.62, 0.55, 0.95), "cost": 6},
		{"name": "Gold",   "body": Color(1.0, 0.86, 0.30),  "dash": Color(1.0, 1.0, 0.8),   "shape": "round", "hat": Color(1.0, 0.7, 0.15), "cost": 9},
	]

static func count() -> int:
	return list().size()

static func get_avatar(index: int) -> Dictionary:
	var l := list()
	return l[clampi(index, 0, l.size() - 1)]

static func is_unlocked(index: int, stars: int) -> bool:
	return stars >= int(get_avatar(index).get("cost", 0))
