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
var gravity_force: float = 800.0

## 移动速度
var move_velocity: Vector2 = Vector2.ZERO

## 初始向上速度（制造抛物线）
var initial_upward_velocity: float = -200.0

func _ready() -> void:
	# 设置初始速度（有向上的初速度，形成抛物线）
	move_velocity.x = direction * speed
	move_velocity.y = initial_upward_velocity

	# 连接信号
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# 设置旋转，初始朝向飞行方向
	rotation = 0

	# 自动销毁计时器
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# 应用重力
	move_velocity.y += gravity_force * delta

	# 更新旋转，使其朝向速度方向
	if abs(move_velocity.x) > 1:
		rotation = atan2(move_velocity.y, move_velocity.x)

	# 移动
	position += move_velocity * delta

	# 超出屏幕后销毁
	if position.x > 2000 or position.x < -2000 or position.y > 1500:
		queue_free()

## 命中处理
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		# 对敌人造成伤害
		if body.has_method("take_damage"):
			body.take_damage(damage, direction)
		AudioManager.play_attack_sound()
		queue_free()
	elif body.is_in_group("terrain"):
		# 击中地形
		AudioManager.play_attack_sound()
		queue_free()

## 区域进入处理
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("terrain"):
		AudioManager.play_attack_sound()
		queue_free()

## 设置方向
func set_direction(dir: int) -> void:
	direction = dir
	move_velocity.x = direction * speed

## 设置伤害
func set_damage(dmg: int) -> void:
	damage = dmg

## 设置速度
func set_speed(spd: float) -> void:
	speed = spd
	move_velocity.x = direction * speed
