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

# Tools / environment
const JET_ACCEL := 1300.0         # jetpack thrust accel while Jump held
const JET_MAX := 150.0            # jetpack max climb speed
const SWIM_GRAVITY := 0.28        # gravity multiplier underwater
const SWIM_MAX_FALL := 70.0       # terminal velocity underwater
const SWIM_STROKE := 150.0        # upward kick per Jump underwater
const SHOOT_CD := 0.28
const BULLET_SPEED := 260.0

var facing := 1
var dead := false
var gravity_sign := 1.0           # +1 = down (normal), -1 = up (flipped)

# Tool / environment state (all reset on respawn — pickups respawn too).
var has_jetpack := false
var has_gun := false
var shielded := false             # helmet: absorbs one otherwise-fatal hit

var _coyote := 0.0
var _buffer := 0.0
var _can_double := true
var _can_dash := true
var _dash_time := 0.0
var _dash_dir := Vector2.ZERO
var _wall_lock := 0.0
var _was_on_floor := true
var _reverse_count := 0
var _water := 0                   # number of overlapping water tiles
var _shoot_cd := 0.0
var _invuln := 0.0                # brief mercy window after a shield save

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
	has_jetpack = false
	has_gun = false
	shielded = false
	_water = 0
	_shoot_cd = 0.0
	_invuln = 0.0

func die() -> void:
	if dead or _invuln > 0.0:
		return
	# Helmet absorbs one hit instead of killing.
	if shielded:
		shielded = false
		_invuln = 0.7
		velocity.y = -180.0 * gravity_sign
		Audio.play("stomp", 0.1)
		Burst.spawn(get_parent(), global_position, Color(0.6, 0.9, 1.0), 16, 110.0, 0.5, 2.2)
		Game.toast.emit("Helmet saved you!")
		Game.set_tool("")
		return
	dead = true
	Burst.spawn(get_parent(), global_position, Color(1.0, 0.5, 0.45), 18, 130.0, 0.55, 2.4)
	Audio.play("die")
	died.emit()
	Game.player_died()

# --- Tools ---

func grant_jetpack() -> void:
	has_jetpack = true
	Game.set_tool("🚀 Jetpack — hold Jump")
	_equip_fx()

func grant_gun() -> void:
	has_gun = true
	Game.set_tool("🔫 Blaster — press F / J")
	_equip_fx()

func grant_helmet() -> void:
	shielded = true
	Game.set_tool("🪖 Helmet — blocks one hit")
	_equip_fx()

func add_water(n: int) -> void:
	_water = maxi(0, _water + n)

func _equip_fx() -> void:
	Audio.play("star")
	Burst.spawn(get_parent(), global_position, Color(1.0, 0.95, 0.6), 14, 90.0, 0.5, 2.0)
	if skin:
		skin.squash(Vector2(0.7, 1.3))

func _shoot() -> void:
	_shoot_cd = SHOOT_CD
	var b := Bullet.new()
	b.dir = Vector2(facing, 0)
	b.speed = BULLET_SPEED
	b.position = global_position + Vector2(facing * 6.0, -1.0)
	get_parent().add_child(b)
	Audio.play("dash", 0.12)

## Launch upward (springs, stomps). Refreshes air abilities so chaining feels good.
func bounce(v: float) -> void:
	velocity.y = -absf(v) * gravity_sign
	_can_double = true
	_can_dash = true
	_coyote = 0.0
	_buffer = 0.0
	jumped.emit()
	if skin:
		skin.squash(Vector2(0.6, 1.4))

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
	_invuln -= delta
	_shoot_cd -= delta

	var input_x := Input.get_axis("move_left", "move_right")
	if is_reversed():
		input_x = -input_x
	if _dash_time <= 0.0:
		if input_x > 0.0:
			facing = 1
		elif input_x < 0.0:
			facing = -1

	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("move_up"):
		_buffer = JUMP_BUFFER
	if Input.is_action_just_pressed("dash"):
		_try_dash(input_x)
	if has_gun and _shoot_cd <= 0.0 and Input.is_action_just_pressed("shoot"):
		_shoot()

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

	# Gravity (direction follows gravity_sign; scaled by the level, e.g. low-grav
	# space, and softened underwater).
	var in_water := _water > 0
	var grav_scale := Game.level_gravity()
	if in_water:
		grav_scale *= SWIM_GRAVITY
	velocity.y += GRAVITY * grav_scale * delta * gravity_sign
	var max_fall := SWIM_MAX_FALL if in_water else MAX_FALL
	if gravity_sign > 0.0:
		velocity.y = minf(velocity.y, max_fall)
	else:
		velocity.y = maxf(velocity.y, -max_fall)

	# Jetpack: hold Jump to thrust against gravity.
	var jump_down := Input.is_action_pressed("jump") or Input.is_action_pressed("move_up")
	if has_jetpack and jump_down:
		velocity.y = move_toward(velocity.y, -JET_MAX * gravity_sign, JET_ACCEL * delta)
		if Engine.get_physics_frames() % 3 == 0:
			Burst.spawn(get_parent(), global_position + Vector2(0, 7 * gravity_sign),
				Color(1.0, 0.7, 0.3, 0.85), 2, 45.0, 0.25, 1.4)

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
		if in_water:
			# Swimming: every Jump is a repeatable upward stroke.
			velocity.y = -SWIM_STROKE * gravity_sign
			_buffer = 0.0
			Audio.play("jump", 0.12)
			if skin:
				skin.squash(Vector2(0.8, 1.2))
		elif _coyote > 0.0:
			_jump(JUMP_VELOCITY)
		elif on_wall:
			_wall_jump(get_wall_normal())
		elif _can_double and Game.double_jump_unlocked:
			_can_double = false
			_jump(DOUBLE_JUMP_VELOCITY)

	# Variable jump height (cut when moving against gravity and Jump released).
	# Either Jump or Up can hold the rise; only cut once neither is held.
	var jump_held := Input.is_action_pressed("jump") or Input.is_action_pressed("move_up")
	var jump_released := Input.is_action_just_released("jump") or Input.is_action_just_released("move_up")
	if jump_released and not jump_held and velocity.y * gravity_sign < 0.0:
		velocity.y *= JUMP_CUT

	var pre_fall := velocity.y
	move_and_slide()

	# Landing feedback.
	if is_on_floor() and not _was_on_floor:
		var strength := clampf(absf(pre_fall) / MAX_FALL, 0.0, 1.0)
		landed.emit(strength)
		if skin:
			skin.squash(Vector2(1.0 + 0.3 * strength, 1.0 - 0.3 * strength))
		if strength > 0.25:
			Burst.spawn(get_parent(), global_position + Vector2(0, 7 * gravity_sign),
				Color(0.9, 0.92, 1.0, 0.7), int(2 + strength * 6), 40.0 + strength * 50.0, 0.35, 1.6)
	_was_on_floor = is_on_floor()

func _jump(v: float) -> void:
	velocity.y = v * gravity_sign
	_coyote = 0.0
	_buffer = 0.0
	jumped.emit()
	Audio.play("jump", 0.06)
	if skin:
		skin.squash(Vector2(0.7, 1.3))

func _wall_jump(n: Vector2) -> void:
	velocity.x = n.x * WALL_JUMP_PUSH
	velocity.y = WALL_JUMP_VELOCITY * gravity_sign
	_wall_lock = WALL_JUMP_LOCK
	_buffer = 0.0
	facing = int(signf(n.x))
	jumped.emit()
	Audio.play("jump", 0.06)
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
	Audio.play("dash", 0.04)
	Burst.spawn(get_parent(), global_position, Color(0.45, 0.85, 1.0, 0.9), 10, 60.0, 0.35, 2.0)
	if skin:
		skin.squash(Vector2(1.3, 0.7))
