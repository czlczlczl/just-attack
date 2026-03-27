## 弓 - 远程武器，抛物线弹道
class_name Bow
extends WeaponBase

## 抛射物场景
@export var projectile_scene: PackedScene

## 抛射物速度
@export var projectile_speed: float = 500.0

## 动画引用
var animation_player: AnimationPlayer = null

func _init():
	weapon_name = "Bow"
	damage = 15
	attack_range = 300.0
	attack_cooldown = 0.8

func _ready() -> void:
	animation_player = get_node_or_null("AnimationPlayer")

func attack(direction: int) -> void:
	if is_cooldown:
		return

	current_cooldown = attack_cooldown
	is_cooldown = true

	# 播放挥动动画
	if animation_player:
		animation_player.play("swing")

	# 发射抛射物
	if projectile_scene:
		var projectile = projectile_scene.instantiate() as Node2D
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector2(50 * direction, 0)
		# 设置抛射物属性
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		if projectile.has_method("set_damage"):
			projectile.set_damage(damage)
		if projectile.has_method("set_speed"):
			projectile.set_speed(projectile_speed)
	else:
		# 如果没有设置抛射物场景，直接调用父类方法
		super.attack(direction)
