class_name AudioManager
extends Node

var _bgm_player: AudioStreamPlayer
var _amb_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _last_played_ms: Dictionary = {}
var _bgm_game: AudioStream
var _bgm_title: AudioStream
var _amb_nature: AudioStream
var muted: bool = false
var master_volume: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = -18.0
	add_child(_bgm_player)

	_amb_player = AudioStreamPlayer.new()
	_amb_player.volume_db = -25.0
	add_child(_amb_player)

	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.volume_db = -10.0
		add_child(p)
		_sfx_pool.append(p)

	# Rich living Foley, organic impacts & natural human effort sounds (100% bundled offline CC0)
	var map := {
		"jump": "res://assets/audio/clean_jump.wav",
		"double_jump": "res://assets/audio/clean_double_jump.wav",
		"land": "res://assets/audio/clean_land.wav",
		"slide": "res://assets/audio/clean_slide.wav",
		"coin": "res://assets/audio/foley/coin_jingle.ogg",
		"gem": "res://assets/audio/clean_gem.wav",
		"boost": "res://assets/audio/clean_boost.wav",
		"rescue": "res://assets/audio/sfx_rescue.ogg",
		"hit": "res://assets/audio/foley/hit_soft.ogg",
		"hit_heavy": "res://assets/audio/foley/hit_heavy.ogg",
		"metal_hit": "res://assets/audio/foley/metal_hit.ogg",
		"sword_whoosh_1": "res://assets/audio/foley/sword_slice_1.ogg",
		"sword_whoosh_2": "res://assets/audio/foley/sword_slice_2.ogg",
		"sword_draw": "res://assets/audio/foley/sword_draw.ogg",
		"gate_open": "res://assets/audio/foley/gate_open.ogg",
		"gate_creak": "res://assets/audio/foley/gate_creak.ogg",
		"gate_slam": "res://assets/audio/foley/gate_close.ogg",
		"gate_thud": "res://assets/audio/foley/gate_thud.ogg",
		"step_grass_1": "res://assets/audio/foley/step_grass_1.ogg",
		"step_grass_2": "res://assets/audio/foley/step_grass_2.ogg",
		"step_stone_1": "res://assets/audio/foley/step_stone_1.ogg",
		"step_stone_2": "res://assets/audio/foley/step_stone_2.ogg",
		"water_splash_1": "res://assets/audio/foley/water_splash_1.wav",
		"water_splash_2": "res://assets/audio/foley/water_splash_2.wav",
		"water_plunge": "res://assets/audio/foley/water_plunge.wav",
		"voice_hah_f": "res://assets/audio/foley/voice_hah_f.wav",
		"voice_hah_m": "res://assets/audio/foley/voice_hah_m.wav",
		"voice_hurt_f": "res://assets/audio/foley/voice_hurt_f.wav",
		"voice_hurt_m": "res://assets/audio/foley/voice_hurt_m.wav",
		"lose": "res://assets/audio/sfx_lose.ogg",
		"win": "res://assets/audio/sfx_win.ogg",
		"click": "res://assets/audio/clean_click.wav",
	}
	for k in map.keys():
		if ResourceLoader.exists(map[k]):
			_streams[k] = load(map[k])

	if ResourceLoader.exists("res://assets/audio/bgm_haneen.mp3"):
		_bgm_game = load("res://assets/audio/bgm_haneen.mp3")
		if _bgm_game is AudioStreamMP3:
			(_bgm_game as AudioStreamMP3).loop = true
	if ResourceLoader.exists("res://assets/audio/bgm_title.ogg"):
		_bgm_title = load("res://assets/audio/bgm_title.ogg")
		if _bgm_title is AudioStreamOggVorbis:
			(_bgm_title as AudioStreamOggVorbis).loop = true
	if ResourceLoader.exists("res://assets/audio/foley/birds_forest_raw.ogg"):
		_amb_nature = load("res://assets/audio/foley/birds_forest_raw.ogg")
		if _amb_nature is AudioStreamOggVorbis:
			(_amb_nature as AudioStreamOggVorbis).loop = true


func start_title_bgm() -> void:
	if _bgm_title == null:
		return
	if _bgm_player.stream != _bgm_title:
		_bgm_player.stream = _bgm_title
	_bgm_player.volume_db = -19.0
	if not _bgm_player.playing:
		_bgm_player.play()
	_bgm_player.stream_paused = muted


func start_bgm() -> void:
	if _bgm_game == null:
		return
	if _bgm_player.stream != _bgm_game:
		_bgm_player.stream = _bgm_game
	_bgm_player.volume_db = -18.0
	if not _bgm_player.playing:
		_bgm_player.play()
	_bgm_player.stream_paused = muted


func set_paused_duck(paused: bool) -> void:
	_bgm_player.volume_db = -26.0 if paused else -18.0
	if _amb_player:
		_amb_player.stream_paused = paused or muted


func stop_bgm() -> void:
	_bgm_player.stop()


func set_nature_ambience(active: bool) -> void:
	if _amb_player == null or _amb_nature == null:
		return
	if active:
		if _amb_player.stream != _amb_nature:
			_amb_player.stream = _amb_nature
		_amb_player.volume_db = -24.5
		if not _amb_player.playing:
			_amb_player.play()
		_amb_player.stream_paused = muted
	else:
		_amb_player.stop()


func set_muted(val: bool) -> void:
	muted = val
	_bgm_player.stream_paused = muted
	if _amb_player:
		_amb_player.stream_paused = muted


func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Master")
	if master_volume <= 0.005:
		if bus >= 0:
			AudioServer.set_bus_mute(bus, true)
		set_muted(true)
	else:
		if bus >= 0:
			AudioServer.set_bus_mute(bus, false)
			AudioServer.set_bus_volume_db(bus, linear_to_db(master_volume))
		set_muted(false)


func play_variant(names: Array[String], pitch_min: float = 0.94, pitch_max: float = 1.07, vol_db: float = -10.0, cooldown_ms: int = 90) -> void:
	if names.is_empty():
		return
	var pick := names[randi() % names.size()]
	play(pick, randf_range(pitch_min, pitch_max), vol_db, cooldown_ms)


func play_hero_voice(char_id: String, kind: String = "effort") -> void:
	var is_fem := (char_id == "haneen")
	if kind == "hurt":
		play("voice_hurt_f" if is_fem else "voice_hurt_m", randf_range(0.96, 1.05), -8.0, 280)
	else:
		play("voice_hah_f" if is_fem else "voice_hah_m", randf_range(0.95, 1.06), -9.5, 220)


func play(sfx_name: String, pitch_scale: float = 1.0, vol_db: float = -10.0, min_cooldown_ms: int = 90) -> void:
	if muted or not _streams.has(sfx_name):
		return
	var now := Time.get_ticks_msec()
	var prev: int = _last_played_ms.get(sfx_name, -9999)
	if now - prev < min_cooldown_ms:
		return
	_last_played_ms[sfx_name] = now

	for p in _sfx_pool:
		if not p.playing:
			p.stream = _streams[sfx_name]
			p.pitch_scale = pitch_scale
			p.volume_db = vol_db
			p.play()
			return
	var p0 := _sfx_pool[0]
	p0.stream = _streams[sfx_name]
	p0.pitch_scale = pitch_scale
	p0.volume_db = vol_db
	p0.play()
