## 法杖 - 远程武器，穿透效果
class_name Staff
extends WeaponBase

func _init():
	weapon_name = "Staff"
	damage = 12
	attack_range = 250.0
	attack_cooldown = 0.4

func _check_hits(hitbox: Area2D) -> Array:
	var targets = []
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			targets.append(body)
			# 法杖可以穿透，继续检测更多目标
			if body.has_method("take_damage"):
				body.take_damage(damage, attack_direction)
	return targets
