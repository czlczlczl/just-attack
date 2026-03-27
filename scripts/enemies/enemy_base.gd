## 敌人基类 - 所有敌人的共同行为和 AI
class_name EnemyBase
extends CharacterBody2D

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

## 敌人属性
@export var stats: EnemyStats
@export var patrol_points: Array[Vector2]

## 信号：敌人死亡
signal enemy_died(enemy: EnemyBase)
signal enemy_hit(enemy: EnemyBase, damage: int)

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

## 最大生命值
var max_health: int = 50

## 面向方向
var facing_direction: int = 1

## 返回位置（生成位置）
var spawn_position: Vector2 = Vector2.ZERO

## 无敌时间
var invincibility_timer: float = 0.0

## 受击击退速度
var knockback_velocity: Vector2 = Vector2.ZERO

## 血条引用
var health_bar: ProgressBar = null

## 血条隐藏计时器
var health_bar_hide_timer: float = 0.0

## 敌人分离半径
var separation_radius: float = 40.0

## 敌人分离力
var separation_force: Vector2 = Vector2.ZERO

## 视觉节点引用
var enemy_visual: ColorRect = null

## 原始颜色（用于闪白后恢复）
var original_color: Color = Color.WHITE

## 闪白计时器
var flash_timer: float = 0.0

## 闪白是否在进行
var is_flashing: bool = false

func _ready() -> void:
	add_to_group("enemies")
	max_health = stats.max_health if stats else 50
	current_health = max_health
	spawn_position = global_position

	# 获取玩家引用
	if GameManager.player:
		player = GameManager.player

	# 获取视觉节点引用
	enemy_visual = get_node_or_null("EnemyVisual") as ColorRect
	if enemy_visual:
		original_color = enemy_visual.color

	# 获取血条引用
	health_bar = get_node_or_null("HealthBar")
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
		health_bar.visible = false

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD or current_state == EnemyState.STUNNED:
		return

	# 应用重力
	if not is_on_floor():
		velocity.y += 980.0 * delta

	# 应用击退速度
	if knockback_velocity.length() > 0:
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 2000 * delta)

	# 计算敌人之间的分离力（避免重叠）
	_apply_separation(delta)

	# 更新无敌时间
	if invincibility_timer > 0:
		invincibility_timer -= delta
		# print("[Enemy] Invincibility timer: ", invincibility_timer)

	# 更新闪白效果
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			_stop_flash()

	# 更新血条隐藏计时器
	if health_bar and health_bar.visible:
		health_bar_hide_timer -= delta
		if health_bar_hide_timer <= 0:
			hide_health_bar()

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

## 应用敌人之间的分离力
func _apply_separation(delta: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var separation = Vector2.ZERO
	var count = 0

	for other in enemies:
		if other == self or not other.is_inside_tree():
			continue
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_radius and dist > 0:
			separation += (global_position - other.global_position).normalized() / dist
			count += 1

	if count > 0:
		separation /= count
		velocity += separation * 500 * delta

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
func take_damage(amount: int, hit_direction: int = 0) -> void:
	if invincibility_timer > 0:
		return

	invincibility_timer = 0.5  # 0.5 秒无敌时间

	current_health = max(0, current_health - amount)

	# 显示血条
	if health_bar:
		health_bar.value = current_health
		health_bar.visible = true
		health_bar_hide_timer = 2.0  # 2 秒后隐藏

	# 发射受伤信号
	enemy_hit.emit(self, amount)

	# 击退效果
	if hit_direction != 0:
		knockback_velocity = Vector2(-hit_direction * 300, -150)

	# 播放受击闪白效果
	_flash_on_hit()

	AudioManager.play_hurt_sound()

	if current_health <= 0:
		_die()

## 显示血条
func show_health_bar() -> void:
	if health_bar:
		health_bar.visible = true

## 隐藏血条
func hide_health_bar() -> void:
	if health_bar:
		health_bar.visible = false

## 敌人死亡
func _die() -> void:
	current_state = EnemyState.DEAD

	# 隐藏血条
	hide_health_bar()

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

func _exit_tree() -> void:
	# 清理资源
	patrol_points.clear()

## 播放受击闪白效果
func _flash_on_hit() -> void:
	if enemy_visual:
		is_flashing = true
		flash_timer = 0.15  # 闪白持续 0.15 秒
		enemy_visual.color = Color.WHITE

## 停止闪白，恢复原始颜色
func _stop_flash() -> void:
	is_flashing = false
	if enemy_visual:
		enemy_visual.color = original_color
