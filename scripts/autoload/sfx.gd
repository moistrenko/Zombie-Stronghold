extends Node

## Lightweight procedural SFX (AudioStreamWAV). Works on mobile export — no editor-only APIs.

const SAMPLE_RATE := 22050
const POOL_SIZE := 8

enum SfxId { PLACE, SHOOT, HIT, KILL, WALL_HIT, VICTORY, DEFEAT }

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _bus_name: StringName = &"Master"
var _muted: bool = false


func _ready() -> void:
	_streams[SfxId.PLACE] = _build_blip(880.0, 0.07, 0.28, 0.0)
	_streams[SfxId.SHOOT] = _build_noise_burst(0.045, 0.18, 1800.0, 400.0)
	_streams[SfxId.HIT] = _build_blip(220.0, 0.05, 0.22, -8.0)
	_streams[SfxId.KILL] = _build_kill_pop(0.12, 0.26)
	_streams[SfxId.WALL_HIT] = _build_noise_burst(0.09, 0.32, 120.0, 60.0)
	_streams[SfxId.VICTORY] = _build_arpeggio([523.25, 659.25, 783.99], 0.1, 0.22)
	_streams[SfxId.DEFEAT] = _build_arpeggio([392.0, 311.13, 246.94], 0.14, 0.26)

	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = _bus_name
		player.volume_db = -6.0
		add_child(player)
		_players.append(player)


func play(id: SfxId, volume_db: float = 0.0) -> void:
	if _muted or not _streams.has(id):
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[id]
	player.volume_db = -6.0 + volume_db
	player.play()


func is_muted() -> bool:
	return _muted


func set_muted(value: bool) -> void:
	_muted = value
	var bus_idx := AudioServer.get_bus_index(_bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_mute(bus_idx, _muted)


func play_place() -> void:
	play(SfxId.PLACE, 1.0)


func play_shoot() -> void:
	play(SfxId.SHOOT, -1.0)


func play_hit() -> void:
	play(SfxId.HIT, 0.0)


func play_kill() -> void:
	play(SfxId.KILL, 2.0)


func play_wall_hit() -> void:
	play(SfxId.WALL_HIT, 3.0)


func play_victory() -> void:
	play(SfxId.VICTORY, 2.0)


func play_defeat() -> void:
	play(SfxId.DEFEAT, 1.0)


func _build_blip(freq: float, duration: float, amp: float, slide_semitones: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var env := 1.0 - (float(i) / float(sample_count))
		env *= env
		var f := freq * pow(2.0, (slide_semitones * (float(i) / float(sample_count))) / 12.0)
		var sample := sin(TAU * f * t) * amp * env
		_write_pcm16(data, i, sample)
	return _make_stream(data)


func _build_noise_burst(duration: float, amp: float, start_hp: float, end_hp: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var prev := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in sample_count:
		var t := float(i) / float(maxi(sample_count - 1, 1))
		var env := 1.0 - t
		env *= env
		var hp := lerpf(start_hp, end_hp, t)
		var alpha := clampf(hp / float(SAMPLE_RATE), 0.01, 0.95)
		var white := rng.randf_range(-1.0, 1.0)
		prev = prev + alpha * (white - prev)
		_write_pcm16(data, i, prev * amp * env)
	return _make_stream(data)


func _build_kill_pop(duration: float, amp: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var env := 1.0 - (float(i) / float(sample_count))
		env = env * env
		var f := lerpf(420.0, 90.0, float(i) / float(sample_count))
		var sample := (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.3) * amp * env
		_write_pcm16(data, i, sample)
	return _make_stream(data)


func _build_arpeggio(freqs: Array, note_len: float, amp: float) -> AudioStreamWAV:
	var total := note_len * float(freqs.size())
	var sample_count := int(SAMPLE_RATE * total)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var note_samples := int(SAMPLE_RATE * note_len)
	for i in sample_count:
		var note_i := mini(i / note_samples, freqs.size() - 1)
		var local_i := i % note_samples
		var t := float(local_i) / float(SAMPLE_RATE)
		var env := 1.0 - (float(local_i) / float(note_samples))
		env *= env
		var f: float = freqs[note_i]
		var sample := sin(TAU * f * t) * amp * env
		_write_pcm16(data, i, sample)
	return _make_stream(data)


func _write_pcm16(data: PackedByteArray, index: int, sample: float) -> void:
	var clamped := clampf(sample, -1.0, 1.0)
	var pcm := int(clamped * 32767.0)
	var byte_i := index * 2
	data[byte_i] = pcm & 0xFF
	data[byte_i + 1] = (pcm >> 8) & 0xFF


func _make_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
