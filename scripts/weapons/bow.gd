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
	if animation_player:
		_create_swing_animation()

func _create_swing_animation() -> void:
	if not animation_player:
		return

	# 创建动画
	var anim = Animation.new()
	anim.length = 0.2

	# 获取 BowVisual 节点
	var visual_path = get_path_to("BowVisual")
	if visual_path.is_empty():
		visual_path = "../BowVisual"

	# 添加旋转轨道
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_index, visual_path + ":rotation")

	# 添加关键帧
	anim.track_insert_key(track_index, 0.0, -0.3)   # 后拉
	anim.track_insert_key(track_index, 0.1, 0.4)    # 挥动
	anim.track_insert_key(track_index, 0.2, 0.0)    # 归位

	animation_player.add_animation("swing", anim)

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
