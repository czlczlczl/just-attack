# 绿色史莱姆怪物设计

## 概述

新增一种绿色史莱姆怪物，使用青蛙（frog）精灵图素材，以规律跳跃的方式追踪玩家，碰撞造成伤害。当前版本只开放生成史莱姆。

## 行为设计

### 跳跃追踪
- **待机状态**：站在原地播放 idle 动画，每隔 1.5 秒原地跳跃一次
- **追踪状态**：检测到玩家后朝玩家方向跳跃，每次跳跃形成固定抛物线轨迹
- **规律节奏**：跳跃间隔、高度、距离固定，像青蛙一样一跳一跳追玩家
- **碰撞伤害**：通过 AttackBox（Area2D）碰撞玩家造成伤害

### 状态流转
```
IDLE（原地跳跃）→ 检测到玩家 → CHASE（朝玩家跳跃）→ 碰撞攻击 → 继续 CHASE
                                                  → 超出追击距离 → IDLE
```

## 技术方案

继承 `EnemyBase` 基类，重写移动逻辑为跳跃行为，复用现有的生命值、受伤闪烁、碰撞伤害、生成器等基础设施。

### 新增文件

| 文件 | 说明 |
|------|------|
| `scripts/enemies/slime.gd` | 继承 EnemyBase，重写 _physics_process 和状态方法为跳跃逻辑 |
| `resources/enemy_configs/slime.tres` | 史莱姆属性配置 |
| `scenes/enemies/slime.tscn` | 史莱姆场景，使用 frog 精灵图 |

### 修改文件

- EnemySpawner：只生成史莱姆

## 属性配置

| 属性 | 值 | 说明 |
|------|------|------|
| max_health | 30 | 低血量，容易被击败 |
| damage | 8 | 低伤害 |
| move_speed | 60 | 慢速（跳跃水平速度基准） |
| attack_cooldown | 1.0 | 攻击冷却 |
| score_value | 80 | 击杀得分 |
| detection_range | 200.0 | 检测范围 |
| attack_range | 35.0 | 攻击范围 |

## 跳跃机制

### 参数
- `jump_force`: 400（跳跃力度，向上初速度）
- `jump_horizontal_speed`: 150（跳跃水平速度）
- `jump_interval`: 1.5 秒（跳跃间隔）

### 逻辑
1. 在地面上时，跳跃计时器倒计时
2. 计时器归零时：
   - IDLE 状态：原地方向跳跃
   - CHASE 状态：朝玩家方向跳跃
3. 施加速度：`velocity.y = -jump_force`，`velocity.x = direction * jump_horizontal_speed`
4. 空中受重力影响，形成抛物线
5. 着地后重置计时器，进入下一次跳跃循环

## 精灵图

使用现有素材 `assets/sprites/enemies/frog/`：
- `frog-idle-1.png` ~ `frog-idle-4.png`：待机动画
- `frog-jump-1.png` ~ `frog-jump-2.png`：跳跃动画

### 动画映射
- Idle → frog-idle-1~4（速度 5fps）
- Jump → frog-jump-1~2（速度 4fps）
- Hurt → frog-idle-1（单帧）
- Death → frog-idle-1（单帧）

## 碰撞配置

- 碰撞形状：RectangleShape2D，32x28（比 monster_01 小）
- 碰撞层：layer 2（敌人层），mask 5（地面+玩家）
- AttackBox：layer 4（敌人攻击层），mask 1（玩家层）
