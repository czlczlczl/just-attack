## 玩家属性配置资源
## 可在编辑器中创建和修改
class_name PlayerStats
extends Resource

@export_group("移动属性")
@export var move_speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 980.0
@export var crouch_speed: float = 100.0

@export_group("战斗属性")
@export var max_health: int = 100
@export var invincibility_frames: float = 1.0
@export var knockback_resistance: float = 0.5

@export_group("动画")
@export var idle_animation: String = "idle"
@export var run_animation: String = "run"
@export var jump_animation: String = "jump"
@export var crouch_animation: String = "crouch"
