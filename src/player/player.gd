class_name Player
extends CharacterBody2D
## Precision platformer controller: run, variable-height jump, double jump,
## wall slide / wall jump, and an 8-directional dash — with coyote time and
## jump buffering so inputs feel forgiving. Tuned for a 16px tile world at 60fps.
##
## Trap hooks: gravity can be flipped (flip_gravity) and horizontal controls can
## be reversed by zones (push_reverse). Both reset on respawn.

signal jumped
signal landed(strength: float)
signal dashed
signal died

# --- Tunables (pixels, seconds) ---
const RUN_SPEED := 112.0
const GROUND_ACCEL := 1500.0
const AIR_ACCEL := 950.0
const GROUND_FRICTION := 1700.0
const AIR_FRICTION := 450.0
const GRAVITY := 1000.0
const MAX_FALL := 340.0
const JUMP_VELOCITY := -310.0
const DOUBLE_JUMP_VELOCITY := -280.0
const JUMP_CUT := 0.45            # upward velocity kept when Jump is released early
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.10
const WALL_SLIDE_SPEED := 56.0
const WALL_JUMP_PUSH := 165.0
const WALL_JUMP_VELOCITY := -300.0
const WALL_JUMP_LOCK := 0.12      # window where horizontal control is dampened
const DASH_SPEED := 330.0
const DASH_TIME := 0.14
const DASH_END_SPEED := 130.0     # speed retained when a dash finishes

var facing := 1
var dead := false
var gravity_sign := 1.0           # +1 = down (normal), -1 = up (flipped)

var _coyote := 0.0
var _buffer := 0.0
var _can_double := true
var _can_dash := true
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _wall_lock := 0.0
var _was_on_floor := true
var _reverse_count := 0

var skin: PlayerSkin

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 14)
	shape.shape = rect
	add_child(shape)
	skin = PlayerSkin.new()
	add_child(skin)

func reset() -> void:
	velocity = Vector2.ZERO
	dead = false
	_can_double = true
	_can_dash = true
	_dash_time = 0.0
	_wall_lock = 0.0
	_coyote = 0.0
	_buffer = 0.0
	_reverse_count = 0
	gravity_sign = 1.0
	up_direction = Vector2.UP

func die() -> void:
	if dead:
		return
	dead = true
	died.emit()
	Game.player_died()

# --- Trap hooks ---

func flip_gravity() -> void:
	gravity_sign = -gravity_sign
	up_direction = Vector2(0.0, -gravity_sign)
	velocity.y = 0.0

func push_reverse(delta_count: int) -> void:
	_reverse_count = maxi(0, _reverse_count + delta_count)

func is_reversed() -> bool:
	return _reverse_count > 0

# --- Main loop ---

func _physics_process(delta: float) -> void:
	if dead:
		return

	_coyote -= delta
	_buffer -= delta
	_wall_lock -= delta

	var input_x := Input.get_axis("move_left", "move_right")
	if is_reversed():
		input_x = -input_x
	if _dash_time <= 0.0:
		if input_x > 0.0:
			facing = 1
		elif input_x < 0.0:
			facing = -1

	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	if Input.is_action_just_pressed("dash"):
		_try_dash(input_x)

	# An active dash overrides normal motion (no gravity while dashing).
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * DASH_SPEED
		if _dash_time <= 0.0:
			velocity = _dash_dir * DASH_END_SPEED
		move_and_slide()
		return

	if is_on_floor():
		_coyote = COYOTE_TIME
		_can_double = true
		_can_dash = true

	# Horizontal acceleration / friction.
	var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
	if _wall_lock > 0.0:
		accel *= 0.3
	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, input_x * RUN_SPEED, accel * delta)
	else:
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	# Gravity (direction follows gravity_sign).
	velocity.y += GRAVITY * delta * gravity_sign
	if gravity_sign > 0.0:
		velocity.y = minf(velocity.y, MAX_FALL)
	else:
		velocity.y = maxf(velocity.y, -MAX_FALL)

	# Wall slide (only when pushing into the wall while falling).
	var on_wall := is_on_wall_only()
	if on_wall:
		var n := get_wall_normal()
		var pressing := input_x != 0.0 and signf(input_x) == -signf(n.x)
		var falling := velocity.y * gravity_sign > 0.0
		if pressing and falling:
			if gravity_sign > 0.0:
				velocity.y = minf(velocity.y, WALL_SLIDE_SPEED)
			else:
				velocity.y = maxf(velocity.y, -WALL_SLIDE_SPEED)

	# Resolve a buffered jump against the best available option.
	if _buffer > 0.0:
		if _coyote > 0.0:
			_jump(JUMP_VELOCITY)
		elif on_wall:
			_wall_jump(get_wall_normal())
		elif _can_double and Game.double_jump_unlocked:
			_can_double = false
			_jump(DOUBLE_JUMP_VELOCITY)

	# Variable jump height (cut when moving against gravity and Jump released).
	if Input.is_action_just_released("jump") and velocity.y * gravity_sign < 0.0:
		velocity.y *= JUMP_CUT

	var pre_fall := velocity.y
	move_and_slide()

	# Landing feedback.
	if is_on_floor() and not _was_on_floor:
		var strength := clampf(absf(pre_fall) / MAX_FALL, 0.0, 1.0)
		landed.emit(strength)
		if skin:
			skin.squash(Vector2(1.0 + 0.3 * strength, 1.0 - 0.3 * strength))
	_was_on_floor = is_on_floor()

func _jump(v: float) -> void:
	velocity.y = v * gravity_sign
	_coyote = 0.0
	_buffer = 0.0
	jumped.emit()
	if skin:
		skin.squash(Vector2(0.7, 1.3))

func _wall_jump(n: Vector2) -> void:
	velocity.x = n.x * WALL_JUMP_PUSH
	velocity.y = WALL_JUMP_VELOCITY * gravity_sign
	_wall_lock = WALL_JUMP_LOCK
	_buffer = 0.0
	facing = int(signf(n.x))
	jumped.emit()
	if skin:
		skin.squash(Vector2(0.7, 1.3))

func _try_dash(input_x: float) -> void:
	if not Game.dash_unlocked or not _can_dash:
		return
	var vert := Input.get_axis("move_up", "move_down")
	var dir := Vector2(input_x, vert)
	if dir == Vector2.ZERO:
		dir = Vector2(facing, 0)
	_dash_dir = dir.normalized()
	_dash_time = DASH_TIME
	_can_dash = false
	velocity = _dash_dir * DASH_SPEED
	dashed.emit()
	if skin:
		skin.squash(Vector2(1.3, 0.7))
