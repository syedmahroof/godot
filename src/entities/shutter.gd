class_name Shutter
extends Area2D
## Umbral Vault. A drifting curtain of blinding fog. Not lethal by itself — while the
## player is inside it, it chokes the lantern down to almost nothing, so any Wisps,
## Gloomhounds or Lances hidden in the dark become deadly. A vision trap, not a blade.

var span := 26.0          # how far it drifts from its origin along the axis
var speed := 0.7
var axis := Vector2.RIGHT
var _origin := Vector2.ZERO
var _t := 0.0
var _shape: CollisionShape2D
var _inside := 0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_origin = position
	_t = randf() * TAU
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	_shape = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(16, 20)
	_shape.shape = r
	add_child(_shape)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _process(delta: float) -> void:
	_t += delta * speed
	position = _origin + axis * sin(_t) * span
	queue_redraw()

func _on_enter(b: Node) -> void:
	if b is Player:
		_inside += 1
		(b as Player).add_blind(1)

func _on_exit(b: Node) -> void:
	if b is Player and _inside > 0:
		_inside -= 1
		(b as Player).add_blind(-1)

func _draw() -> void:
	var puff := 1.0 + sin(_t * 3.0) * 0.08
	draw_circle(Vector2(0, 0), 11.0 * puff, Color(0.05, 0.04, 0.09, 0.8))
	draw_circle(Vector2(-4, -3), 7.0 * puff, Color(0.10, 0.09, 0.16, 0.7))
	draw_circle(Vector2(5, 2), 8.0 * puff, Color(0.08, 0.07, 0.13, 0.7))
	draw_circle(Vector2(2, -5), 6.0 * puff, Color(0.12, 0.10, 0.18, 0.6))
