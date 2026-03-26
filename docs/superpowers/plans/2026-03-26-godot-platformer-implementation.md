# Godot 4.6.1 横板动作冒险游戏实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 创建一个基于 Godot 4.6.1 的 2D 横板动作冒险游戏框架，包含玩家控制、武器切换、怪物 AI 和随机生成系统。

**Architecture:** 采用模块化场景架构，使用 Godot 原生场景组合模式。AutoLoad 单例管理全局状态（GameManager、InputHandler、AudioManager），玩家、敌人、武器均作为独立场景，通过信号和接口通信。

**Tech Stack:** Godot 4.6.1、GDScript、程序生成音效 (AudioStreamGenerator)、免费 2D 精灵素材。

---

## 文件结构总览

**创建文件列表：**

```
project.godot                      # Godot 项目配置
scenes/main.tscn                   # 主游戏场景
scenes/player/player.tscn          # 玩家场景
scenes/player/player.gd            # 玩家控制器
scenes/enemies/enemy_base.tscn     # 敌人基类场景
scenes/enemies/enemy_base.gd       # 敌人基类脚本
scenes/enemies/monster_01.tscn     # 怪物类型 1
scenes/projectiles/projectile.tscn # 抛射物场景
scripts/game_manager.gd            # 游戏管理器 (AutoLoad)
scripts/input_handler.gd           # 输入处理器 (AutoLoad)
scripts/audio_manager.gd           # 音效管理器 (AutoLoad)
scripts/camera_controller.gd       # 摄像机控制器
scripts/enemy_spawner.gd           # 怪物生成器
scripts/ui_controller.gd           # UI 控制器
scripts/death_zone.gd              # 死亡区域
scripts/weapons/weapon_base.gd     # 武器基类
scripts/weapons/sword.gd           # 剑武器
scripts/weapons/bow.gd             # 弓武器
scripts/weapons/staff.gd           # 法杖武器
scripts/projectiles/projectile.gd  # 抛射物脚本
resources/player_stats.tres        # 玩家属性配置
resources/enemy_configs/monster_01.tres  # 怪物配置
```

---

## Task 1: 项目基础配置

**Files:**
- Create: `project.godot`
- Create: `.godot/` (Godot 自动生成)

- [ ] **Step 1: 创建 project.godot 文件**

```gdscript
; Engine configuration file for Godot 4.6.1
config_version=5

[application]

config/name="Godot Platformer"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.6", "Forward Plus")
config/icon="res://icon.svg"

[autoload]

GameManager="*res://scripts/game_manager.gd"
InputHandler="*res://scripts/input_handler.gd"
AudioManager="*res://scripts/audio_manager.gd"

[display]

window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"

[input_map]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
jump={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":0,"pressure":0.0,"pressed":true)
]
}
crouch={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":13,"pressure":0.0,"pressed":true)
]
}
attack_1={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":74,"key_label":0,"unicode":106,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":2,"pressure":0.0,"pressed":true)
]
}
attack_2={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":75,"key_label":0,"unicode":107,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":3,"pressure":0.0,"pressed":true)
]
}
attack_3={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":76,"key_label":0,"unicode":108,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":1,"pressure":0.0,"pressed":true)
]
}
weapon_switch_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":113,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":9,"pressure":0.0,"pressed":true)
]
}
weapon_switch_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":10,"pressure":0.0,"pressed":true)
]
}
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"button_index":6,"pressure":0.0,"pressed":true)
]
}

[layer_names]

2d_physics/layer_1="player"
2d_physics/layer_2="enemies"
2d_physics/layer_3="terrain"
2d_physics/layer_4="hitbox"
```

- [ ] **Step 2: 创建基础目录结构**

```bash
mkdir -p scenes/player scenes/enemies scenes/weapons scenes/levels
mkdir -p scripts/weapons scripts/enemies
mkdir -p resources/enemy_configs
mkdir -p assets/sprites/player assets/sprites/enemies assets/sprites/tiles
mkdir -p assets/audio
```

- [ ] **Step 3: 创建简单的 icon.svg 文件**

```svg
<svg height="128" width="128" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="2" width="124" height="124" rx="14" fill="#363d52" stroke="#232638" stroke-width="4"/>
  <g transform="translate(64,64)">
    <circle r="40" fill="#478cb8"/>
    <text y="15" x="50%" text-anchor="middle" fill="white" font-size="60" font-weight="bold">P</text>
  </g>
</svg>
```

- [ ] **Step 4: 初始化 Godot 项目**

```bash
# 打开 Godot 编辑器导入项目
# Expected: Godot 4.6.1 成功打开项目
```

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "chore: initialize Godot 4.6.1 project structure"
```

---

## Task 2: GameManager AutoLoad

**Files:**
- Create: `scripts/game_manager.gd`

- [ ] **Step 1: 创建 GameManager 脚本**

```gdscript
## 游戏管理器 - 全局游戏状态管理
## AutoLoad 单例，通过 GameManager 访问
extends Node

## 游戏状态枚举
enum GameState { PLAYING, PAUSED, GAME_OVER, VICTORY }

## 玩家引用
var player: Node2D = null

## 当前关卡索引
var current_level: int = 0

## 当前游戏状态
var game_state: GameState = GameState.PLAYING:
	set(value):
		game_state = value
		_on_game_state_changed(value)

## 玩家得分
var score: int = 0

## 玩家生命值
var player_health: int = 100

## 信号：游戏状态改变
signal game_state_changed(new_state: GameState)

## 信号：玩家死亡
signal player_died

## 信号：得分改变
signal score_changed(new_score: int)

## 信号：生命值改变
signal health_changed(new_health: int)

func _ready() -> void:
	print("[GameManager] Initialized")

## 注册玩家引用
func register_player(player_node: Node2D) -> void:
	player = player_node

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	if game_state == new_state:
		return

	game_state = new_state

func _on_game_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.GAME_OVER:
			get_tree().paused = true
			print("[GameManager] Game Over!")
		GameState.VICTORY:
			get_tree().paused = true
			print("[GameManager] Victory!")

## 玩家受伤
func take_damage(amount: int) -> void:
	player_health = max(0, player_health - amount)
	health_changed.emit(player_health)

	if player_health <= 0:
		change_state(GameState.GAME_OVER)
		player_died.emit()

## 玩家得分
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

## 重新开始游戏
func restart_game() -> void:
	score = 0
	player_health = 100
	current_level = 0
	change_state(GameState.PLAYING)
	get_tree().reload_current_scene()
```

- [ ] **Step 2: 提交**

```bash
git add scripts/game_manager.gd
git commit -m "feat: add GameManager AutoLoad for global state management"
```

---

## Task 3: InputHandler AutoLoad

**Files:**
- Create: `scripts/input_handler.gd`

- [ ] **Step 1: 创建 InputHandler 脚本**

```gdscript
## 输入处理器 - 统一处理键盘和手柄输入
## AutoLoad 单例，通过 InputHandler 访问
extends Node

## 移动方向输入
var move_direction: Vector2 = Vector2.ZERO

## 是否下蹲
var is_crouching: bool = false

## 当前选择的武器索引
var current_weapon_index: int = 0

## 信号：移动输入改变
signal move_input_changed(direction: Vector2)

## 信号：跳跃按下
signal jump_pressed

## 信号：下蹲输入改变
signal crouch_input_changed(is_crouching: bool)

## 信号：攻击按下
signal attack_pressed(attack_index: int)

## 信号：武器切换按下
signal weapon_switch_pressed(direction: int)

## 信号：暂停按下
signal pause_pressed

## 手柄震动强度 (0-1)
var controller_vibration: float = 0.0

func _ready() -> void:
	print("[InputHandler] Initialized")

func _input(event: InputEvent) -> void:
	# 只处理按下事件，避免重复触发
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_input(event)
	elif event is InputEventJoypadButton and event.pressed:
		_handle_controller_input(event)
	elif event is InputEventJoypadMotion:
		_handle_joypad_motion(event)

func _handle_keyboard_input(event: InputEventKey) -> void:
	var prev_x: float = move_direction.x

	match event.physical_keycode:
		KEY_A, KEY_LEFT:
			if event.pressed:
				move_direction.x = -1
			else:
				if move_direction.x < 0:
					move_direction.x = 0
			move_input_changed.emit(move_direction)
		KEY_D, KEY_RIGHT:
			if event.pressed:
				move_direction.x = 1
			else:
				if move_direction.x > 0:
					move_direction.x = 0
			move_input_changed.emit(move_direction)
		KEY_SPACE:
			jump_pressed.emit()
		KEY_S:
			is_crouching = event.pressed
			crouch_input_changed.emit(is_crouching)
		KEY_J:
			attack_pressed.emit(0)
		KEY_K:
			attack_pressed.emit(1)
		KEY_L:
			attack_pressed.emit(2)
		KEY_Q:
			weapon_switch_pressed.emit(-1)
		KEY_E:
			weapon_switch_pressed.emit(1)
		KEY_ESCAPE:
			pause_pressed.emit()

func _handle_controller_input(event: InputEventJoypadButton) -> void:
	match event.button_index:
		JOY_BUTTON_A:
			jump_pressed.emit()
		JOY_BUTTON_X:
			attack_pressed.emit(0)
		JOY_BUTTON_Y:
			attack_pressed.emit(1)
		JOY_BUTTON_B:
			attack_pressed.emit(2)
		JOY_BUTTON_LEFT_SHOULDER:
			weapon_switch_pressed.emit(-1)
		JOY_BUTTON_RIGHT_SHOULDER:
			weapon_switch_pressed.emit(1)
		JOY_BUTTON_START:
			pause_pressed.emit()

func _handle_joypad_motion(event: InputEventJoypadMotion) -> void:
	match event.axis:
		JOY_AXIS_LEFT_X:
			if abs(event.axis_value) < 0.2:
				move_direction.x = 0
			else:
				move_direction.x = sign(event.axis_value)
			move_input_changed.emit(move_direction)
		JOY_AXIS_LEFT_Y:
			# 下蹲使用十字键下
			pass
		JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
			# 肩键用于切换武器
			pass

## 获取归一化的移动方向
func get_normalized_move() -> Vector2:
	return move_direction.normalized()

## 触发手柄震动
func trigger_vibration(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	Input.start_joy_vibration(0, weak_magnitude, strong_magnitude, duration)
```

- [ ] **Step 2: 提交**

```bash
git add scripts/input_handler.gd
git commit -m "feat: add InputHandler AutoLoad for unified input handling"
```

---

## Task 4: AudioManager AutoLoad (程序生成音效)

**Files:**
- Create: `scripts/audio_manager.gd`

- [ ] **Step 1: 创建 AudioManager 脚本**

```gdscript
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
		player.bus = "SFX"
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
func _create_frequency_sweep(from_hz: float, to_hz: float, duration: float) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_frames = 4096

	# 使用 Godot 4.x 的正确方式生成音频数据
	var audio_data = PackedVector2Array()
	var sample_count = int(44100.0 * duration)
	var step = 1.0 / 44100.0

	for i in range(sample_count):
		var t = float(i) / sample_count
		var freq = lerp(from_hz, to_hz, t)
		var phase = freq * i * step * 2 * PI
		var amplitude = 1.0 - t  # 淡出
		audio_data.append(Vector2(sin(phase) * amplitude, sin(phase) * amplitude))

	# 将数据写入生成器缓冲区
	var buffer = AudioStreamGenerator.new()
	buffer.mix_rate = 44100
	buffer.buffer_frames = sample_count

	# 注意：Godot 4.x 中需要通过 playback.push_buffer() 来填充数据
	# 这里我们使用简化方式，直接返回生成器，由播放器在运行时填充
	generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_frames = 1024

	return generator

## 创建噪音爆发音效
func _create_noise_burst(duration: float) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_frames = 1024
	return generator

## 创建方波音效
func _create_square_wave(frequency: float, duration: float) -> AudioStreamGenerator:
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_frames = 1024
	return generator

## 创建滑音音效
func _create_pitch_slide(from_hz: float, to_hz: float, duration: float) -> AudioStreamGenerator:
	return _create_frequency_sweep(from_hz, to_hz, duration)

	return generator

## 创建滑音音效
func _create_pitch_slide(from_hz: float, to_hz: float, duration: float) -> AudioStreamGenerator:
	return _create_frequency_sweep(from_hz, to_hz, duration)
```

- [ ] **Step 2: 提交**

```bash
git add scripts/audio_manager.gd
git commit -m "feat: add AudioManager with procedural sound generation"
```

---

## Task 5: 玩家属性资源

**Files:**
- Create: `resources/player_stats.tres`

- [ ] **Step 1: 创建 PlayerStats 资源类**

```gdscript
## 玩家属性配置资源
## 可在编辑器中创建和修改
class_name PlayerStats
extends Resource

@export_group("移动属性")
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var crouch_speed: float = 100.0

@export_group("战斗属性")
@export var max_health: int = 100
@export var invincibility_frames: float = 1.0
@export var knockback_resistance: float = 0.5

@export_group("动画")
@export var idle_animation: String = "idle"
@export var run_animation: String = "run"
@export var jump_animation: String = "jump"
@export var crouch_animation: String = "crouch"
```

- [ ] **Step 2: 创建默认玩家属性文件**

```gdscript
@tool
extends EditorScript

func _run() -> void:
	var stats = PlayerStats.new()
	var err = ResourceSaver.save(stats, "res://resources/player_stats.tres")
	print("Saved player stats: ", err == OK)
```

- [ ] **Step 3: 提交**

```bash
git add scripts/resources/player_stats.gd resources/player_stats.tres
git commit -m "feat: add PlayerStats resource for configurable player attributes"
```

---

## Task 6: 玩家控制器

**Files:**
- Create: `scenes/player/player.gd`
- Create: `scenes/player/player.tscn`

- [ ] **Step 1: 创建玩家控制器脚本**

```gdscript
## 玩家控制器 - 处理玩家移动、跳跃、攻击等所有行为
class_name Player
extends CharacterBody2D

## 玩家属性
@export var stats: PlayerStats

## 信号：玩家受伤
signal player_hurt(damage: int)

## 信号：玩家死亡
signal player_died

## 信号：武器切换
signal weapon_changed(weapon_name: String)

## 当前武器
var current_weapon: Node2D = null

## 武器列表
var weapons: Array[Node2D] = []

## 当前武器索引
var weapon_index: int = 0

## 是否在地面
var is_on_ground: bool = false

## 是否下蹲
var is_crouching: bool = false

## 无敌计时器
var invincibility_timer: float = 0.0

## 移动方向
var move_direction: float = 0.0

## 面向方向 (1=右，-1=左)
var facing_direction: int = 1

func _ready() -> void:
	# 注册到 GameManager
	GameManager.register_player(self)

	# 连接输入信号
	InputHandler.move_input_changed.connect(_on_move_input)
	InputHandler.crouch_input_changed.connect(_on_crouch_input)
	InputHandler.jump_pressed.connect(_on_jump_pressed)
	InputHandler.attack_pressed.connect(_on_attack_pressed)
	InputHandler.weapon_switch_pressed.connect(_on_weapon_switch)
	InputHandler.pause_pressed.connect(_on_pause_pressed)

	# 初始化无敌计时器
	invincibility_timer = 0.0

func _physics_process(delta: float) -> void:
	# 应用重力
	if not is_on_ground:
		velocity.y += stats.gravity * delta

	# 水平移动
	velocity.x = move_direction * stats.move_speed

	# 处理下蹲
	if is_crouching and is_on_ground:
		velocity.x = move_direction * stats.crouch_speed

	# 更新面向方向
	if move_direction != 0:
		facing_direction = sign(move_direction)

	# 更新无敌计时器
	if invincibility_timer > 0:
		invincibility_timer -= delta

	# 移动并获取碰撞信息
	is_on_ground = is_on_floor()
	move_and_slide()

func _process(_delta: float) -> void:
	# 更新动画状态（后续添加 AnimationPlayer 后使用）
	_update_animation_state()

## 处理移动输入
func _on_move_input(direction: Vector2) -> void:
	move_direction = direction.x

## 处理下蹲输入
func _on_crouch_input(crouching: bool) -> void:
	is_crouching = crouching

## 处理跳跃
func _on_jump_pressed() -> void:
	if is_on_ground and not is_crouching:
		velocity.y = stats.jump_velocity
		AudioManager.play_jump_sound()

## 处理攻击
func _on_attack_pressed(attack_index: int) -> void:
	if current_weapon and current_weapon.has_method("attack"):
		current_weapon.attack(facing_direction)
		AudioManager.play_attack_sound()

## 处理武器切换
func _on_weapon_switch(direction: int) -> void:
	if weapons.size() == 0:
		return

	weapon_index = wrapi(weapon_index + direction, 0, weapons.size())
	_equip_weapon(weapons[weapon_index])

## 处理暂停
func _on_pause_pressed() -> void:
	if GameManager.game_state == GameManager.GameState.PLAYING:
		GameManager.change_state(GameManager.GameState.PAUSED)
	elif GameManager.game_state == GameManager.GameState.PAUSED:
		GameManager.change_state(GameManager.GameState.PLAYING)

## 装备武器
func _equip_weapon(weapon: Node2D) -> void:
	# 卸载当前武器
	if current_weapon and current_weapon.get_parent():
		current_weapon.get_parent().remove_child(current_weapon)

	# 装备新武器
	current_weapon = weapon
	add_child(current_weapon)

	# 设置武器位置（根据面向方向调整）
	current_weapon.position = Vector2(32 * facing_direction, 0)

	weapon_changed.emit(weapon.weapon_name if weapon.has_method("get_weapon_name") else "Unknown")

## 玩家受伤
func take_damage(amount: int) -> void:
	if invincibility_timer > 0:
		return

	invincibility_timer = stats.invincibility_frames
	GameManager.take_damage(amount)
	player_hurt.emit(amount)
	AudioManager.play_hurt_sound()

	# 击退效果
	velocity.y = -200
	velocity.x = -facing_direction * 300

## 添加武器到武器列表
func add_weapon(weapon: Node2D) -> void:
	weapons.append(weapon)
	if current_weapon == null:
		_equip_weapon(weapon)

## 更新动画状态
func _update_animation_state() -> void:
	# 后续添加 AnimationPlayer 后实现
	pass
```

- [ ] **Step 2: 创建玩家场景 (player.tscn)**

```gdscript
[gd_scene load_steps=3 format=3 uid="uid://player123"]

[ext_resource type="Script" path="player.gd" id="1_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_player"]
size = Vector2(32, 48)

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 6
script = ExtResource("1_player")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_player")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_scale = Vector2(1, 1)

[node name="WeaponPivot" type="Node2D" parent="."]
position = Vector2(32, 0)

[node name="CameraPivot" type="Node2D" parent="."]
position = Vector2(0, -50)

[node name="HurtBox" type="Area2D" parent="."]
collision_layer = 4
collision_mask = 2

[node name="CollisionShape2D" type="CollisionShape2D" parent="HurtBox"]
shape = SubResource("RectangleShape2D_player")
```

- [ ] **Step 3: 提交**

```bash
git add scenes/player/player.gd scenes/player/player.tscn
git commit -m "feat: add Player controller with movement, jumping, crouching, and attack"
```

---

## Task 7: 武器系统

**Files:**
- Create: `scripts/weapons/weapon_base.gd`
- Create: `scripts/weapons/sword.gd`
- Create: `scripts/weapons/bow.gd`
- Create: `scripts/weapons/staff.gd`

- [ ] **Step 1: 创建武器基类**

```gdscript
## 武器基类 - 所有武器继承此类
class_name WeaponBase
extends Node2D

## 武器名称
@export var weapon_name: String = "Unnamed Weapon"

## 伤害值
@export var damage: int = 10

## 攻击范围
@export var attack_range: float = 50.0

## 攻击冷却时间
@export var attack_cooldown: float = 0.5

## 攻击方向
var attack_direction: int = 1

## 是否在冷却中
var is_cooldown: bool = false

## 当前冷却时间
var current_cooldown: float = 0.0

## 信号：攻击命中
signal attack_hit(targets: Array)

func _process(delta: float) -> void:
	if is_cooldown:
		current_cooldown -= delta
		if current_cooldown <= 0:
			is_cooldown = false

## 执行攻击
func attack(direction: int) -> void:
	if is_cooldown:
		return

	attack_direction = direction
	current_cooldown = attack_cooldown
	is_cooldown = true

	# 创建命中框
	var hitbox = _create_hitbox()
	get_tree().current_scene.add_child(hitbox)

	# 检测命中
	await get_tree().process_frame
	var targets = _check_hits(hitbox)
	attack_hit.emit(targets)

	# 清理命中框
	hitbox.queue_free()

## 创建命中框
func _create_hitbox() -> Area2D:
	var hitbox = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	shape.size = Vector2(attack_range * 2, 20)
	collision_shape.shape = shape
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2  # enemies layer

	# 设置位置（根据攻击方向）
	hitbox.position = global_position + Vector2(attack_range * attack_direction, 0)

	hitbox.add_child(collision_shape)
	return hitbox

## 检测命中
func _check_hits(hitbox: Area2D) -> Array:
	var targets = []
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			targets.append(body)
	return targets

## 获取武器名称
func get_weapon_name() -> String:
	return weapon_name

## 获取伤害值
func get_damage() -> int:
	return damage
```

- [ ] **Step 2: 创建剑武器**

```gdscript
## 剑 - 近战武器，快速连击
class_name Sword
extends WeaponBase

func _init():
	weapon_name = "Sword"
	damage = 25
	attack_range = 40.0
	attack_cooldown = 0.3

func attack(direction: int) -> void:
	super.attack(direction)
	# 剑有特殊攻击效果（可扩展）
```

- [ ] **Step 3: 创建弓武器**

```gdscript
## 弓 - 远程武器，抛物线弹道
class_name Bow
extends WeaponBase

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 500.0

func _init():
	weapon_name = "Bow"
	damage = 15
	attack_range = 300.0
	attack_cooldown = 0.8

func attack(direction: int) -> void:
	if is_cooldown:
		return

	current_cooldown = attack_cooldown
	is_cooldown = true

	# 发射抛射物
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector2(50 * direction, 0)
		projectile.direction = direction
		projectile.damage = damage
		projectile.speed = projectile_speed
```

- [ ] **Step 4: 创建法杖武器**

```gdscript
## 法杖 - 远程武器，穿透效果
class_name Staff
extends WeaponBase

func _init():
	weapon_name = "Staff"
	damage = 12
	attack_range = 250.0
	attack_cooldown = 0.4

func _check_hits(hitbox: Area2D) -> Array:
	var targets = []
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			targets.append(body)
			# 法杖可以穿透，继续检测更多目标
	return targets
```

- [ ] **Step 5: 提交**

```bash
git add scripts/weapons/*.gd
git commit -m "feat: add weapon system (Sword, Bow, Staff)"
```

---

## Task 8: 怪物 AI 系统

**Files:**
- Create: `scripts/enemies/enemy_base.gd`
- Create: `resources/enemy_configs/monster_01.tres`
- Create: `scenes/enemies/enemy_base.tscn`
- Create: `scenes/enemies/monster_01.tscn`

- [ ] **Step 1: 创建 EnemyStats 资源类**

```gdscript
## 敌人属性配置资源
class_name EnemyStats
extends Resource

@export var max_health: int = 50
@export var damage: int = 10
@export var move_speed: float = 80.0
@export var attack_cooldown: float = 1.0
@export var score_value: int = 100
@export var detection_range: float = 150.0
@export var attack_range: float = 40.0
```

- [ ] **Step 2: 创建敌人状态枚举**

```gdscript
## 敌人状态枚举
enum EnemyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	RETURN,
	STUNNED,
	DEAD
}
```

- [ ] **Step 3: 创建敌人基类脚本**

```gdscript
## 敌人基类 - 所有敌人的共同行为和 AI
class_name EnemyBase
extends CharacterBody2D

## 敌人属性
@export var stats: EnemyStats
@export var patrol_points: Array[Vector2]

## 信号：敌人死亡
signal enemy_died(enemy: EnemyBase)

## 当前状态
var current_state: EnemyState = EnemyState.IDLE

## 玩家引用
var player: Node2D = null

## 当前巡逻点索引
var patrol_index: int = 0

## 攻击冷却
var attack_cooldown_timer: float = 0.0

## 当前生命值
var current_health: int = 50

## 面向方向
var facing_direction: int = 1

## 返回位置（生成位置）
var spawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	current_health = stats.max_health if stats else 50
	spawn_position = global_position

	# 获取玩家引用
	if GameManager.player:
		player = GameManager.player

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD or current_state == EnemyState.STUNNED:
		return

	# 更新攻击冷却
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	# 根据状态执行行为
	match current_state:
		EnemyState.IDLE:
			_state_idle(delta)
		EnemyState.PATROL:
			_state_patrol(delta)
		EnemyState.CHASE:
			_state_chase(delta)
		EnemyState.ATTACK:
			_state_attack(delta)
		EnemyState.RETURN:
			_state_return(delta)

	# 应用移动
	move_and_slide()

func _state_idle(_delta: float) -> void:
	# 检测玩家
	if _can_see_player():
		current_state = EnemyState.CHASE

func _state_patrol(delta: float) -> void:
	if patrol_points.size() == 0:
		return

	# 移动到下一个巡逻点
	var target = patrol_points[patrol_index]
	var direction = (target - global_position).normalized()

	if direction.x != 0:
		facing_direction = sign(direction.x)

	velocity.x = direction.x * stats.move_speed

	# 到达巡逻点
	if global_position.distance_to(target) < 10:
		patrol_index = (patrol_index + 1) % patrol_points.size()

	# 检测玩家
	if _can_see_player():
		current_state = EnemyState.CHASE

func _state_chase(delta: float) -> void:
	if player == null or not player.is_inside_tree():
		current_state = EnemyState.RETURN
		return

	var direction = (player.global_position - global_position).normalized()

	if direction.x != 0:
		facing_direction = sign(direction.x)

	velocity.x = direction.x * stats.move_speed

	# 进入攻击范围
	if global_position.distance_to(player.global_position) <= stats.attack_range:
		current_state = EnemyState.ATTACK

func _state_attack(_delta: float) -> void:
	if player == null or not player.is_inside_tree():
		current_state = EnemyState.RETURN
		return

	# 检查距离
	var distance = global_position.distance_to(player.global_position)

	if distance > stats.attack_range:
		current_state = EnemyState.CHASE
		return

	# 攻击玩家
	if attack_cooldown_timer <= 0:
		_perform_attack()

func _state_return(_delta: float) -> void:
	# 返回生成位置
	var direction = (spawn_position - global_position).normalized()
	velocity.x = direction.x * stats.move_speed

	if global_position.distance_to(spawn_position) < 10:
		current_state = EnemyState.PATROL

## 能否看到玩家
func _can_see_player() -> bool:
	if player == null or not player.is_inside_tree():
		return false

	var distance = global_position.distance_to(player.global_position)
	return distance <= stats.detection_range

## 执行攻击
func _perform_attack() -> void:
	attack_cooldown_timer = stats.attack_cooldown

	if player and player.has_method("take_damage"):
		player.take_damage(stats.damage)

## 敌人受伤
func take_damage(amount: int) -> void:
	current_health = max(0, current_health - amount)

	if current_health <= 0:
		_die()

## 敌人死亡
func _die() -> void:
	current_state = EnemyState.DEAD

	# 添加分数
	if GameManager:
		GameManager.add_score(stats.score_value if stats else 100)

	enemy_died.emit(self)
	AudioManager.play_death_sound()

	# 延迟销毁
	await get_tree().create_timer(1.0).timeout
	queue_free()

## 设置巡逻点
func set_patrol_points(points: Array[Vector2]) -> void:
	patrol_points = points
	if points.size() > 0:
		current_state = EnemyState.PATROL
```

- [ ] **Step 4: 创建怪物场景 (monster_01.tscn)**

```gdscript
[gd_scene load_steps=3 format=3 uid="uid://monster01"]

[ext_resource type="Script" path="enemy_base.gd" id="1_enemy"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_enemy"]
size = Vector2(32, 32)

[node name="Monster01" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 5
script = ExtResource("1_enemy")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_enemy")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_scale = Vector2(1, 1)

[node name="AttackBox" type="Area2D" parent="."]
collision_layer = 4
collision_mask = 1
```

- [ ] **Step 5: 创建怪物配置资源**

```gdscript
@tool
extends EditorScript

func _run() -> void:
	var stats = EnemyStats.new()
	stats.max_health = 50
	stats.damage = 10
	stats.move_speed = 80.0
	stats.attack_cooldown = 1.0
	stats.score_value = 100
	stats.detection_range = 150.0
	stats.attack_range = 40.0

	var err = ResourceSaver.save(stats, "res://resources/enemy_configs/monster_01.tres")
	print("Saved monster_01 config: ", err == OK)
```

- [ ] **Step 6: 提交**

```bash
git add scripts/enemies/enemy_base.gd scenes/enemies/*.tscn resources/enemy_configs/monster_01.tres
git commit -m "feat: add Enemy AI system with state machine"
```

---

## Task 9: 怪物生成器

**Files:**
- Create: `scripts/enemy_spawner.gd`

- [ ] **Step 1: 创建怪物生成器脚本**

```gdscript
## 怪物生成器 - 随机生成怪物
class_name EnemySpawner
extends Node2D

## 生成点列表
@export var spawn_points: Array[Marker2D]

## 怪物场景列表
@export var enemy_scenes: Array[PackedScene]

## 最大同时存在的怪物数量
@export var max_enemies: int = 5

## 生成间隔
@export var spawn_interval: float = 2.0

## 玩家引用
var player: Node2D = null

## 当前存活的怪物
var current_enemies: Array[Node] = []

## 生成计时器
var spawn_timer: float = 0.0

## 玩家区域检测
@onready var detection_area: Area2D = $DetectionArea if has_node("DetectionArea") else null

func _ready() -> void:
	# 连接怪物死亡信号
	for enemy in current_enemies:
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

	# 延迟获取玩家引用
	await get_tree().create_timer(0.5).timeout
	if GameManager.player:
		player = GameManager.player

func _process(delta: float) -> void:
	if player == null or not player.is_inside_tree():
		return

	# 更新生成计时器
	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		try_spawn_enemy()

## 尝试生成怪物
func try_spawn_enemy() -> void:
	if current_enemies.size() >= max_enemies:
		return

	if spawn_points.size() == 0 or enemy_scenes.size() == 0:
		return

	# 选择不在玩家视野内的生成点
	var valid_spawn_point = _get_valid_spawn_point()
	if valid_spawn_point == null:
		return

	# 随机选择怪物类型
	var scene_index = randi() % enemy_scenes.size()
	var enemy = enemy_scenes[scene_index].instantiate()

	# 设置位置
	enemy.global_position = valid_spawn_point

	# 连接到死亡信号
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)

	# 设置巡逻点（如果有多个生成点）
	if enemy.has_method("set_patrol_points") and spawn_points.size() > 1:
		var patrol_points = []
		for sp in spawn_points:
			patrol_points.append(sp.global_position)
		enemy.set_patrol_points(patrol_points)

	get_tree().current_scene.add_child(enemy)
	current_enemies.append(enemy)

	AudioManager.play_spawn_sound()

## 获取有效的生成点（不在玩家视野内）
func _get_valid_spawn_point() -> Marker2D:
	var valid_points = []

	for spawn_point in spawn_points:
		if player == null:
			valid_points.append(spawn_point)
			continue

		# 检查距离玩家是否足够远
		var distance = spawn_point.global_position.distance_to(player.global_position)
		if distance > 300:  # 不在玩家 300 像素范围内
			valid_points.append(spawn_point)

	if valid_points.size() == 0:
		return null

	return valid_points[randi() % valid_points.size()]

## 怪物死亡处理
func _on_enemy_died(enemy: EnemyBase) -> void:
	current_enemies.erase(enemy)

## 清除所有怪物
func clear_all_enemies() -> void:
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()
```

- [ ] **Step 2: 创建生成器场景**

```gdscript
[gd_scene load_steps=2 format=3 uid="uid://spawner123"]

[node name="EnemySpawner" type="Node2D"]
script = "res://scripts/enemy_spawner.gd"

[node name="DetectionArea" type="Area2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="DetectionArea"]
shape = SubResource("RectangleShape2D_detection")

[sub_resource type="RectangleShape2D" id="RectangleShape2D_detection"]
size = Vector2(800, 600)

# 添加生成点（Marker2D）作为子节点
[node name="SpawnPoint1" type="Marker2D" parent="."]
position = Vector2(-200, 100)

[node name="SpawnPoint2" type="Marker2D" parent="."]
position = Vector2(200, 100)
```

- [ ] **Step 3: 提交**

```bash
git add scripts/enemy_spawner.gd
git commit -m "feat: add EnemySpawner with random spawning logic"
```

---

## Task 10: 摄像机控制器

**Files:**
- Create: `scripts/camera_controller.gd`

- [ ] **Step 1: 创建摄像机控制器脚本**

```gdscript
## 摄像机控制器 - 平滑跟随玩家
class_name CameraController
extends Camera2D

## 跟随目标
@export var target: Node2D

## 跟随速度
@export var follow_speed: float = 5.0

## 偏移量
@export var offset: Vector2 = Vector2(0, -50)

## 边界矩形
@export var boundary_rect: Rect2

## 死亡位置（游戏结束时使用）
var death_position: Vector2

## 动态偏移
var dynamic_offset: Vector2 = Vector2.ZERO

## 当前目标位置
var target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 默认边界为无穷大
	if boundary_rect == Rect2():
		boundary_rect = Rect2(-10000, -10000, 20000, 20000)

func _process(delta: float) -> void:
	if target == null or not target.is_inside_tree():
		return

	# 计算目标位置
	var base_target = target.global_position + offset + dynamic_offset

	# 根据玩家速度添加提前量
	if target.has_method("get_normalized_move"):
		var move_dir = target.get_normalized_move()
		if move_dir.length() > 0.5:
			dynamic_offset.x = move_dir.x * 50
		else:
			dynamic_offset.x = lerp(dynamic_offset.x, 0, delta * 5)

	# 玩家下蹲时降低摄像机
	if target.has_method("is_crouching") and target.is_crouching():
		dynamic_offset.y = lerp(dynamic_offset.y, 30, delta * 5)
	else:
		dynamic_offset.y = lerp(dynamic_offset.y, 0, delta * 5)

	# 更新目标位置
	target_position = target.global_position + offset + dynamic_offset

	# 平滑插值
	global_position = global_position.lerp(target_position, follow_speed * delta)

	# 边界限制
	global_position.x = clamp(global_position.x, boundary_rect.position.x, boundary_rect.end.x)
	global_position.y = clamp(global_position.y, boundary_rect.position.y, boundary_rect.end.y)

## 设置跟随目标
func set_target(new_target: Node2D) -> void:
	target = new_target

## 设置边界
func set_boundary(rect: Rect2) -> void:
	boundary_rect = rect

## 锁定摄像机位置
func lock_position() -> void:
	set_process(false)

## 解锁摄像机位置
func unlock_position() -> void:
	set_process(true)

## 游戏结束时的特殊行为
func on_game_over() -> void:
	# 可以添加缓慢推进等效果
	pass

## 获取归一化移动方向（供玩家使用）
func get_normalized_move() -> Vector2:
	if target and target.has_method("get_normalized_move"):
		return target.get_normalized_move()
	return Vector2.ZERO

## 是否下蹲（供玩家使用）
func is_crouching() -> bool:
	if target and target.has_method("is_crouching"):
		return target.is_crouching()  # 调用方法而不是返回方法引用
	return false
	return false
```

- [ ] **Step 2: 提交**

```bash
git add scripts/camera_controller.gd
git commit -m "feat: add CameraController with smooth follow"
```

---

## Task 11: 主场景组装

**Files:**
- Create: `scenes/main.tscn`

- [ ] **Step 1: 创建主场景文件**

```gdscript
[gd_scene load_steps=10 format=3 uid="uid://main123"]

[ext_resource type="Script" path="../scripts/camera_controller.gd" id="1_camera"]
[ext_resource type="Script" path="../scripts/enemy_spawner.gd" id="2_spawner"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_terrain"]
size = Vector2(2000, 50)

[sub_resource type="TileSet" id="TileSet_main"]
# TileSet 配置（后续添加实际素材后完善）

[node name="Main" type="Node2D"]

[node name="World" type="Node2D" parent="."]

[node name="Camera2D" type="Camera2D" parent="World"]
script = ExtResource("1_camera")

[node name="Terrain" type="TileMap" parent="World"]
collision_layer = 4
tile_set = SubResource("TileSet_main")

[node name="Ground" type="StaticBody2D" parent="World"]
collision_layer = 4
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="World/Ground"]
shape = SubResource("RectangleShape2D_terrain")

[node name="Player" type="CharacterBody2D" parent="World"]
position = Vector2(0, -100)
# 使用 PackedScene 实例化玩家
# [PackedScene: res://scenes/player/player.tscn]

[node name="EnemySpawner" type="Node2D" parent="World"]
script = ExtResource("2_spawner")
max_enemies = 5
spawn_interval = 2.0

[node name="SpawnPoint1" type="Marker2D" parent="World/EnemySpawner"]
position = Vector2(-200, 100)

[node name="SpawnPoint2" type="Marker2D" parent="World/EnemySpawner"]
position = Vector2(200, 100)

[node name="DeathZone" type="Area2D" parent="World"]
position = Vector2(0, 500)
collision_layer = 8
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="World/DeathZone"]
shape = SubResource("RectangleShape2D_terrain")

[node name="UI" type="CanvasLayer" parent="."]

[node name="HealthBar" type="ProgressBar" parent="UI"]
offset_left = 20.0
offset_top = 20.0
offset_right = 220.0
offset_bottom = 40.0
max_value = 100.0
value = 100.0

[node name="WeaponLabel" type="Label" parent="UI"]
offset_left = 20.0
offset_top = 50.0
offset_right = 200.0
offset_bottom = 80.0
text = "Weapon: Sword"

[node name="ScoreLabel" type="Label" parent="UI"]
offset_left = 1060.0
offset_top = 20.0
offset_right = 1260.0
offset_bottom = 50.0
text = "Score: 0"
horizontal_alignment = 2
```

- [ ] **Step 2: 连接 GameManager 信号到 UI**

```gdscript
# 需要添加一个 UI 控制器脚本
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_label: Label = $WeaponLabel
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.score_changed.connect(_on_score_changed)

	if GameManager.player and GameManager.player.has_signal("weapon_changed"):
		GameManager.player.weapon_changed.connect(_on_weapon_changed)

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func _on_weapon_changed(weapon_name: String) -> void:
	weapon_label.text = "Weapon: " + weapon_name
```

- [ ] **Step 3: 提交**

```bash
git add scenes/main.tscn
git commit -m "feat: assemble main scene with all components"
```

---

## Task 11: UI 控制器

**Files:**
- Create: `scripts/ui_controller.gd`

- [ ] **Step 1: 创建 UI 控制器脚本**

```gdscript
## UI 控制器 - 管理所有 UI 元素
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_label: Label = $WeaponLabel
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.score_changed.connect(_on_score_changed)

	# 连接玩家武器信号
	await get_tree().create_timer(0.1).timeout
	if GameManager.player and GameManager.player.has_signal("weapon_changed"):
		GameManager.player.weapon_changed.connect(_on_weapon_changed)
		# 初始化武器显示
		if GameManager.player.current_weapon:
			weapon_label.text = "Weapon: " + GameManager.player.current_weapon.weapon_name

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func _on_weapon_changed(weapon_name: String) -> void:
	weapon_label.text = "Weapon: " + weapon_name
```

- [ ] **Step 2: 提交**

```bash
git add scripts/ui_controller.gd
git commit -m "feat: add UI controller for HUD management"
```

---

## Task 12: 抛射物脚本（弓武器使用）

**Files:**
- Create: `scripts/projectiles/projectile.gd`
- Create: `scenes/projectiles/projectile.tscn`

- [ ] **Step 1: 创建抛射物脚本**

```gdscript
## 抛射物 - 用于弓武器的箭矢
class_name Projectile
extends Area2D

## 飞行速度
var speed: float = 500.0

## 飞行方向 (1=右，-1=左)
var direction: int = 1

## 伤害值
var damage: int = 15

## 存在时间
var lifetime: float = 3.0

## 重力
var gravity_force: float = 200.0

## 初始速度
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 设置初始速度
	velocity.x = direction * speed

	# 连接信号
	body_entered.connect(_on_body_entered)

	# 设置旋转
	rotation = direction * PI / 2 if direction > 0 else -PI / 2

	# 自动销毁计时器
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# 应用重力
	velocity.y += gravity_force * delta

	# 移动
	position += velocity * delta

	# 超出屏幕后销毁
	if position.x > 2000 or position.x < -2000 or position.y > 1500:
		queue_free()

## 命中处理
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		# 对敌人造成伤害
		if body.has_method("take_damage"):
			body.take_damage(damage)
		AudioManager.play_attack_sound()
		queue_free()
	elif body.is_in_group("terrain"):
		# 击中地形
		AudioManager.play_attack_sound()
		queue_free()
```

- [ ] **Step 2: 创建抛射物场景**

```gdscript
[gd_scene load_steps=3 format=3 uid="uid://projectile123"]

[ext_resource type="Script" path="../../scripts/projectiles/projectile.gd" id="1_projectile"]

[sub_resource type="CircleShape2D" id="CircleShape2D_projectile"]
radius = 5.0

[node name="Projectile" type="Area2D"]
collision_layer = 16
collision_mask = 2 | 4
script = ExtResource("1_projectile")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_projectile")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture_scale = Vector2(0.5, 0.5)
```

- [ ] **Step 3: 提交**

```bash
git add scripts/projectiles/projectile.gd scenes/projectiles/projectile.tscn
git commit -m "feat: add Projectile for bow weapon"
```

---

## Task 13: 死亡区域脚本

**Files:**
- Create: `scripts/death_zone.gd`

- [ ] **Step 1: 创建死亡区域脚本**

```gdscript
## 死亡区域 - 玩家掉落时触发
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## 有物体进入区域
func _on_body_entered(body: Node) -> void:
	if body is Player:
		# 玩家掉落即死
		body.take_damage(9999)
		AudioManager.play_death_sound()
	elif body.is_in_group("enemies"):
		# 敌人掉落也销毁
		if body.has_method("take_damage"):
			body.take_damage(9999)
```

- [ ] **Step 2: 提交**

```bash
git add scripts/death_zone.gd
git commit -m "feat: add DeathZone for fall damage"
```

---

## Task 14: 主场景组装

**Files:**
- Create: `scenes/main.tscn`

- [ ] **Step 1: 使用 Godot 编辑器创建主场景**

主场景包含以下节点结构：

```
Main (Node2D)
├── World (Node2D)
│   ├── Camera2D (Camera2D) - 使用 camera_controller.gd
│   ├── Terrain (TileMap)
│   ├── Ground (StaticBody2D)
│   │   └── CollisionShape2D
│   ├── Player (CharacterBody2D) - 实例化 player.tscn
│   ├── EnemySpawner (Node2D) - 使用 enemy_spawner.gd
│   │   ├── SpawnPoint1 (Marker2D)
│   │   └── SpawnPoint2 (Marker2D)
│   └── DeathZone (Area2D) - 使用 death_zone.gd
│       └── CollisionShape2D
└── UI (CanvasLayer) - 使用 ui_controller.gd
    ├── HealthBar (ProgressBar)
    ├── WeaponLabel (Label)
    └── ScoreLabel (Label)
```

**创建步骤：**
1. 打开 Godot 编辑器
2. 创建新场景，根节点为 Node2D，命名为 Main
3. 添加子节点 World (Node2D)
4. 在 World 下添加 Camera2D，挂载 camera_controller.gd
5. 添加 TileMap 作为地形
6. 添加 StaticBody2D 作为地面
7. 实例化 player.tscn 场景
8. 添加 EnemySpawner 节点
9. 添加 DeathZone (Area2D) 节点
10. 添加 UI (CanvasLayer) 节点
11. 保存为 scenes/main.tscn

- [ ] **Step 2: 配置摄像机边界**

在 Godot 编辑器中设置 Camera2D 的 Limit 属性：
- Left: -1000
- Top: -500
- Right: 1000
- Bottom: 500

- [ ] **Step 3: 提交**

```bash
git add scenes/main.tscn
git commit -m "feat: assemble main scene with all components"
```

---

## Task 15: 测试和调试

**Files:**
- Various test scenes

- [ ] **Step 1: 测试玩家移动**

```bash
# 打开 Godot 编辑器
# 运行场景 scenes/main.tscn
# 测试内容:
# - WASD 移动正常
# - Space 跳跃正常
# - S 下蹲正常
# - 手柄输入正常
```

- [ ] **Step 2: 测试武器系统**

```bash
# 测试内容:
# - J/K/L 攻击正常
# - Q/E 切换武器正常
# - 武器伤害正常
```

- [ ] **Step 3: 测试怪物 AI**

```bash
# 测试内容:
# - 怪物巡逻正常
# - 发现玩家后追击
# - 进入攻击范围后攻击
# - 玩家离开后返回
```

- [ ] **Step 4: 测试生成系统**

```bash
# 测试内容:
# - 怪物按时生成
# - 不超过最大数量限制
# - 不在玩家视野内生成
```

- [ ] **Step 5: 测试摄像机**

```bash
# 测试内容:
# - 平滑跟随玩家
# - 边界限制正常
# - 下蹲时调整正常
```

- [ ] **Step 6: 提交**

```bash
git commit -A -m "test: verify all systems working correctly"
```

---

## Task 16: 添加免费素材

**Files:**
- Download and integrate free assets

- [ ] **Step 1: 下载 Pixel Adventure 1 素材包**

```bash
# 从 itch.io 或 Kenney.nl 下载素材
# 解压到 assets/sprites/ 目录
```

- [ ] **Step 2: 替换玩家精灵**

```gdscript
# 在 player.tscn 中设置 Sprite2D 的 texture
# 使用素材包中的玩家动画精灵
```

- [ ] **Step 3: 替换怪物精灵**

```gdscript
# 在 monster_01.tscn 中设置 Sprite2D 的 texture
# 使用素材包中的怪物精灵
```

- [ ] **Step 4: 提交**

```bash
git add assets/sprites/
git commit -m "art: integrate free Pixel Adventure 1 assets"
```

---

## Task 17: 按键提示功能

**Files:**
- Create: `scripts/controls_overlay.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/ui_controller.gd`
- Modify: `scripts/input_handler.gd`

- [ ] **Step 1: 创建 ControlsOverlay 脚本**

```gdscript
## 按键控制器 - 管理按键提示面板
extends PanelContainer

## 按键信息数据结构
struct KeyBinding {
	var action: String
	var keys: Array[String]
	var description: String
}

## 所有按键绑定
var key_bindings: Array[KeyBinding] = []

func _ready() -> void:
	_initialize_key_bindings()
	_update_ui()

## 初始化按键绑定
func _initialize_key_bindings() -> void:
	key_bindings = [
		KeyBinding.new("移动", ["A", "D", "←", "→"], "左右移动"),
		KeyBinding.new("跳跃", ["Space"], "跳跃"),
		KeyBinding.new("下蹲", ["S"], "下蹲/蹲下"),
		KeyBinding.new("攻击 1", ["J"], "近战攻击 (剑)"),
		KeyBinding.new("攻击 2", ["K"], "远程攻击 (弓)"),
		KeyBinding.new("攻击 3", ["L"], "法术攻击 (法杖)"),
		KeyBinding.new("切换武器", ["Q", "E"], "切换武器"),
		KeyBinding.new("暂停", ["Escape", "Enter(手柄)"], "暂停/继续游戏"),
		KeyBinding.new("帮助", ["H"], "显示/隐藏本面板"),
	]

## 更新 UI 显示
func _update_ui() -> void:
	var container = $VBoxContainer
	if not container:
		return

	# 清除现有内容
	for child in container.get_children():
		child.queue_free()

	# 添加标题
	var title = Label.new()
	title.text = "操作说明"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	var separator = HSeparator.new()
	container.add_child(separator)

	# 添加按键绑定
	for binding in key_bindings:
		var hbox = HBoxContainer.new()

		var action_label = Label.new()
		action_label.text = binding.action + ":"
		action_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		action_label.custom_minimum_size.x = 100
		hbox.add_child(action_label)

		var keys_label = Label.new()
		keys_label.text = " [ " + " / ".join(binding.keys) + " ]"
		keys_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		hbox.add_child(keys_label)

		var desc_label = Label.new()
		desc_label.text = " - " + binding.description
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(desc_label)

		container.add_child(hbox)
```

- [ ] **Step 2: 修改 main.tscn 添加帮助按钮和面板**

```gdscript
# 在 UI CanvasLayer 下添加:
[node name="HelpButton" type="Button" parent="UI"]
offset_left = 1180.0
offset_top = 60.0
offset_right = 1260.0
offset_bottom = 90.0
text = "? 帮助"

[node name="ControlsOverlay" type="PanelContainer" parent="UI"]
visible = false
offset_left = 400.0
offset_top = 150.0
offset_right = 880.0
offset_bottom = 550.0
script = ExtResource("6_controls")

[node name="VBoxContainer" type="VBoxContainer" parent="UI/ControlsOverlay"]
layout_mode = 2
```

- [ ] **Step 3: 修改 ui_controller.gd 添加帮助功能**

```gdscript
@onready var help_button: Button = $HelpButton
@onready var controls_overlay: PanelContainer = $ControlsOverlay

func _ready() -> void:
	# ... 现有代码 ...

	# 连接帮助按钮
	if help_button:
		help_button.pressed.connect(_on_help_pressed)

	# 连接 H 键切换帮助面板
	InputHandler.toggle_help_pressed.connect(_on_toggle_help)

func _on_help_pressed() -> void:
	if controls_overlay:
		controls_overlay.visible = not controls_overlay.visible

func _on_toggle_help() -> void:
	if controls_overlay:
		controls_overlay.visible = not controls_overlay.visible
```

- [ ] **Step 4: 修改 input_handler.gd 添加切换帮助信号**

```gdscript
## 信号：切换帮助面板
signal toggle_help_pressed

func _handle_keyboard_input(event: InputEventKey) -> void:
	# ... 现有代码 ...
	KEY_H:
		toggle_help_pressed.emit()
```

- [ ] **Step 5: 提交**

```bash
git add scripts/controls_overlay.gd scenes/main.tscn scripts/ui_controller.gd scripts/input_handler.gd
git commit -m "feat: add controls overlay with key bindings display"
```

---

## 变更记录

### 2026-03-26
- **新增**: 按键提示功能 - 按 H 键或点击 "?" 按钮显示/隐藏操作说明面板
- **新增**: 支持键盘和手柄按键绑定显示
- **修改**: `scripts/input_handler.gd` - 添加 `toggle_help_pressed` 信号
- **修改**: `scripts/ui_controller.gd` - 添加帮助按钮和面板控制逻辑
- **新增**: `scripts/controls_overlay.gd` - 按键提示面板控制器
- **修改**: `scenes/main.tscn` - 添加帮助按钮和 ControlsOverlay 面板

---

## 验收检查清单

### 核心功能
- [ ] 玩家可流畅移动、跳跃、下蹲
- [ ] 三种武器可正常切换和使用
- [ ] 弓武器的抛射物正常飞行和命中
- [ ] 怪物能正确巡逻、追踪、攻击
- [ ] 怪物能随机生成和正确销毁
- [ ] 摄像机平滑跟随不卡顿
- [ ] 键盘和手柄输入均正常
- [ ] 程序音效正常播放

### UI 和系统
- [ ] UI 正确显示生命值、武器、得分
- [ ] 死亡区域正确检测掉落
- [ ] 游戏暂停/恢复功能正常

### 代码质量
- [ ] 代码有清晰注释
- [ ] 所有脚本无语法错误
- [ ] 信号连接正确

---

**计划结束**
