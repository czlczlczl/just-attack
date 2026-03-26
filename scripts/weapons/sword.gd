## 剑 - 近战武器，快速连击
class_name Sword
extends WeaponBase

## 动画引用（可选）
var animation_player: AnimationPlayer = null

## 攻击动画是否正在播放
var is_attacking: bool = false

func _init():
	weapon_name = "Sword"
	damage = 25
	attack_range = 40.0
	attack_cooldown = 0.3

func _ready() -> void:
	# 获取动画播放器
	animation_player = get_node_or_null("AnimationPlayer")
	if animation_player and animation_player.get_animation_list().size() > 0:
		animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	is_attacking = false

func attack(direction: int) -> void:
	if is_attacking:
		return

	is_attacking = true
	super.attack(direction)

	# 播放挥舞动画（如果有）
	if animation_player and animation_player.get_animation_list().size() > 0:
		animation_player.play("swing")
	else:
		# 没有动画时，攻击完成后立即重置
		is_attacking = false
