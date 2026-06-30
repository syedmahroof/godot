extends Node2D
## Entry point. Hands the scene root to the Game singleton, which builds the
## HUD and loads the first level.

func _ready() -> void:
	Game.start(self)
