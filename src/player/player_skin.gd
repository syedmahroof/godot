class_name PlayerSkin
extends Node2D
## Draws the player and handles squash & stretch. Kept separate so scaling the
## visual never touches the collision shape. The actual look comes from the
## active avatar (see Avatars), drawn by the shared draw_avatar() helper so the
## menu preview and the in-game character stay identical.

var _scale := Vector2.ONE

func squash(s: Vector2) -> void:
	_scale = s

func _process(delta: float) -> void:
	_scale = _scale.lerp(Vector2.ONE, clampf(14.0 * delta, 0.0, 1.0))
	scale = _scale
	queue_redraw()

func _draw() -> void:
	var p := get_parent() as Player
	var facing := p.facing if p else 1
	var dashing := p != null and p._dash_time > 0.0
	draw_avatar(self, Avatars.get_avatar(Game.avatar_index), facing, dashing)

	# Tool overlays so the held gear reads at a glance.
	if p:
		if p.shielded:
			draw_arc(Vector2(0, -5), 9.0, PI, TAU, 16, Color(0.6, 0.9, 1.0, 0.9), 1.5)
		if p.has_jetpack:
			draw_rect(Rect2(-7.5, -3, 2.5, 9), Color(0.85, 0.5, 0.3))
		if p.has_gun:
			draw_line(Vector2(3.0 * facing, 0), Vector2(9.0 * facing, 0), Color(0.2, 0.2, 0.28), 2.0)

## Draws an avatar centred on the canvas origin. Shared by the player and the
## avatar-select preview. `dashing` swaps the body to the avatar's dash colour.
static func draw_avatar(c: CanvasItem, av: Dictionary, facing := 1, dashing := false) -> void:
	var body: Color = av.get("dash", Color.SKY_BLUE) if dashing else av.get("body", Color(0.96, 0.78, 0.25))
	var hat: Color = av.get("hat", Color(0, 0, 0, 0))
	var shape: String = av.get("shape", "block")

	var half_w := 5.0
	var half_h := 7.0
	match shape:
		"tall":
			half_w = 4.0
			half_h = 8.0
		"round":
			half_w = 5.5
			half_h = 6.0

	# Soft glow halo for a modern, lit look.
	c.draw_circle(Vector2(0, 0), half_h + 5.0, Color(body.r, body.g, body.b, 0.10))

	var rect := Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)
	c.draw_rect(rect, body, true)
	c.draw_rect(rect, body.darkened(0.35), false, 1.0)
	if shape == "round":
		c.draw_circle(Vector2(0, -half_h + 1.0), half_w, body)

	# Optional accent cap on top of the head.
	if hat.a > 0.01:
		c.draw_rect(Rect2(-half_w - 0.5, -half_h - 2.0, half_w * 2.0 + 1.0, 2.5), hat, true)

	# Eye looks in the facing direction.
	var eye_x := 2.0 * facing
	c.draw_rect(Rect2(eye_x - 1.0, -3.0, 2.0, 3.0), Color(0.1, 0.1, 0.15), true)
