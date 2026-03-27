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

	# 获取默认动画库
	var anim_library = animation_player.get_animation_library("")

	# 如果动画已存在，先删除
	if anim_library and anim_library.has_animation("swing"):
		anim_library.remove_animation("swing")

	# 如果没有动画库，创建一个临时的
	if not anim_library:
		anim_library = AnimationLibrary.new()
		animation_player.add_animation_library("", anim_library)

	# 创建动画
	var anim = Animation.new()
	anim.length = 0.15

	# 获取 SwordVisual 节点路径
	var visual_path = "SwordVisual"

	# 添加旋转轨道 - 在 Godot 4.x 中使用 transform/rotation
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, visual_path + ":transform")

	# 添加关键帧：起始 - 挥动 - 回正（使用 Transform2D 旋转）
	var start_transform = Transform2D(0, Vector2.ZERO)
	var swing1_transform = Transform2D(-0.5236, Vector2.ZERO)  # -30 度
	var swing2_transform = Transform2D(0.7854, Vector2.ZERO)   # 45 度
	var swing3_transform = Transform2D(-0.2618, Vector2.ZERO)  # -15 度
	var end_transform = Transform2D(0, Vector2.ZERO)           # 0 度（归位）

	anim.track_insert_key(track_index, 0.0, start_transform)
	anim.track_insert_key(track_index, 0.05, swing2_transform)
	anim.track_insert_key(track_index, 0.1, swing3_transform)
	anim.track_insert_key(track_index, 0.15, end_transform)

	# 添加动画到库
	anim_library.add_animation("swing", anim)

func _on_animation_finished() -> void:
	is_attacking = false

func attack(direction: int) -> void:
	print("[Sword] attack() called, is_attacking=", is_attacking)
	if is_attacking:
		print("[Sword] Already attacking, skipping")
		return

	is_attacking = true
	print("[Sword] Calling super.attack()")
	super.attack(direction)

	# 播放挥舞动画
	if animation_player and animation_player.get_animation_list().size() > 0:
		print("[Sword] Playing swing animation")
		animation_player.play("swing")
	else:
		print("[Sword] No animation available")
		# 没有动画时，攻击完成后立即重置
		is_attacking = false
