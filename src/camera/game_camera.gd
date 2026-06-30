class_name GameCamera
extends Camera2D
## Smooth-follow camera with decaying screen shake.

var _shake := 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 9.0
	ignore_rotation = true

func shake(amount: float) -> void:
	if not Game.screen_shake:
		return
	_shake = maxf(_shake, amount)

func _process(delta: float) -> void:
	if _shake > 0.0:
		offset = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
		_shake = move_toward(_shake, 0.0, delta * 22.0)
	else:
		offset = Vector2.ZERO
