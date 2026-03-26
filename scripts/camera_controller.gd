## 摄像机控制器 - 平滑跟随玩家
class_name CameraController
extends Camera2D

## 跟随目标
@export var target: Node2D

## 跟随速度
@export var follow_speed: float = 5.0

## 偏移量
@export var camera_offset: Vector2 = Vector2(0, -50)

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
	var base_target = target.global_position + camera_offset + dynamic_offset

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
	target_position = target.global_position + camera_offset + dynamic_offset

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
