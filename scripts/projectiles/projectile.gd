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
var gravity_force: float = 200.0

## 移动速度
var move_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# 设置初始速度
	move_velocity.x = direction * speed

	# 连接信号
	body_entered.connect(_on_body_entered)

	# 设置旋转
	rotation = direction * PI / 2 if direction > 0 else -PI / 2

	# 自动销毁计时器
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	# 应用重力
	move_velocity.y += gravity_force * delta

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
			body.take_damage(damage)
		AudioManager.play_attack_sound()
		queue_free()
	elif body.is_in_group("terrain"):
		# 击中地形
		AudioManager.play_attack_sound()
		queue_free()
