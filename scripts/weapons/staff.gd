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
	if animation_player:
		_create_swing_animation()

func _create_swing_animation() -> void:
	if not animation_player:
		return

	# 先添加空动画
	animation_player.add_animation("swing")
	var anim = animation_player.get_animation("swing")

	# 如果动画不存在，创建一个新的
	if not anim:
		anim = Animation.new()
		animation_player.add_animation("swing")
		anim = animation_player.get_animation("swing")

	anim.length = 0.25

	# 获取 StaffVisual 节点路径
	var visual_path = "StaffVisual"

	# 添加旋转轨道
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, visual_path + ":rotation")

	# 添加关键帧
	anim.track_insert_key(track_index, 0.0, -0.6)   # 后拉
	anim.track_insert_key(track_index, 0.125, 0.9)  # 挥动
	anim.track_insert_key(track_index, 0.25, 0.0)   # 归位

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
