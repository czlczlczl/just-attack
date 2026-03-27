## 剑 - 近战武器，快速连击
class_name Sword
extends WeaponBase

## 动画引用
var animation_player: AnimationPlayer = null

## 攻击动画是否正在播放
var is_attacking: bool = false

func _init():
	weapon_name = "Sword"
	damage = 25
	attack_range = 40.0
	attack_cooldown = 0.3

func _ready() -> void:
	# 获取或创建动画播放器
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player:
		_create_swing_animation()
		if animation_player.get_animation_list().size() > 0:
			animation_player.animation_finished.connect(_on_animation_finished)

func _create_swing_animation() -> void:
	if not animation_player:
		return

	# 创建动画
	var anim = Animation.new()
	anim.length = 0.15

	# 获取 SwordVisual 节点
	var visual_path = get_path_to("SwordVisual")
	if visual_path.is_empty():
		visual_path = "../SwordVisual"

	# 添加旋转轨道
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, visual_path + ":rotation")

	# 添加关键帧：起始 - 挥动 - 回正
	anim.track_insert_key(track_index, 0.0, -0.5236)  # -30 度
	anim.track_insert_key(track_index, 0.05, 0.7854)  # 45 度
	anim.track_insert_key(track_index, 0.1, -0.2618)  # -15 度
	anim.track_insert_key(track_index, 0.15, 0.0)     # 0 度（归位）

	# 添加动画到 AnimationPlayer
	animation_player.add_animation("swing", anim)

func _on_animation_finished() -> void:
	is_attacking = false

func attack(direction: int) -> void:
	if is_attacking:
		return

	is_attacking = true
	super.attack(direction)

	# 播放挥舞动画
	if animation_player and animation_player.get_animation_list().size() > 0:
		animation_player.play("swing")
	else:
		# 没有动画时，攻击完成后立即重置
		is_attacking = false
