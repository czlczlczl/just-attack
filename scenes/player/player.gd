## 玩家控制器 - 处理玩家移动、跳跃、攻击等所有行为
class_name Player
extends CharacterBody2D

## 玩家属性
@export var stats: PlayerStats

## 信号：玩家受伤
signal player_hurt(damage: int)

## 信号：玩家死亡
signal player_died

## 信号：武器切换
signal weapon_changed(weapon_name: String)

## 当前武器
var current_weapon: Node2D = null

## 武器列表
var weapons: Array[Node2D] = []

## 当前武器索引
var weapon_index: int = 0

## 是否在地面
var is_on_ground: bool = false

## 是否下蹲
var is_crouching: bool = false

## 无敌计时器
var invincibility_timer: float = 0.0

## 移动方向
var move_direction: float = 0.0

## 面向方向 (1=右，-1=左)
var facing_direction: int = 1

func _exit_tree() -> void:
	# 清理武器
	for weapon in weapons:
		if is_instance_valid(weapon):
			weapon.queue_free()
	weapons.clear()
	current_weapon = null

func _ready() -> void:
	# 注册到 GameManager
	GameManager.register_player(self)

	# 连接输入信号
	InputHandler.move_input_changed.connect(_on_move_input)
	InputHandler.crouch_input_changed.connect(_on_crouch_input)
	InputHandler.jump_pressed.connect(_on_jump_pressed)
	InputHandler.attack_pressed.connect(_on_attack_pressed)
	InputHandler.weapon_switch_pressed.connect(_on_weapon_switch)
	InputHandler.pause_pressed.connect(_on_pause_pressed)

	# 初始化无敌计时器
	invincibility_timer = 0.0

	# 初始化武器
	_initialize_weapons()

func _physics_process(delta: float) -> void:
	# 应用重力
	if not is_on_ground:
		velocity.y += stats.gravity * delta

	# 水平移动
	velocity.x = move_direction * stats.move_speed

	# 处理下蹲
	if is_crouching and is_on_ground:
		velocity.x = move_direction * stats.crouch_speed

	# 更新面向方向
	if move_direction != 0:
		facing_direction = sign(move_direction)

	# 更新无敌计时器
	if invincibility_timer > 0:
		invincibility_timer -= delta

	# 移动并获取碰撞信息
	is_on_ground = is_on_floor()
	move_and_slide()

func _process(_delta: float) -> void:
	# 更新动画状态（后续添加 AnimationPlayer 后使用）
	_update_animation_state()

## 处理移动输入
func _on_move_input(direction: Vector2) -> void:
	move_direction = direction.x

## 处理下蹲输入
func _on_crouch_input(crouching: bool) -> void:
	is_crouching = crouching

## 处理跳跃
func _on_jump_pressed() -> void:
	if is_on_ground and not is_crouching:
		velocity.y = stats.jump_velocity
		AudioManager.play_jump_sound()

## 处理攻击
func _on_attack_pressed(attack_index: int) -> void:
	if current_weapon and current_weapon.has_method("attack"):
		current_weapon.attack(facing_direction)
		AudioManager.play_attack_sound()

## 处理武器切换
func _on_weapon_switch(direction: int) -> void:
	if weapons.size() == 0:
		return

	weapon_index = wrapi(weapon_index + direction, 0, weapons.size())
	_equip_weapon(weapons[weapon_index])

## 处理暂停
func _on_pause_pressed() -> void:
	if GameManager.game_state == GameManager.GameState.PLAYING:
		GameManager.change_state(GameManager.GameState.PAUSED)
	elif GameManager.game_state == GameManager.GameState.PAUSED:
		GameManager.change_state(GameManager.GameState.PLAYING)

## 装备武器
func _equip_weapon(weapon: Node2D) -> void:
	# 卸载当前武器
	if current_weapon and current_weapon.get_parent():
		current_weapon.get_parent().remove_child(current_weapon)

	# 装备新武器
	current_weapon = weapon
	add_child(current_weapon)

	# 设置武器位置（根据面向方向调整）
	current_weapon.position = Vector2(32 * facing_direction, 0)

	weapon_changed.emit(weapon.weapon_name if weapon.has_method("get_weapon_name") else "Unknown")

## 玩家受伤
func take_damage(amount: int) -> void:
	if invincibility_timer > 0:
		return

	invincibility_timer = stats.invincibility_frames
	GameManager.take_damage(amount)
	player_hurt.emit(amount)
	AudioManager.play_hurt_sound()

	# 击退效果
	velocity.y = -200
	velocity.x = -facing_direction * 300

## 添加武器到武器列表
func add_weapon(weapon: Node2D) -> void:
	weapons.append(weapon)
	if current_weapon == null:
		_equip_weapon(weapon)

## 更新动画状态
func _update_animation_state() -> void:
	# 后续添加 AnimationPlayer 后实现
	pass

## 获取归一化移动方向
func get_normalized_move() -> Vector2:
	return Vector2(move_direction, 0).normalized()

## 初始化武器
func _initialize_weapons() -> void:
	# 创建三种武器
	var sword = preload("res://scenes/weapons/sword.tscn").instantiate()
	var bow = preload("res://scenes/weapons/bow.tscn").instantiate()
	var staff = preload("res://scenes/weapons/staff.tscn").instantiate()

	add_weapon(sword)
	add_weapon(bow)
	add_weapon(staff)
