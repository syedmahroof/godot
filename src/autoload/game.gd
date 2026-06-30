extends Node
## Global game state, level flow, input binding, and save/load.
## Registered as the "Game" autoload (see project.godot).

signal hud_changed
signal toast(text: String)

# --- Run state ---
var deaths := 0
var run_coins := 0
var total_coins := 0
var stars := 0
var time := 0.0
var playing := false

# --- Ability unlocks (granted as levels are reached) ---
var double_jump_unlocked := false
var dash_unlocked := false

var _level_index := 0
var _checkpoint := Vector2.ZERO
var _coins_at_cp := 0
var _world: Node = null
var _hud: CanvasLayer = null

func _ready() -> void:
	_setup_input()

func start(world: Node) -> void:
	_world = world
	_hud = Hud.new()
	world.add_child(_hud)
	load_level(0)

func _process(delta: float) -> void:
	if playing:
		time += delta

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("restart"):
		reload_level()
	elif Input.is_action_just_pressed("pause"):
		get_tree().quit()

func current_level_name() -> String:
	return Levels.DATA[_level_index].get("name", "")

# --- Level flow ---

func load_level(index: int) -> void:
	_level_index = clampi(index, 0, Levels.DATA.size() - 1)
	run_coins = 0
	_coins_at_cp = 0
	time = 0.0
	_apply_unlock(_level_index)
	_build(false)
	playing = true
	hud_changed.emit()

func reload_level() -> void:
	# Fast respawn: rebuild the room, drop the player at the last checkpoint,
	# and roll coins back to the checkpoint snapshot.
	run_coins = _coins_at_cp
	_build(true)
	hud_changed.emit()

func player_died() -> void:
	deaths += 1
	call_deferred("reload_level")

func complete_level() -> void:
	if not playing:
		return
	playing = false
	total_coins += run_coins
	_save()
	toast.emit("Level Complete!  %.2fs" % time)
	var next_index := _level_index + 1
	if next_index >= Levels.DATA.size():
		next_index = 0
	call_deferred("load_level", next_index)

# --- Pickups / checkpoints ---

func add_coin() -> void:
	run_coins += 1
	hud_changed.emit()

func add_star() -> void:
	stars += 1
	toast.emit("Secret Star found!")
	hud_changed.emit()

func set_checkpoint(pos: Vector2) -> void:
	_checkpoint = pos
	_coins_at_cp = run_coins
	toast.emit("Checkpoint")

# --- Internals ---

func _build(use_checkpoint: bool) -> void:
	for child in _world.get_children():
		if child is Level:
			child.set_physics_process(false)
			child.queue_free()
	var level := Level.new()
	level.data = Levels.DATA[_level_index]
	_world.add_child(level)
	if use_checkpoint:
		level.player.global_position = _checkpoint
		level.player.reset()
	else:
		_checkpoint = level.spawn_point

func _apply_unlock(index: int) -> void:
	var unlock: String = Levels.DATA[index].get("unlock", "")
	if unlock == "double" and not double_jump_unlocked:
		double_jump_unlocked = true
		toast.emit("Unlocked: Double Jump — tap Jump again midair")
	elif unlock == "dash" and not dash_unlocked:
		dash_unlocked = true
		toast.emit("Unlocked: Dash — press Shift / X")

func _setup_input() -> void:
	_bind("move_left", [KEY_LEFT, KEY_A])
	_bind("move_right", [KEY_RIGHT, KEY_D])
	_bind("move_up", [KEY_UP, KEY_W])
	_bind("move_down", [KEY_DOWN, KEY_S])
	_bind("jump", [KEY_SPACE, KEY_Z, KEY_K], [JOY_BUTTON_A])
	_bind("dash", [KEY_SHIFT, KEY_X, KEY_L], [JOY_BUTTON_X])
	_bind("interact", [KEY_E, KEY_ENTER], [JOY_BUTTON_Y])
	_bind("restart", [KEY_R], [JOY_BUTTON_BACK])
	_bind("pause", [KEY_ESCAPE], [JOY_BUTTON_START])

func _bind(action: String, keys: Array, buttons: Array = []) -> void:
	if InputMap.has_action(action):
		InputMap.action_erase_events(action)
	else:
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jev := InputEventJoypadButton.new()
		jev.button_index = b
		InputMap.action_add_event(action, jev)

func _save() -> void:
	var path := "user://save.json"
	var data := {}
	if FileAccess.file_exists(path):
		var rf := FileAccess.open(path, FileAccess.READ)
		if rf:
			var parsed: Variant = JSON.parse_string(rf.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				data = parsed
			rf.close()
	var key := "best_%d" % _level_index
	var best: float = data.get(key, 1.0e9)
	if time < best:
		data[key] = time
	data["total_coins"] = total_coins
	data["stars"] = stars
	var wf := FileAccess.open(path, FileAccess.WRITE)
	if wf:
		wf.store_string(JSON.stringify(data))
		wf.close()
