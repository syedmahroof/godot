class_name Sfx
## Synthesizes all sound effects in code as 16-bit PCM AudioStreamWAVs — chunky
## little chiptune blips, sweeps and jingles. Keeps the project asset-free.

const RATE := 44100

## name -> AudioStreamWAV. Built once at startup by the Audio autoload.
static func build_all() -> Dictionary:
	return {
		"coin": _tone(0.08, 900.0, 1500.0, "square", 0.32),
		"star": _seq([[0.06, 1200.0, 1200.0, "sine", 0.30], [0.12, 1800.0, 2300.0, "sine", 0.30]]),
		"gem": _seq([[0.07, 800.0, 800.0, "square", 0.30], [0.07, 1100.0, 1100.0, "square", 0.30], [0.14, 1500.0, 1750.0, "square", 0.30]]),
		"jump": _tone(0.12, 320.0, 640.0, "square", 0.28),
		"bounce": _tone(0.18, 260.0, 860.0, "square", 0.32),
		"dash": _tone(0.16, 200.0, 920.0, "saw", 0.26),
		"stomp": _tone(0.12, 320.0, 90.0, "square", 0.34),
		"die": _tone(0.34, 440.0, 70.0, "saw", 0.32),
		"complete": _seq([[0.10, 660.0, 660.0, "square", 0.30], [0.10, 880.0, 880.0, "square", 0.30], [0.20, 1320.0, 1320.0, "square", 0.30]]),
		"checkpoint": _seq([[0.08, 700.0, 700.0, "sine", 0.30], [0.13, 1050.0, 1050.0, "sine", 0.30]]),
		"portal": _tone(0.26, 1000.0, 300.0, "sine", 0.30),
		"select": _tone(0.05, 1150.0, 1150.0, "square", 0.20),
	}

# --- Synthesis ---

static func _tone(dur: float, f0: float, f1: float, wave: String, vol: float) -> AudioStreamWAV:
	return _make(_gen(dur, f0, f1, wave, vol))

static func _seq(parts: Array) -> AudioStreamWAV:
	var all := PackedFloat32Array()
	for p in parts:
		all.append_array(_gen(p[0], p[1], p[2], p[3], p[4]))
	return _make(all)

static func _gen(dur: float, f0: float, f1: float, wave: String, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var atk := 0.005 * RATE
	for i in n:
		var p := float(i) / float(n)
		var freq: float = lerp(f0, f1, p)
		phase += TAU * freq / RATE
		var env := minf(1.0, float(i) / atk) * pow(1.0 - p, 0.5)
		out[i] = _wave(wave, phase) * env * vol
	return out

static func _wave(wave: String, phase: float) -> float:
	match wave:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"saw":
			return fmod(phase / TAU, 1.0) * 2.0 - 1.0
		_:
			return sin(phase)

static func _make(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var iv := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		var u := iv & 0xFFFF
		bytes[i * 2] = u & 0xFF
		bytes[i * 2 + 1] = (u >> 8) & 0xFF
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s
