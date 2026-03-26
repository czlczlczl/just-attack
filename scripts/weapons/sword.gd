## 剑 - 近战武器，快速连击
class_name Sword
extends WeaponBase

func _init():
	weapon_name = "Sword"
	damage = 25
	attack_range = 40.0
	attack_cooldown = 0.3

func attack(direction: int) -> void:
	super.attack(direction)
	# 剑有特殊攻击效果（可扩展）
