## 法杖 - 远程武器，穿透效果
class_name Staff
extends WeaponBase

## 动画引用
var animation_player: AnimationPlayer = null

func _init():
	weapon_name = "Staff"
	damage = 12
	attack_range = 250.0
	attack_cooldown = 0.4

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

	# 创建命中框
	var hitbox = _create_hitbox()
	get_tree().current_scene.add_child(hitbox)

	# 等待一帧让物理引擎检测碰撞
	await get_tree().process_frame
	var targets = _check_hits(hitbox)
	attack_hit.emit(targets)

	# 清理命中框
	hitbox.queue_free()

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
