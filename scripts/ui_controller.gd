## UI 控制器 - 管理所有 UI 元素
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_label: Label = $WeaponLabel
@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	# 连接 GameManager 信号
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.score_changed.connect(_on_score_changed)

	# 连接玩家武器信号
	await get_tree().create_timer(0.1).timeout
	if GameManager.player and GameManager.player.has_signal("weapon_changed"):
		GameManager.player.weapon_changed.connect(_on_weapon_changed)
		# 初始化武器显示
		if GameManager.player.current_weapon:
			weapon_label.text = "Weapon: " + GameManager.player.current_weapon.weapon_name

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func _on_weapon_changed(weapon_name: String) -> void:
	weapon_label.text = "Weapon: " + weapon_name
