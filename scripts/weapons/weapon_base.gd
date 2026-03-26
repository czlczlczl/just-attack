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
			# 对敌人造成伤害
			if body.has_method("take_damage"):
				body.take_damage(damage)
	return targets

## 获取武器名称
func get_weapon_name() -> String:
	return weapon_name

## 获取伤害值
func get_damage() -> int:
	return damage
