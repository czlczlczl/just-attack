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

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if is_cooldown:
		current_cooldown -= delta
		if current_cooldown <= 0:
			is_cooldown = false

## 执行攻击
func attack(direction: int) -> void:
	if is_cooldown:
		print("[Weapon] Attack skipped, cooldown remaining: ", current_cooldown)
		return

	attack_direction = direction
	current_cooldown = attack_cooldown
	is_cooldown = true
	print("[Weapon] Attack started, direction=", direction, " setting cooldown to ", attack_cooldown)

	# 创建命中框
	var hitbox = _create_hitbox()
	get_tree().current_scene.add_child(hitbox)

	# 等待两帧以确保物理服务器注册新的 Area2D 和 CollisionShape2D
	await get_tree().physics_frame
	await get_tree().physics_frame

	# 手动检查重叠以调试
	print("[Weapon] Checking for overlaps...")
	_manual_check_overlaps(hitbox)

	# 检测命中
	var targets = _check_hits(hitbox)
	print("[Weapon] Hit found: ", targets.size(), " targets")
	attack_hit.emit(targets)

	# 清理命中框
	hitbox.queue_free()

## 创建命中框
func _create_hitbox() -> Area2D:
	var hitbox = Area2D.new()
	hitbox.name = "WeaponHitbox"
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "HitboxShape"
	var shape = RectangleShape2D.new()

	# 设置形状大小
	shape.size = Vector2(attack_range * 2, 60)
	collision_shape.shape = shape

	# 设置碰撞层和掩码
	hitbox.collision_layer = 4
	hitbox.collision_mask = 2

	# 获取玩家位置 - 使用 get_parent() 获取玩家位置
	var player_pos: Vector2
	if get_parent():
		player_pos = get_parent().global_position
		print("[Weapon] Parent found, position: ", player_pos)
	else:
		player_pos = global_position
		print("[Weapon] No parent found, using weapon position")

	# 计算偏移：水平方向根据攻击方向，垂直方向调整以匹配敌人位置
	var offset = Vector2(attack_range * attack_direction, 8)  # 8 调整垂直偏移，使 hitbox 更高
	hitbox.global_position = player_pos + offset

	var y_min = hitbox.global_position.y - shape.size.y / 2
	var y_max = hitbox.global_position.y + shape.size.y / 2
	print("[Weapon] Hitbox created at ", hitbox.global_position, " with size ", shape.size, " Y range (", y_min, ", ", y_max, ") and collision_mask ", hitbox.collision_mask)

	# 添加碰撞形状
	hitbox.add_child(collision_shape)

	# 列出所有敌人及其位置
	print("[Weapon] Enemies in scene:")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		print("[Weapon]   - ", enemy.name, " at ", enemy.global_position, " collision_layer: ", enemy.collision_layer if enemy.has_method("get_collision_layer") else "N/A")

	return hitbox

## 手动检查重叠用于调试
func _manual_check_overlaps(hitbox: Area2D) -> void:
	var hitbox_x_min = hitbox.global_position.x - 40.0  # attack_range
	var hitbox_x_max = hitbox.global_position.x + 40.0
	var hitbox_y_min = hitbox.global_position.y - 30.0  # 60/2
	var hitbox_y_max = hitbox.global_position.y + 30.0

	print("[Weapon] Hitbox AABB: x(", hitbox_x_min, ", ", hitbox_x_max, ") y(", hitbox_y_min, ", ", hitbox_y_max, ")")

	for enemy in get_tree().get_nodes_in_group("enemies"):
		print("[Weapon] Enemy ", enemy.name, " at ", enemy.global_position, " is in hitbox: ",
			enemy.global_position.x >= hitbox_x_min and enemy.global_position.x <= hitbox_x_max and
			enemy.global_position.y >= hitbox_y_min and enemy.global_position.y <= hitbox_y_max)

## 检测命中
func _check_hits(hitbox: Area2D) -> Array:
	var targets = []
	var bodies = hitbox.get_overlapping_bodies()

	print("[Weapon] _check_hits: found ", bodies.size(), " bodies")
	for body in bodies:
		print("[Weapon] Found body: ", body.name, " groups: ", body.get_groups())

	for body in bodies:
		print("[Weapon] Checking if ", body.name, " is in enemies group...")
		if body.is_in_group("enemies"):
			print("[Weapon] Enemy found in group!")
			targets.append(body)
			if body.has_method("take_damage"):
				print("[Weapon] Applying damage to ", body.name)
				body.take_damage(damage, attack_direction)
		else:
			print("[Weapon] Body not in enemies group")

	return targets

## 获取武器名称
func get_weapon_name() -> String:
	return weapon_name

## 获取伤害值
func get_damage() -> int:
	return damage
