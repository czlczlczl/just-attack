## 死亡区域 - 玩家掉落时触发
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

## 有物体进入区域
func _on_body_entered(body: Node) -> void:
	if body is Player:
		# 玩家掉落即死
		body.take_damage(9999)
		AudioManager.play_death_sound()
	elif body.is_in_group("enemies"):
		# 敌人掉落也销毁
		if body.has_method("take_damage"):
			body.take_damage(9999)
