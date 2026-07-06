extends Node
## All audio is synthesized at startup — the repo contains no audio files.
##
## REPLACING THE SOUNDTRACK (two ways, no code changes):
##   1. Drop a file named  track.ogg / track.mp3 / track.wav  into  res://music/
##      and re-export (or just run from the editor).
##   2. At runtime, drop  music.ogg / music.mp3 / music.wav  into the game's
##      user data folder (macOS: ~/Library/Application Support/Godot/
##      app_userdata/Two Microseconds/). Found on next launch.
## The generated loop below is only the fallback.

const SFX_RATE := 22050
const MUSIC_RATE := 12000
const MUSIC_DB := -12.0
const WIND_DB := -30.0

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = _music_stream()
	_music_player.volume_db = MUSIC_DB
	add_child(_music_player)
	# Loop fallback for streams that don't loop natively.
	_music_player.finished.connect(_music_player.play)
	_music_player.play()
	_start_loop("wind", WIND_DB)


func play(key: String, vol_db := 0.0, pitch_jitter := 0.05) -> void:
	if not _streams.has(key):
		return
	var player: AudioStreamPlayer = null
	for p in _pool:
		if not p.playing:
			player = p
			break
	if player == null:
		player = _pool[0]
	player.stream = _streams[key]
	player.volume_db = vol_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func _start_loop(key: String, vol_db: float) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = _streams[key]
	p.volume_db = vol_db
	add_child(p)
	p.play()


# ------------------------------------------------------------------ music --

func _music_stream() -> AudioStream:
	# 1) Runtime override in the user data folder.
	for ext: String in ["ogg", "mp3", "wav"]:
		var user_path := "user://music." + ext
		if FileAccess.file_exists(user_path):
			var s := _load_external_music(user_path, ext)
			if s != null:
				return s
	# 2) Project override committed under res://music/.
	for ext: String in ["ogg", "mp3", "wav"]:
		var res_path := "res://music/track." + ext
		if ResourceLoader.exists(res_path):
			var s2: AudioStream = load(res_path)
			if s2 != null:
				_enable_loop(s2)
				return s2
	# 3) The built-in generated tune.
	return _make_music()


func _load_external_music(path: String, ext: String) -> AudioStream:
	match ext:
		"ogg":
			var ogg := AudioStreamOggVorbis.load_from_file(path)
			if ogg != null:
				ogg.loop = true
			return ogg
		"mp3":
			var bytes := FileAccess.get_file_as_bytes(path)
			if bytes.is_empty():
				return null
			var mp3 := AudioStreamMP3.new()
			mp3.data = bytes
			mp3.loop = true
			return mp3
		"wav":
			# Looping falls back to the `finished` reconnect.
			return AudioStreamWAV.load_from_file(path)
	return null


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = true


# ------------------------------------------------------------ synthesis ----

func _build() -> void:
	_streams["zap"] = _make_zap()
	_streams["dash"] = _make_dash()
	_streams["task_done"] = _make_task_done()
	_streams["pop"] = _make_pop()
	_streams["tick"] = _make_tick()
	_streams["decay"] = _make_decay()
	_streams["detected"] = _make_detected()
	_streams["chirp"] = _make_chirp()
	_streams["boing"] = _make_boing()
	_streams["glitch"] = _make_glitch()
	_streams["buy"] = _make_buy()
	_streams["deny"] = _make_deny()
	_streams["wind"] = _make_wind()


func _pack(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var n := samples.size()
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var v := clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = n
	return wav


func _normalize(b: PackedFloat32Array, peak: float) -> void:
	var m := 0.0
	for i in b.size():
		m = maxf(m, absf(b[i]))
	if m < 0.0001:
		return
	var s := peak / m
	for i in b.size():
		b[i] *= s


## The "honk": a cheeky square-wave chirp sliding down.
func _make_zap() -> AudioStreamWAV:
	var dur := 0.22
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var k := t / dur
		var freq := lerpf(950.0, 190.0, pow(k, 0.55))
		phase += freq / SFX_RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		b[i] = sq * 0.45 * pow(1.0 - k, 1.4)
	return _pack(b, SFX_RATE, false)


## Filtered-noise whoosh for the dash.
func _make_dash() -> AudioStreamWAV:
	var dur := 0.32
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var y := 0.0
	for i in n:
		var k := float(i) / n
		var x := rng.randf() * 2.0 - 1.0
		var a := lerpf(0.55, 0.03, k)
		y += a * (x - y)
		b[i] = y * 1.1 * pow(1.0 - k, 1.1)
	return _pack(b, SFX_RATE, false)


## Little major arpeggio for a completed task.
func _make_task_done() -> AudioStreamWAV:
	var dur := 0.85
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var notes := [[0.0, 523.25], [0.09, 659.25], [0.18, 783.99], [0.30, 1046.5]]
	for note in notes:
		var onset := int(note[0] * SFX_RATE)
		var freq: float = note[1]
		var length := mini(int(0.5 * SFX_RATE), n - onset)
		for j in length:
			var t := float(j) / SFX_RATE
			var a := exp(-t * 7.0) * 0.22
			b[onset + j] += (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * a
	return _pack(b, SFX_RATE, false)


func _make_pop() -> AudioStreamWAV:
	var dur := 0.09
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var k := t / dur
		phase += lerpf(620.0, 940.0, k) / SFX_RATE
		b[i] = sin(TAU * phase) * 0.4 * (1.0 - k)
	return _pack(b, SFX_RATE, false)


func _make_tick() -> AudioStreamWAV:
	var dur := 0.07
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	for i in n:
		var t := float(i) / SFX_RATE
		b[i] = sin(TAU * 300.0 * t) * exp(-t * 34.0) * 0.5
	return _pack(b, SFX_RATE, false)


## Sad-cute goodbye gliss for the decay ending.
func _make_decay() -> AudioStreamWAV:
	var dur := 0.95
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var k := t / dur
		var freq := lerpf(540.0, 170.0, pow(k, 0.8))
		phase += freq / SFX_RATE
		var v := sin(TAU * phase) * (1.0 + 0.12 * sin(TAU * 6.0 * t))
		var out := v * 0.38 * pow(1.0 - k, 1.2)
		if t < 0.09:
			out += (rng.randf() * 2.0 - 1.0) * 0.3 * (1.0 - t / 0.09)
		b[i] = out
	return _pack(b, SFX_RATE, false)


## Geiger click + receipt-printer ratchet + a proud little ding.
func _make_detected() -> AudioStreamWAV:
	var dur := 1.15
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in int(0.012 * SFX_RATE):
		b[i] += (rng.randf() * 2.0 - 1.0) * (1.0 - float(i) / (0.012 * SFX_RATE)) * 0.8
	for i in int(0.28 * SFX_RATE):
		var t := float(i) / SFX_RATE
		b[int(0.02 * SFX_RATE) + i] += sin(TAU * 1244.5 * t) * exp(-t * 12.0) * 0.3
	for click_i in 14:
		var onset := int((0.36 + click_i * 0.028) * SFX_RATE)
		for j in int(0.004 * SFX_RATE):
			if onset + j < n:
				b[onset + j] += (rng.randf() * 2.0 - 1.0) * 0.22
	var ding_start := int(0.82 * SFX_RATE)
	for i in n - ding_start:
		var t := float(i) / SFX_RATE
		b[ding_start + i] += (sin(TAU * 1568.0 * t) + 0.4 * sin(TAU * 3136.0 * t)) * exp(-t * 9.0) * 0.25
	return _pack(b, SFX_RATE, false)


func _make_chirp() -> AudioStreamWAV:
	var dur := 0.2
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	for start in [0.0, 0.1]:
		var onset := int(start * SFX_RATE)
		var length := int(0.07 * SFX_RATE)
		var phase := 0.0
		for j in length:
			if onset + j >= n:
				break
			var t := float(j) / SFX_RATE
			var k := t / 0.07
			phase += lerpf(2300.0, 1500.0, k) / SFX_RATE
			b[onset + j] += sin(TAU * phase) * 0.3 * (1.0 - k)
	return _pack(b, SFX_RATE, false)


func _make_boing() -> AudioStreamWAV:
	var dur := 0.3
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var k := t / dur
		var freq := 260.0 * (1.0 + 0.3 * exp(-t * 7.0) * sin(TAU * 22.0 * t))
		phase += freq / SFX_RATE
		b[i] = sin(TAU * phase) * 0.4 * pow(1.0 - k, 1.3)
	return _pack(b, SFX_RATE, false)


## Bitcrushed digital corruption, for satellite bumps.
func _make_glitch() -> AudioStreamWAV:
	var dur := 0.34
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var k := t / dur
		var seg := int(t / 0.011)
		var h := absi(hash(seg * 7919 + 13))
		var gate := 0.0 if h % 5 == 0 else 1.0
		var freq := 300.0 + float(h % 12) * 260.0
		phase += freq / SFX_RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		# 3-bit crush.
		var v := roundf(sq * gate * 4.0) / 4.0
		b[i] = v * 0.42 * pow(1.0 - k, 0.7)
	return _pack(b, SFX_RATE, false)


## Rising shop-purchase arpeggio.
func _make_buy() -> AudioStreamWAV:
	var dur := 0.55
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var notes := [[0.0, 523.25], [0.07, 659.25], [0.14, 783.99], [0.21, 1046.5], [0.30, 1318.5]]
	for note in notes:
		var onset := int(note[0] * SFX_RATE)
		var freq: float = note[1]
		var length := mini(int(0.35 * SFX_RATE), n - onset)
		for j in length:
			var t := float(j) / SFX_RATE
			b[onset + j] += (sin(TAU * freq * t) + 0.25 * sin(TAU * freq * 3.0 * t)) * exp(-t * 8.0) * 0.2
	return _pack(b, SFX_RATE, false)


## Gentle "not yet" double-buzz.
func _make_deny() -> AudioStreamWAV:
	var dur := 0.26
	var n := int(dur * SFX_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / SFX_RATE
		var on := (t < 0.09) or (t > 0.15 and t < 0.24)
		if not on:
			continue
		phase += 138.0 / SFX_RATE
		var sq := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		b[i] = sq * 0.22
	return _pack(b, SFX_RATE, false)


## The built-in soundtrack: a hand-composed 8-bar loop at 104 BPM.
## C - Am - F - G, twice: soft pad, round bass, plucky pentatonic-ish melody,
## brushed offbeat ticks. Note tails wrap around the buffer so it loops clean.
func _make_music() -> AudioStreamWAV:
	var bpm := 104.0
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var bars := 8
	var dur := bar * bars
	var n := int(dur * MUSIC_RATE)
	var b := PackedFloat32Array()
	b.resize(n)

	# Pad: one triad per bar, enveloped inside the bar so changes don't click.
	var pads := [
		[261.63, 329.63, 392.0],   # C
		[220.0, 261.63, 329.63],   # Am
		[174.61, 220.0, 261.63],   # F
		[196.0, 246.94, 293.66],   # G
	]
	for i in n:
		var t := float(i) / MUSIC_RATE
		var bar_i := int(t / bar) % 4
		var bar_pos := fmod(t, bar) / bar
		var env := minf(minf(bar_pos / 0.05, (1.0 - bar_pos) / 0.10), 1.0)
		var chord: Array = pads[bar_i]
		var v := 0.0
		for f in chord:
			v += sin(TAU * float(f) * t)
		b[i] = v * 0.030 * env

	# Bass: root pulses on beats 1, 3, and the 4-and.
	var roots := [65.41, 110.0, 87.31, 98.0]  # C2 A2 F2 G2
	for bar_i in bars:
		var root: float = roots[bar_i % 4]
		for hit in [0.0, 2.0, 3.5]:
			var onset := int((bar_i * 4.0 + float(hit)) * beat * MUSIC_RATE)
			var length := int(0.30 * MUSIC_RATE)
			var amp := 0.13 if float(hit) < 3.0 else 0.09
			for j in length:
				var t2 := float(j) / MUSIC_RATE
				var v2 := (sin(TAU * root * t2) + 0.4 * sin(TAU * root * 2.0 * t2)) * exp(-t2 * 6.0) * amp
				b[(onset + j) % n] += v2

	# Melody: 64 eighth-note slots, hand-written (0 = rest).
	var melody := [
		659.26, 0.0, 783.99, 0.0, 1046.5, 0.0, 987.77, 880.0,
		880.0, 0.0, 659.26, 0.0, 523.25, 587.33, 659.26, 0.0,
		698.46, 0.0, 880.0, 0.0, 1046.5, 0.0, 880.0, 783.99,
		783.99, 0.0, 987.77, 0.0, 1174.66, 0.0, 987.77, 783.99,
		659.26, 783.99, 0.0, 659.26, 523.25, 0.0, 587.33, 659.26,
		440.0, 523.25, 659.26, 0.0, 880.0, 0.0, 783.99, 659.26,
		698.46, 0.0, 523.25, 0.0, 440.0, 698.46, 783.99, 880.0,
		783.99, 698.46, 587.33, 493.88, 392.0, 0.0, 587.33, 493.88,
	]
	var eighth := beat * 0.5
	for slot in melody.size():
		var freq: float = melody[slot]
		if freq <= 0.0:
			continue
		var onset := int(slot * eighth * MUSIC_RATE)
		var length := int(0.42 * MUSIC_RATE)
		for j in length:
			var t3 := float(j) / MUSIC_RATE
			var vib := t3 + 0.0022 * sin(TAU * 5.2 * t3)
			var v3 := sin(TAU * freq * vib) + 0.35 * sin(TAU * freq * 2.0 * vib)
			b[(onset + j) % n] += v3 * exp(-t3 * 6.5) * 0.155

	# Brushed offbeat ticks.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for beat_i in bars * 4:
		var onset := int((float(beat_i) + 0.5) * beat * MUSIC_RATE)
		for j in int(0.02 * MUSIC_RATE):
			var t4 := float(j) / MUSIC_RATE
			b[(onset + j) % n] += (rng.randf() * 2.0 - 1.0) * exp(-t4 * 160.0) * 0.05

	_normalize(b, 0.8)
	return _pack(b, MUSIC_RATE, true)


## Swap the soundtrack to the wistful discovery theme (the finale).
func play_discovery_music() -> void:
	if _music_player == null:
		return
	_music_player.stream = _make_discovery_music()
	_music_player.volume_db = MUSIC_DB - 1.0
	_music_player.play()


## Slow, dreamy, hopeful: a maj7 pad drift (C - Em - Am - F) with a sparse
## high bell twinkle and no percussion. Thematically kin to the main loop,
## but suspended and wide — for the mystery at the bottom of the world.
func _make_discovery_music() -> AudioStreamWAV:
	var bar := 3.4
	var bars := 4
	var dur := bar * bars
	var n := int(dur * MUSIC_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	# maj7/min7 voicings, one per bar, breathing in and out slowly.
	var chords := [
		[261.63, 329.63, 392.0, 493.88],   # Cmaj7
		[164.81, 246.94, 329.63, 392.0],   # Em7
		[220.0, 261.63, 329.63, 392.0],    # Am7
		[174.61, 261.63, 349.23, 440.0],   # Fmaj7
	]
	for i in n:
		var t := float(i) / MUSIC_RATE
		var bar_i := int(t / bar) % 4
		var bar_pos := fmod(t, bar) / bar
		var env := sin(bar_pos * PI)  # swell in and out across the bar
		var chord: Array = chords[bar_i]
		var v := 0.0
		for f in chord:
			v += sin(TAU * float(f) * t) + 0.3 * sin(TAU * float(f) * 2.0 * t)
		b[i] = v * 0.020 * env
	# A sparse bell twinkle high above, seeded so it loops the same.
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var bells := [1046.5, 1318.5, 1568.0, 1975.5, 2093.0]
	for k in 14:
		var onset := int(rng.randf() * dur * MUSIC_RATE)
		var freq: float = bells[rng.randi() % bells.size()]
		var length := int(1.1 * MUSIC_RATE)
		for j in length:
			var t2 := float(j) / MUSIC_RATE
			var v2 := sin(TAU * freq * t2) * exp(-t2 * 2.4) * 0.06
			b[(onset + j) % n] += v2
	_normalize(b, 0.7)
	return _pack(b, MUSIC_RATE, true)


func _make_wind() -> AudioStreamWAV:
	var dur := 5.0
	var n := int(dur * MUSIC_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var y := 0.0
	for i in n:
		var x := rng.randf() * 2.0 - 1.0
		y = (y + 0.045 * x) * 0.998
		b[i] = y
	_normalize(b, 0.5)
	var fade := int(0.3 * MUSIC_RATE)
	for k in fade:
		var w := float(k) / fade
		b[n - fade + k] = lerpf(b[n - fade + k], b[k], w)
	return _pack(b, MUSIC_RATE, true)
