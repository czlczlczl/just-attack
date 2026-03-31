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

func _exit_tree() -> void:
	# 清理所有敌人
	clear_all_enemies()

func _ready() -> void:
	# 如果没有手动配置生成点，自动获取子节点
	if spawn_points.size() == 0:
		for child in get_children():
			if child is Marker2D:
				spawn_points.append(child)

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
	enemy.global_position = valid_spawn_point.global_position

	# 连接到死亡信号
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)

	# 设置巡逻点（如果有多个生成点）
	if enemy.has_method("set_patrol_points") and spawn_points.size() > 1:
		var patrol_points: Array[Vector2] = []
		for sp in spawn_points:
			patrol_points.append(sp.global_position)
		enemy.set_patrol_points(patrol_points)

	get_parent().add_child(enemy)
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
