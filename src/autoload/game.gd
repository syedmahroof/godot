extends Node
## Global game state, level flow, menu navigation, input binding, and save/load.
## Registered as the "Game" autoload (see project.godot).
##
## Flow: start() builds the HUD, loads the save file, and opens the main menu.
## Menus drive everything from there; gameplay runs only in State.PLAYING.

signal hud_changed
signal toast(text: String)
signal flash(color: Color)
signal badge_earned(name: String, desc: String)

enum State { MENU, PLAYING }

# Rotating death taunts — keeps dying funny instead of frustrating.
const TAUNTS := [
	"Ouch.", "Gravity: 1, You: 0", "Skill issue?", "So close!",
	"Have you tried not dying?", "The spikes send their regards.",
	"Bonk.", "That's gonna leave a mark.", "Respawn-tastic!",
	"Dave believes in you. Mostly.", "Oopsie.", "Try jumping. Pro tip.",
]

# --- Run state ---
var state := State.MENU
var deaths := 0
var run_coins := 0
var time := 0.0
var playing := false
var combo := 0                           # consecutive quick coin grabs
var combo_timer := 0.0
var _deaths_at_level_start := 0

# --- Persistent profile (mirrored to user://save.json) ---
var total_coins := 0
var stars := 0
var gems := 0
var max_level := 0                       # highest level the player has reached
var avatar_index := 0
var best_times := {}                     # level index (as String) -> seconds
var stars_found := {}                    # level index -> true once its star is taken
var gems_found := {}                     # level index -> true once its gem is taken
var completed := {}                      # level index -> true once cleared
var badges_earned := {}                  # badge id -> true

# --- Settings ---
var screen_shake := true
var fullscreen := false
var sfx_volume := 0.7                     # 0.0 = muted

# --- Ability unlocks (granted as levels are reached) ---
var double_jump_unlocked := false
var dash_unlocked := false

const SAVE_PATH := "user://save.json"
const SKIP_COST := 25                     # coins to skip a level (or watch an ad)

var _levels: Array = []                  # flattened, themed level list (Levels.flat())
var _level_index := 0
var _checkpoint := Vector2.ZERO
var _coins_at_cp := 0
var _world: Node = null
var _hud: CanvasLayer = null
var _menu: CanvasLayer = null
var _paused := false

func _ready() -> void:
	_setup_input()

func start(world: Node) -> void:
	_world = world
	_levels = Levels.flat()
	_load()
	_apply_fullscreen()
	_hud = Hud.new()
	world.add_child(_hud)
	_hud.visible = false
	goto_main_menu()

func _process(delta: float) -> void:
	if playing:
		time += delta
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0

func _unhandled_input(_event: InputEvent) -> void:
	if state != State.PLAYING or _paused:
		return
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	elif Input.is_action_just_pressed("restart"):
		reload_level()

func current_level_name() -> String:
	return _levels[_level_index].get("name", "")

func current_world_name() -> String:
	return _levels[_level_index].get("world_name", "")

func current_theme() -> Dictionary:
	return _levels[_level_index].get("theme", {})

func level(index: int) -> Dictionary:
	return _levels[clampi(index, 0, _levels.size() - 1)]

func levels() -> Array:
	return _levels

func level_count() -> int:
	return _levels.size()

func world_count() -> int:
	return Levels.world_count()

func best_time(index: int) -> float:
	return best_times.get(str(index), 0.0)

func has_progress() -> bool:
	return max_level > 0 or not completed.is_empty()

# --- Menu navigation ---

func _open(menu: CanvasLayer) -> void:
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
	_menu = menu
	_world.add_child(menu)

func _close_menu() -> void:
	if _menu and is_instance_valid(_menu):
		_menu.queue_free()
		_menu = null

func goto_main_menu() -> void:
	state = State.MENU
	playing = false
	_paused = false
	get_tree().paused = false
	_clear_levels()
	if _hud:
		_hud.visible = false
	_open(MainMenu.new())

func open_level_select() -> void:
	_open(RoadMap.new())

func open_avatar_select() -> void:
	_open(AvatarSelect.new())

func open_options() -> void:
	_open(OptionsMenu.new())

func open_badges() -> void:
	_open(BadgesScreen.new())

# --- Level flow ---

func new_game() -> void:
	max_level = maxi(max_level, 0)
	start_at(0)

func continue_game() -> void:
	start_at(max_level)

func start_at(index: int) -> void:
	state = State.PLAYING
	_close_menu()
	if _hud:
		_hud.visible = true
	load_level(index)

func load_level(index: int) -> void:
	_level_index = clampi(index, 0, _levels.size() - 1)
	max_level = maxi(max_level, _level_index)
	run_coins = 0
	_coins_at_cp = 0
	time = 0.0
	combo = 0
	_deaths_at_level_start = deaths
	_apply_unlock(_level_index)
	_build(false)
	playing = true
	hud_changed.emit()
	_save()

func reload_level() -> void:
	# Fast respawn: rebuild the room, drop the player at the last checkpoint,
	# and roll coins back to the checkpoint snapshot.
	run_coins = _coins_at_cp
	playing = true
	_build(true)
	hud_changed.emit()

func player_died() -> void:
	deaths += 1
	combo = 0
	flash.emit(Color(0.9, 0.2, 0.25, 0.5))
	toast.emit(TAUNTS[randi() % TAUNTS.size()])
	award_badge("deaths50")
	call_deferred("reload_level")

func complete_level() -> void:
	if not playing:
		return
	playing = false
	# Coins only bank the first time a level is cleared, so they can't be farmed.
	if not completed.get(_level_index, false):
		total_coins += run_coins
		completed[_level_index] = true
	var key := str(_level_index)
	var prev: float = best_times.get(key, 1.0e9)
	var new_best := time < prev
	if new_best:
		best_times[key] = time
	_save()
	if deaths == _deaths_at_level_start:
		_flawless_flag = true
		flash.emit(Color(1.0, 0.9, 0.4, 0.35))
		toast.emit("FLAWLESS!  %.2fs ✨" % time)
	elif new_best:
		toast.emit("New Best!  %.2fs" % time)
	else:
		toast.emit("Level Complete!  %.2fs" % time)
	check_badges()
	var next_index := _level_index + 1
	if next_index >= _levels.size():
		toast.emit("You beat every world! ★ %d  ◆ %d" % [stars, gems])
		call_deferred("goto_main_menu")
	else:
		call_deferred("load_level", next_index)

# --- Pickups / checkpoints ---

func add_coin() -> void:
	run_coins += 1
	# Quick consecutive pickups build a combo (purely for flair + a few bonus coins).
	if combo_timer > 0.0:
		combo += 1
	else:
		combo = 1
	combo_timer = 1.4
	if combo >= 5 and combo % 5 == 0:
		run_coins += 2
		toast.emit("Combo x%d!  +2" % combo)
	if combo >= 10:
		_combo_flag = true
		award_badge("combo10")
	hud_changed.emit()

func add_gem() -> void:
	if gems_found.get(_level_index, false):
		run_coins += 5
		hud_changed.emit()
		return
	gems_found[_level_index] = true
	gems = gems_found.size()
	run_coins += 10
	flash.emit(Color(0.5, 0.9, 1.0, 0.3))
	toast.emit("BONUS GEM!  +10 ◆")
	_save()
	check_badges()
	hud_changed.emit()

func add_star() -> void:
	if stars_found.get(_level_index, false):
		toast.emit("Star (already counted)")
		return
	stars_found[_level_index] = true
	stars = stars_found.size()
	toast.emit("Secret Star found!  ★ %d" % stars)
	_save()
	check_badges()
	hud_changed.emit()

func set_checkpoint(pos: Vector2) -> void:
	_checkpoint = pos
	_coins_at_cp = run_coins
	toast.emit("Checkpoint")

# --- Badges ---

## Award any newly-satisfied stat-based badges. Event badges (flawless, combo)
## are granted directly at their moment via award_badge().
func check_badges() -> void:
	for b in Badges.list():
		award_badge(b.get("id", ""))

func award_badge(id: String) -> void:
	if id == "" or badges_earned.get(id, false) or not _badge_condition(id):
		return
	badges_earned[id] = true
	var b := Badges.get_badge(id)
	flash.emit(Color(1.0, 0.88, 0.35, 0.3))
	Audio.play("complete")
	badge_earned.emit(b.get("name", "Badge"), b.get("desc", ""))
	_save()

func badge_count() -> int:
	return badges_earned.size()

func _badge_condition(id: String) -> bool:
	match id:
		"first_clear": return completed.size() >= 1
		"halfway": return max_level >= int(level_count() / 2)
		"rock_bottom": return completed.size() >= level_count()
		"w1": return _world_cleared(0)
		"w2": return _world_cleared(1)
		"w3": return _world_cleared(2)
		"w4": return _world_cleared(3)
		"stars5": return stars >= 5
		"starsall": return stars >= level_count()
		"gems4": return gems >= 4
		"deaths50": return deaths >= 50
		"flawless": return _flawless_flag
		"combo10": return _combo_flag
	return false

# Latches for event-based badges so check_badges() can re-confirm them.
var _flawless_flag := false
var _combo_flag := false

func _world_cleared(wi: int) -> bool:
	var any := false
	for e in _levels:
		if e.get("world", -1) == wi:
			any = true
			if not completed.get(e.get("flat_index", -1), false):
				return false
	return any

# --- Pause ---

func toggle_pause() -> void:
	if _paused:
		resume()
	else:
		pause()

func pause() -> void:
	if state != State.PLAYING or _paused:
		return
	_paused = true
	get_tree().paused = true
	var pm := PauseMenu.new()
	pm.process_mode = Node.PROCESS_MODE_ALWAYS
	_open(pm)

func resume() -> void:
	if not _paused:
		return
	_paused = false
	get_tree().paused = false
	_close_menu()

## Re-show the pause overlay (used when backing out of Options / Skip mid-game).
func reopen_pause_menu() -> void:
	var pm := PauseMenu.new()
	pm.process_mode = Node.PROCESS_MODE_ALWAYS
	_open(pm)

# --- Skip level (watch ad / spend coins) ---

## Open the "stuck?" skip dialog from the pause menu.
func request_skip() -> void:
	var sm := SkipMenu.new()
	sm.process_mode = Node.PROCESS_MODE_ALWAYS
	_open(sm)

## Show the (currently dummy) rewarded ad; on completion the level is skipped.
## Swap the DummyAd body for a real ad SDK call later — keep _do_skip as the
## reward callback.
func skip_via_ad() -> void:
	var ad := DummyAd.new()
	ad.process_mode = Node.PROCESS_MODE_ALWAYS
	ad.on_reward = _do_skip
	_open(ad)

## Spend coins to skip. Returns false (and toasts) if the player can't afford it.
func skip_via_coins() -> bool:
	if total_coins < SKIP_COST:
		toast.emit("Need %d ◎ (have %d)" % [SKIP_COST, total_coins])
		return false
	total_coins -= SKIP_COST
	_save()
	_do_skip()
	return true

func _do_skip() -> void:
	_paused = false
	get_tree().paused = false
	_close_menu()
	var next_index := _level_index + 1
	if next_index >= _levels.size():
		toast.emit("That was the last level!")
		goto_main_menu()
		return
	max_level = maxi(max_level, next_index)
	if _hud:
		_hud.visible = true
	load_level(next_index)
	toast.emit("Level skipped — onward!")

# --- Settings ---

func set_screen_shake(on: bool) -> void:
	screen_shake = on
	_save()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_save()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_save()
	Audio.play("select")

func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED)

func set_avatar(index: int) -> void:
	avatar_index = clampi(index, 0, Avatars.count() - 1)
	_save()

func reset_save() -> void:
	total_coins = 0
	stars = 0
	gems = 0
	max_level = 0
	avatar_index = 0
	best_times = {}
	stars_found = {}
	gems_found = {}
	completed = {}
	badges_earned = {}
	_flawless_flag = false
	_combo_flag = false
	double_jump_unlocked = false
	dash_unlocked = false
	deaths = 0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_save()
	toast.emit("Save reset")

# --- Internals ---

func _clear_levels() -> void:
	for child in _world.get_children():
		if child is Level:
			child.set_physics_process(false)
			child.queue_free()

func _build(use_checkpoint: bool) -> void:
	_clear_levels()
	var level := Level.new()
	level.data = _levels[_level_index]
	_world.add_child(level)
	if use_checkpoint:
		level.player.global_position = _checkpoint
		level.player.reset()
	else:
		_checkpoint = level.spawn_point

func _apply_unlock(index: int) -> void:
	# Re-apply unlocks for every level up to the one being entered, so jumping
	# straight in via Level Select still grants the right abilities.
	for i in range(index + 1):
		var unlock: String = _levels[i].get("unlock", "")
		if unlock == "double":
			double_jump_unlocked = true
		elif unlock == "dash":
			dash_unlocked = true
	# Announce only the unlock that belongs to the current level.
	var here: String = _levels[index].get("unlock", "")
	if here == "double":
		toast.emit("Double Jump — tap Jump again midair")
	elif here == "dash":
		toast.emit("Dash — press Shift / X")

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

# --- Persistence ---

func _save() -> void:
	var data := {
		"total_coins": total_coins,
		"stars": stars,
		"gems": gems,
		"max_level": max_level,
		"avatar_index": avatar_index,
		"best_times": best_times,
		"stars_found": _keys_to_strings(stars_found),
		"gems_found": _keys_to_strings(gems_found),
		"completed": _keys_to_strings(completed),
		"badges_earned": badges_earned,
		"double_jump_unlocked": double_jump_unlocked,
		"dash_unlocked": dash_unlocked,
		"deaths": deaths,
		"screen_shake": screen_shake,
		"fullscreen": fullscreen,
		"sfx_volume": sfx_volume,
	}
	var wf := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if wf:
		wf.store_string(JSON.stringify(data, "\t"))
		wf.close()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var rf := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not rf:
		return
	var parsed: Variant = JSON.parse_string(rf.get_as_text())
	rf.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	total_coins = int(d.get("total_coins", 0))
	max_level = int(d.get("max_level", 0))
	avatar_index = int(d.get("avatar_index", 0))
	best_times = d.get("best_times", {})
	stars_found = _ints_from(d.get("stars_found", {}))
	gems_found = _ints_from(d.get("gems_found", {}))
	completed = _ints_from(d.get("completed", {}))
	badges_earned = d.get("badges_earned", {})
	stars = stars_found.size()
	gems = gems_found.size()
	_flawless_flag = badges_earned.get("flawless", false)
	_combo_flag = badges_earned.get("combo10", false)
	double_jump_unlocked = bool(d.get("double_jump_unlocked", false))
	dash_unlocked = bool(d.get("dash_unlocked", false))
	deaths = int(d.get("deaths", 0))
	screen_shake = bool(d.get("screen_shake", true))
	fullscreen = bool(d.get("fullscreen", false))
	sfx_volume = float(d.get("sfx_volume", 0.7))

# JSON object keys are always strings; these helpers keep our int-keyed dicts
# round-tripping cleanly.
func _keys_to_strings(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[str(k)] = d[k]
	return out

func _ints_from(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[int(k)] = d[k]
	return out
