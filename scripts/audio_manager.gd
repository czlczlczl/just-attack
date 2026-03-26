## 音效管理器 - 使用 AudioStreamGenerator 生成程序音效
## AutoLoad 单例，通过 AudioManager 访问
extends Node

## 音效生成器缓存
var _sound_generators: Dictionary = {}

## 音效播放器池
var _audio_players: Array[AudioStreamPlayer] = []
var _player_index: int = 0

func _ready() -> void:
	print("[AudioManager] Initialized")
	_initialize_generators()
	_initialize_audio_pool()

## 初始化音效生成器（预生成所有音效）
func _initialize_generators() -> void:
	_sound_generators["jump"] = _create_frequency_sweep(400, 800, 0.1)
	_sound_generators["attack"] = _create_noise_burst(0.15)
	_sound_generators["hurt"] = _create_square_wave(150, 0.2)
	_sound_generators["spawn"] = _create_pitch_slide(200, 600, 0.3)
	_sound_generators["death"] = _create_frequency_sweep(400, 100, 0.5)

## 初始化音效播放器池
func _initialize_audio_pool() -> void:
	# 创建 5 个音效播放器用于并发播放
	for i in range(5):
		var player = AudioStreamPlayer.new()
		add_child(player)
		_audio_players.append(player)

## 获取下一个可用的音效播放器
func _get_next_player() -> AudioStreamPlayer:
	var player = _audio_players[_player_index]
	_player_index = (_player_index + 1) % _audio_players.size()
	return player

## 播放跳跃音效 (频率扫描 400Hz -> 800Hz)
func play_jump_sound() -> void:
	_play_sound("jump")

## 播放攻击音效 (噪音爆发)
func play_attack_sound() -> void:
	_play_sound("attack")

## 播放受伤音效 (方波 150Hz)
func play_hurt_sound() -> void:
	_play_sound("hurt")

## 播放怪物生成音效 (滑音 200Hz -> 600Hz)
func play_spawn_sound() -> void:
	_play_sound("spawn")

## 播放死亡音效 (频率下降 400Hz -> 100Hz)
func play_death_sound() -> void:
	_play_sound("death")

## 播放指定音效
func _play_sound(sound_name: String) -> void:
	if not _sound_generators.has(sound_name):
		print("[AudioManager] Sound not found: ", sound_name)
		return

	var player = _get_next_player()
	if player.playing:
		player.stop()
	player.stream = _sound_generators[sound_name]
	player.play()

## 创建频率扫描音效
func _create_frequency_sweep(from_hz: float, to_hz: float, duration: float) -> AudioStreamGeneratorPlayback:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var playback: AudioStreamGeneratorPlayback = generator.instantiate_playback()
	_generate_sound(playback, from_hz, to_hz, duration, "sweep")
	return playback

## 创建噪音爆发音效
func _create_noise_burst(duration: float) -> AudioStreamGeneratorPlayback:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var playback: AudioStreamGeneratorPlayback = generator.instantiate_playback()
	_generate_sound(playback, 0, 0, duration, "noise")
	return playback

## 创建方波音效
func _create_square_wave(frequency: float, duration: float) -> AudioStreamGeneratorPlayback:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	var playback: AudioStreamGeneratorPlayback = generator.instantiate_playback()
	_generate_sound(playback, frequency, frequency, duration, "square")
	return playback

## 创建滑音音效
func _create_pitch_slide(from_hz: float, to_hz: float, duration: float) -> AudioStreamGeneratorPlayback:
	return _create_frequency_sweep(from_hz, to_hz, duration)

## 生成声音数据
func _generate_sound(playback: AudioStreamGeneratorPlayback, from_hz: float, to_hz: float, duration: float, type: String) -> void:
	var sample_count = int(44100 * duration)
	for i in range(sample_count):
		var t = float(i) / sample_count
		var sample: float = 0.0

		match type:
			"sweep":
				var freq = from_hz + (to_hz - from_hz) * t
				sample = sin(PI * 2 * freq * t)
			"noise":
				sample = randf_range(-1, 1) * (1.0 - t)  # 噪音衰减
			"square":
				var wave = sin(PI * 2 * from_hz * t)
				sample = 1.0 if wave > 0 else -1.0
				sample *= (1.0 - t)  # 衰减

		playback.push_frame(Vector2(sample, sample))
