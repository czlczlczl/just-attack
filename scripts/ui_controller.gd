## UI 控制器 - 管理所有 UI 元素
extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_label: Label = $WeaponLabel
@onready var score_label: Label = $ScoreLabel
@onready var help_button: Button = $HelpButton
@onready var controls_overlay: PanelContainer = $ControlsOverlay
@onready var key_display: Label = $KeyDisplay

## 按键显示计时器
var key_display_timer: float = 0.0

## 当前显示的按键
var current_key: String = ""

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

	# 连接帮助按钮
	if help_button:
		help_button.pressed.connect(_on_help_pressed)

	# 连接 H 键切换帮助面板
	InputHandler.toggle_help_pressed.connect(_on_toggle_help)

	# 连接按键显示
	InputHandler.key_pressed.connect(_on_key_pressed)

	# 初始化按键显示
	if key_display:
		key_display.visible = false
		key_display.position = Vector2(20, 680)  # 左下角
		key_display.size = Vector2(300, 40)

func _process(delta: float) -> void:
	# 处理按键显示计时器
	if key_display_timer > 0:
		key_display_timer -= delta
		if key_display_timer <= 0:
			key_display.visible = false
			current_key = ""

func _on_key_pressed(key_name: String) -> void:
	if key_display:
		current_key = key_name
		key_display.text = "按键：" + key_name
		key_display.visible = true
		key_display_timer = 0.5  # 显示 0.5 秒

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: " + str(new_score)

func _on_weapon_changed(weapon_name: String) -> void:
	weapon_label.text = "Weapon: " + weapon_name

func _on_help_pressed() -> void:
	if controls_overlay:
		controls_overlay.visible = not controls_overlay.visible

func _on_toggle_help() -> void:
	if controls_overlay:
		controls_overlay.visible = not controls_overlay.visible
