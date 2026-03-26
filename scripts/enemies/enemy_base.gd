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
