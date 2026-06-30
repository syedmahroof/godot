class_name Badges
## Achievement definitions. Conditions are evaluated in Game._badge_condition()
## (keyed by id) so the data here stays plain and serialisable. Badges reward the
## "deeper and deeper" climb plus collecting and skill milestones.

static func list() -> Array[Dictionary]:
	return [
		{"id": "first_clear", "name": "Baby Steps", "desc": "Clear your first level"},
		{"id": "halfway", "name": "Halfway Down", "desc": "Reach the midpoint"},
		{"id": "w1", "name": "Meadow Master", "desc": "Clear Jelly Meadows"},
		{"id": "w2", "name": "Cavern Conqueror", "desc": "Clear Bubblegum Caverns"},
		{"id": "w3", "name": "Lab Legend", "desc": "Clear Gravity Lab"},
		{"id": "w4", "name": "Devil Tamer", "desc": "Clear Devil's Playground"},
		{"id": "rock_bottom", "name": "Rock Bottom", "desc": "Clear every level"},
		{"id": "stars5", "name": "Stargazer", "desc": "Collect 5 stars"},
		{"id": "starsall", "name": "Constellation", "desc": "Collect every star"},
		{"id": "gems4", "name": "Gem Hunter", "desc": "Collect 4 gems"},
		{"id": "flawless", "name": "Untouchable", "desc": "Clear a level without dying"},
		{"id": "combo10", "name": "Combo King", "desc": "Reach a x10 coin combo"},
		{"id": "deaths50", "name": "Persistent", "desc": "Die 50 times (oof)"},
	]

static func count() -> int:
	return list().size()

static func get_badge(id: String) -> Dictionary:
	for b in list():
		if b.get("id", "") == id:
			return b
	return {}
