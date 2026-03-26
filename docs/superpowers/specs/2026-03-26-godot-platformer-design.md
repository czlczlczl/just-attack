# Godot 4.6.1 横板动作冒险游戏设计文档

**创建日期：** 2026-03-26
**版本：** 1.0
**状态：** 已批准

---

## 1. 项目概述

### 1.1 项目目标
创建一个基于 Godot 4.6.1 的 2D 横板动作冒险游戏框架，具备可扩展的架构，支持玩家控制、武器切换、怪物 AI 和随机生成系统。

### 1.2 核心特性
- **玩家控制：** 走、跳、下蹲、攻击
- **武器系统：** 可切换多种武器（剑、弓、法杖）
- **怪物 AI：** 巡逻、追踪、攻击行为
- **随机生成：** 地牢式怪物生成
- **输入支持：** 键盘 + 手柄双支持
- **摄像机：** 平滑跟随系统
- **音效：** 程序生成音效

---

## 2. 架构设计

### 2.1 模块化场景架构

采用 Godot 原生场景组合模式，各系统独立成场景，通过主场景组装。

```
主场景 (main.tscn)
├── GameManager (AutoLoad)
├── InputHandler (AutoLoad)
├── AudioManager (AutoLoad)
├── World
│   ├── Camera2D
│   ├── TileMap (关卡)
│   ├── Player
│   ├── EnemySpawner
│   └── DeathZone
└── UI
    ├── HealthBar
    ├── WeaponIndicator
    └── PauseMenu
```

### 2.2 项目文件结构

```
godot_platformer/
├── project.godot                 # 项目配置
├── scenes/
│   ├── main.tscn                 # 主场景
│   ├── player/
│   │   ├── player.tscn           # 玩家场景
│   │   ├── player.gd             # 玩家脚本
│   │   └── player_states.gd      # 玩家状态机
│   ├── enemies/
│   │   ├── enemy_base.tscn       # 敌人基类
│   │   ├── enemy_base.gd         # 敌人基类脚本
│   │   ├── enemy_states.gd       # 敌人状态机
│   │   └── monster_01.tscn       # 怪物类型 1
│   ├── weapons/
│   │   ├── weapon_base.gd        # 武器基类
│   │   ├── sword.gd              # 剑
│   │   ├── bow.gd                # 弓
│   │   └── staff.gd              # 法杖
│   └── levels/
│       ├── room_template.tscn    # 房间模板
│       └── dungeon_generator.gd  # 地牢生成器
├── scripts/
│   ├── game_manager.gd           # 游戏管理器 (AutoLoad)
│   ├── input_handler.gd          # 输入处理器 (AutoLoad)
│   ├── enemy_spawner.gd          # 怪物生成器
│   ├── audio_manager.gd          # 音效管理器 (AutoLoad)
│   └── camera_controller.gd      # 摄像机控制器
├── resources/
│   ├── player_stats.tres         # 玩家属性
│   └── enemy_configs/            # 敌人配置
│       ├── monster_01.tres
│       └── monster_02.tres
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   └── tiles/
│   └── audio/
└── docs/
    └── superpowers/specs/
```

---

## 3. 玩家控制系统

### 3.1 输入映射

| 动作 | 键盘 | 手柄 |
|------|------|------|
| 左移 | A | 左摇杆左/十字键左 |
| 右移 | D | 左摇杆右/十字键右 |
| 跳跃 | Space | A 按钮 |
| 下蹲 | S | 十字键下 |
| 攻击 1 | J | X 按钮 |
| 攻击 2 | K | Y 按钮 |
| 攻击 3 | L | B 按钮 |
| 切换武器 (左) | Q | LB 肩键 |
| 切换武器 (右) | E | RB 肩键 |
| 暂停 | Escape | Start 按钮 |

### 3.2 玩家状态机

```
                    ┌─────────┐
                    │  Spawn  │
                    └────┬────┘
                         ↓
                    ┌─────────┐
         ┌─────────►│   Idle  │◄─────────┐
         │          └────┬────┘          │
         │               │               │
    ┌────┴────┐     ┌────┴────┐     ┌────┴────┐
    │   Run   │     │  Jump   │     │  Land   │
    └────┬────┘     └────┬────┘     └─────────┘
         │               │
         │          ┌────┴────┐
         │          │  Fall   │
         │          └─────────┘
         │
    ┌────┴────┐     ┌─────────┐
    │ Crouch  │◄────│ Crouch  │
    └─────────┘     │  Idle   │
                    └─────────┘

攻击状态可在任何地面状态下触发（跳跃攻击、下蹲攻击等）
```

### 3.3 玩家属性配置

```gdscript
# resources/player_stats.tres
class_name PlayerStats
extends Resource

@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var crouch_speed: float = 100.0
@export var max_health: int = 100
@export var invincibility_frames: float = 1.0
```

---

## 4. 武器系统

### 4.1 武器基类接口

```gdscript
# scripts/weapons/weapon_base.gd
class_name WeaponBase
extends Node2D

@export var weapon_name: String
@export var damage: int = 10
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 0.5
@export var attack_animation: String

var is_cooldown: bool = false
var current_cooldown: float = 0.0

func attack(direction: Vector2) -> void:
    pass

func get_hitbox() -> Area2D:
    pass

func play_sound() -> void:
    pass

func _process(delta: float) -> void:
    if is_cooldown:
        current_cooldown -= delta
        if current_cooldown <= 0:
            is_cooldown = false
```

### 4.2 武器类型

| 武器 | 伤害 | 范围 | 冷却 | 特性 |
|------|------|------|------|------|
| 剑 | 25 | 40 | 0.3s | 快速连击，可格挡 |
| 弓 | 15 | 300 | 0.8s | 远程，抛物线弹道 |
| 法杖 | 12 | 250 | 0.4s | 穿透效果，范围伤害 |

### 4.3 武器切换逻辑

```gdscript
# 武器管理器
var weapons: Array[WeaponBase] = []
var current_weapon_index: int = 0

func switch_weapon(direction: int) -> void:
    current_weapon_index = wrapi(current_weapon_index + direction, 0, weapons.size())
    equip_weapon(weapons[current_weapon_index])

func equip_weapon(weapon: WeaponBase) -> void:
    # 动态加载武器场景
    # 播放切换动画
    # 更新 UI 指示器
```

---

## 5. 怪物 AI 系统

### 5.1 敌人基类

```gdscript
# scripts/enemies/enemy_base.gd
class_name EnemyBase
extends CharacterBody2D

@export var stats: EnemyStats
@export var detection_range: float = 150.0
@export var attack_range: float = 40.0
@export var patrol_points: Array[Vector2]

var current_state: EnemyState
var player: Node2D
var patrol_index: int = 0
```

### 5.2 怪物 AI 状态机

```
                    ┌─────────┐
                    │  Spawn  │
                    └────┬────┘
                         ↓
                    ┌─────────┐
                    │   Idle  │
                    └────┬────┘
                         ↓
                    ┌─────────┐
        ┌──────────►│ Patrol  │◄──────────┐
        │           └────┬────┘           │
        │                │                │
        │         [发现玩家]              │
        │                │                │
        │           ┌────┴────┐          │
        │           │  Chase  │          │
        │           └────┬────┘          │
        │                │               │
        │         [在攻击范围内]         │
        │                │               │
        │           ┌────┴────┐          │
        │           │  Attack │          │
        │           └────┬────┘          │
        │                │               │
        │         [玩家脱离]             │
        │                │               │
        │           ┌────┴────┐          │
        └───────────│ Return  │──────────┘
                    └─────────┘
```

### 5.3 怪物配置资源

```gdscript
# resources/enemy_configs/monster_01.tres
class_name EnemyStats
extends Resource

@export var max_health: int = 50
@export var damage: int = 10
@export var move_speed: float = 80.0
@export var attack_cooldown: float = 1.0
@export var score_value: int = 100
```

---

## 6. 随机生成系统

### 6.1 生成器工作流程

```
1. 玩家进入新区域
        ↓
2. 触发 Area2D 检测
        ↓
3. 读取当前区域配置
        ↓
4. 随机选择怪物类型
        ↓
5. 在生成点实例化
        ↓
6. 加入 AI 管理
```

### 6.2 生成规则

```gdscript
# scripts/enemy_spawner.gd
class_name EnemySpawner
extends Node2D

@export var spawn_points: Array[Marker2D]
@export var enemy_scenes: Array[PackedScene]
@export var max_enemies: int = 5
@export var spawn_interval: float = 2.0

var current_enemies: Array[Node] = []

func try_spawn_enemy() -> void:
    if current_enemies.size() >= max_enemies:
        return

    # 选择随机生成点（不在玩家视野内）
    # 选择随机怪物类型
    # 实例化并加入管理
```

### 6.3 难度调整

- 根据玩家当前生命值调整怪物数量
- 根据游戏时间调整怪物强度
- 保证最低生成间隔，避免过度生成

---

## 7. 摄像机系统

### 7.1 平滑跟随算法

```gdscript
# scripts/camera_controller.gd
class_name CameraController
extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 5.0
@export var offset: Vector2 = Vector2.ZERO
@export var boundary_rect: Rect2

var death_position: Vector2

func _process(delta: float) -> void:
    if target == null:
        return

    var target_position = target.global_position + offset

    # 动态调整偏移量
    if target is Player:
        # 根据玩家速度添加提前量
        # 根据玩家状态调整（下蹲时降低）
        pass

    # 平滑插值
    global_position = global_position.lerp(target_position, follow_speed * delta)

    # 边界限制
    global_position = global_position.clamp(boundary_rect.position, boundary_rect.end)
```

### 7.2 动态调整规则

| 玩家状态 | 摄像机行为 |
|----------|------------|
| 正常移动 | 标准跟随 |
| 快速移动 | 增加提前量 |
| 下蹲 | 降低偏移 Y 值 |
| 死亡 | 锁定位置，缓慢推进 |
| 过场动画 | 临时锁定目标 |

---

## 8. 音效系统

### 8.1 程序生成音效

使用 `AudioStreamGenerator` 生成简单音效：

```gdscript
# scripts/audio_manager.gd
class_name AudioManager
extends Node

var jump_sound: AudioStreamGenerator
var attack_sound: AudioStreamGenerator
var hurt_sound: AudioStreamGenerator
var spawn_sound: AudioStreamGenerator

func _ready() -> void:
    # 初始化音效生成器
    jump_sound = create_frequency_sweep(400, 800, 0.1)
    attack_sound = create_noise_burst(0.15)
    hurt_sound = create_square_wave(150, 0.2)
    spawn_sound = create_pitch_slide(200, 600, 0.3)

func create_frequency_sweep(from_hz: float, to_hz: float, duration: float) -> AudioStreamGenerator:
    # 生成频率扫描波形（用于跳跃音效）
    pass

func create_noise_burst(duration: float) -> AudioStreamGenerator:
    # 生成噪音爆发（用于攻击音效）
    pass

func create_square_wave(frequency: float, duration: float) -> AudioStreamGenerator:
    # 生成方波（用于受伤音效）
    pass
```

### 8.2 音效映射

| 事件 | 音效类型 | 参数 |
|------|----------|------|
| 跳跃 | 频率扫描 | 400Hz → 800Hz, 0.1s |
| 攻击 | 噪音爆发 | 0.15s 衰减 |
| 受伤 | 方波 | 150Hz, 0.2s |
| 怪物生成 | 滑音 | 200Hz → 600Hz, 0.3s |
| 死亡 | 频率下降 | 400Hz → 100Hz, 0.5s |

---

## 9. AutoLoad 单例

### 9.1 GameManager

```gdscript
# scripts/game_manager.gd
extends Node

var player: Node2D
var current_level: int = 0
var game_state: GameState = GameState.PLAYING
var score: int = 0

enum GameState { PLAYING, PAUSED, GAME_OVER, VICTORY }

func change_state(new_state: GameState) -> void:
    game_state = new_state
    match new_state:
        GameState.PAUSED:
            get_tree().paused = true
        GameState.GAME_OVER:
            # 显示游戏结束 UI
            pass
```

### 9.2 InputHandler

```gdscript
# scripts/input_handler.gd
extends Node

signal move_input_changed(direction: Vector2)
signal jump_pressed
signal crouch_input_changed(is_crouching: bool)
signal attack_pressed(weapon_index: int)
signal weapon_switch_pressed(direction: int)

var move_direction: Vector2 = Vector2.ZERO
var is_crouching: bool = false

func _input(event: InputEvent) -> void:
    # 处理键盘和手柄输入
    # 发出相应信号
    pass
```

### 9.3 AudioManager

全局音效管理器，提供统一的音效播放接口。

---

## 10. 免费素材资源推荐

### 10.1 精灵图素材

- **Kenney.nl** - 提供大量免费 2D 游戏素材
- **OpenGameArt.org** - 开源游戏素材社区
- **itch.io 免费包** - 搜索"free 2d assets"

### 10.2 推荐素材包

1. **Pixel Adventure 1** - 完整的平台游戏素材包
2. **Kenney Platformer** - 简洁的几何风格
3. **LPC Legacy** - 经典 RPG 风格

---

## 11. 测试计划

### 11.1 单元测试

- 玩家移动和跳跃物理
- 武器冷却和伤害计算
- 怪物 AI 状态转换

### 11.2 集成测试

- 玩家与怪物战斗流程
- 怪物生成和销毁周期
- 摄像机跟随边界处理

### 11.3 手动测试清单

- [ ] 键盘输入响应
- [ ] 手柄输入响应
- [ ] 武器切换流畅性
- [ ] 怪物 AI 行为正确性
- [ ] 摄像机不穿墙
- [ ] 音效播放正常

---

## 12. 扩展点

### 12.1 易于添加的内容

- **新武器** - 继承 `WeaponBase` 类
- **新怪物** - 继承 `EnemyBase` 类，创建新配置
- **新关卡** - 使用房间模板拼接
- **新玩家技能** - 在玩家状态机中添加状态

### 12.2 配置驱动

所有数值（速度、伤害、生成规则）均通过资源文件配置，无需修改代码即可调整游戏平衡。

---

## 13. 验收标准

- [ ] 玩家可流畅移动、跳跃、下蹲
- [ ] 三种武器可正常切换和使用
- [ ] 怪物能正确巡逻、追踪、攻击
- [ ] 怪物能随机生成和正确销毁
- [ ] 摄像机平滑跟随不卡顿
- [ ] 键盘和手柄输入均正常
- [ ] 程序音效正常播放
- [ ] 代码有清晰注释和文档

---

**文档结束**
