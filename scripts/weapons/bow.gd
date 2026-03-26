## 弓 - 远程武器，抛物线弹道
class_name Bow
extends WeaponBase

## 抛射物场景
@export var projectile_scene: PackedScene

## 抛射物速度
@export var projectile_speed: float = 500.0

func _init():
	weapon_name = "Bow"
	damage = 15
	attack_range = 300.0
	attack_cooldown = 0.8

func attack(direction: int) -> void:
	if is_cooldown:
		return

	current_cooldown = attack_cooldown
	is_cooldown = true

	# 发射抛射物
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position + Vector2(50 * direction, 0)
		projectile.direction = direction
		projectile.damage = damage
		projectile.speed = projectile_speed
