extends Node
## Audio autoload. Holds the procedurally-built SFX bank (see Sfx) and a small
## pool of players for overlapping one-shots. Volume is driven by Game.sfx_volume.

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus pause the tree; UI clicks still beep
	_streams = Sfx.build_all()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)

## Play a named SFX. `pitch_var` adds ± random pitch for variety.
func play(sound: String, pitch_var := 0.0, vol_db := 0.0) -> void:
	var vol: float = Game.sfx_volume if Game != null else 0.7
	if vol <= 0.0:
		return
	var stream: AudioStreamWAV = _streams.get(sound)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.volume_db = vol_db + linear_to_db(clampf(vol, 0.0001, 1.0))
	p.play()
