extends Node
## All audio is synthesized at startup — the repo contains no audio files.
## Sounds are rendered once into AudioStreamWAV buffers and played from a pool.

const SFX_RATE := 22050
const MUSIC_RATE := 12000

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_start_loop("music", -13.0)
	_start_loop("wind", -30.0)


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
	_streams["music"] = _make_music()
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
	# click
	for i in int(0.012 * SFX_RATE):
		b[i] += (rng.randf() * 2.0 - 1.0) * (1.0 - float(i) / (0.012 * SFX_RATE)) * 0.8
	# ping
	for i in int(0.28 * SFX_RATE):
		var t := float(i) / SFX_RATE
		b[int(0.02 * SFX_RATE) + i] += sin(TAU * 1244.5 * t) * exp(-t * 12.0) * 0.3
	# receipt ratchet
	for click_i in 14:
		var onset := int((0.36 + click_i * 0.028) * SFX_RATE)
		for j in int(0.004 * SFX_RATE):
			if onset + j < n:
				b[onset + j] += (rng.randf() * 2.0 - 1.0) * 0.22
	# ding
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


## Gentle generative pentatonic loop. Note tails wrap around the buffer,
## and pad frequencies are quantized to whole cycles, so the loop is seamless.
func _make_music() -> AudioStreamWAV:
	var bpm := 96.0
	var beat := 60.0 / bpm
	var bars := 8
	var dur := beat * 4.0 * bars
	var n := int(dur * MUSIC_RATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260703
	# Pad drone: C3 + G3, quantized so freq * dur is an integer cycle count.
	var pad_a := roundf(130.81 * dur) / dur
	var pad_b := roundf(196.0 * dur) / dur
	for i in n:
		var t := float(i) / MUSIC_RATE
		var swell := 0.7 + 0.3 * sin(TAU * 4.0 * t / dur)
		b[i] = (sin(TAU * pad_a * t) * 0.05 + sin(TAU * pad_b * t) * 0.032) * swell
	# Sparse plucked pentatonic melody on an eighth-note grid.
	var notes := [261.63, 293.66, 329.63, 392.0, 440.0, 523.25, 587.33, 659.26]
	var slots := bars * 8
	var eighth := beat / 2.0
	for slot in slots:
		if rng.randf() > 0.38:
			continue
		var freq: float = notes[rng.randi_range(0, notes.size() - 1)]
		var onset := int(slot * eighth * MUSIC_RATE)
		var length := int(1.1 * MUSIC_RATE)
		var amp := rng.randf_range(0.10, 0.17)
		for j in length:
			var t := float(j) / MUSIC_RATE
			var a := exp(-t * 4.5) * amp
			var v := sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 2.0 * t) + 0.12 * sin(TAU * freq * 3.0 * t)
			b[(onset + j) % n] += v * a
	_normalize(b, 0.8)
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
	# Crossfade the tail into the head so the loop point is inaudible.
	var fade := int(0.3 * MUSIC_RATE)
	for k in fade:
		var w := float(k) / fade
		b[n - fade + k] = lerpf(b[n - fade + k], b[k], w)
	return _pack(b, MUSIC_RATE, true)
