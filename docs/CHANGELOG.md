# Godot Platformer 变更日志

## 2026-03-26 - 游戏性功能修复

### 新增功能

#### 1. 怪物血条系统
- 在 `monster_01.tscn` 中添加 ProgressBar 作为血条
- 在 `enemy_base.gd` 中添加血条控制逻辑
- 受伤时显示血条，2 秒后自动隐藏
- 死亡时立即隐藏血条

#### 2. Sword 挥动动画
- 在 `sword.tscn` 中添加 AnimationPlayer 节点
- 在 `sword.gd` 中添加动画播放逻辑
- 攻击时播放挥舞动画，阻止连续攻击

#### 3. Bow 箭矢抛物线弹道
- 在 `projectile.gd` 中增加初始向上速度 `initial_upward_velocity = -200`
- 增加重力 `gravity_force = 800`
- 添加旋转朝向速度方向的功能（使用 `atan2`）

#### 4. 怪物受击反应
- 在 `enemy_base.gd` 中添加 `knockback_velocity` 变量
- `take_damage` 函数接收击退方向参数
- 受击时施加向后的击退速度并带有向上分量
- 添加 0.5 秒无敌时间防止连续命中

### Bug 修复

#### 1. 怪物落在天上问题
- **文件**: `scripts/enemies/enemy_base.gd`
- **修复**: 在 `_physics_process` 中添加重力应用逻辑

#### 2. 人物移动 stuck 问题
- **文件**: `scripts/input_handler.gd`
- **修复**: 修改 `_input` 函数处理按键释放事件

#### 3. 武器方向不同步问题
- **文件**: `scenes/player/player.gd`
- **修复**: 添加 `_update_weapon_position` 函数同步武器位置

#### 4. 空格键触发帮助框问题
- **文件**: `scripts/input_handler.gd`
- **修复**: 所有按键处理添加 `if event.pressed` 检查

#### 5. 帮助框位置问题
- **文件**: `scenes/main.tscn`
- **修复**: 将 ControlsOverlay 位置从中间移到右侧

#### 6. 抛射物属性设置错误
- **文件**: `scripts/weapons/bow.gd`, `scripts/projectiles/projectile.gd`
- **修复**: 使用 setter 方法设置抛射物属性

#### 7. 武器攻击不生效问题
- **文件**: `scripts/weapons/weapon_base.gd`, `project.godot`
- **修复**:
  - 使用 `global_position` 设置 hitbox 位置
  - 添加碰撞层交互配置 `[physics_layer_2d]`

#### 8. 怪物重叠问题
- **文件**: `scripts/enemies/enemy_base.gd`
- **修复**: 添加 `_apply_separation` 函数实现敌人分离逻辑

### 文件修改清单

| 文件 | 修改类型 |
|------|----------|
| `scripts/enemies/enemy_base.gd` | 新增血条、受击反应、分离逻辑 |
| `scenes/enemies/monster_01.tscn` | 新增 HealthBar 节点 |
| `scripts/weapons/sword.gd` | 新增动画播放逻辑 |
| `scenes/weapons/sword.tscn` | 新增 AnimationPlayer 节点 |
| `scripts/weapons/bow.gd` | 修改抛射物属性设置 |
| `scripts/projectiles/projectile.gd` | 新增抛物线弹道、setter 方法 |
| `scenes/weapons/bow.tscn` | 修复文件内容 |
| `scenes/weapons/staff.tscn` | 修复文件内容 |
| `scripts/weapons/weapon_base.gd` | 修复 hitbox 位置、碰撞检测 |
| `scripts/input_handler.gd` | 修复按键释放处理 |
| `scenes/player/player.gd` | 新增武器位置同步 |
| `scenes/main.tscn` | 移动帮助框位置 |
| `project.godot` | 新增碰撞层配置 |
