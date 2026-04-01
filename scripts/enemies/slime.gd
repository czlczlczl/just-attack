## 绿色史莱姆 - 跳跃追踪玩家
class_name Slime
extends EnemyBase

## 跳跃力度（向上初速度）
@export var jump_force: float = 400.0

## 跳跃水平速度
@export var jump_horizontal_speed: float = 150.0

## 跳跃间隔（秒）
@export var jump_interval: float = 1.5

## 跳跃计时器（初始设为 jump_interval，避免出生就跳）
var jump_timer: float = 1.5

## 是否在跳跃中（空中）
var is_jumping: bool = false

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD or current_state == EnemyState.STUNNED:
		return

	# 应用重力
	if not is_on_floor():
		velocity.y += 980.0 * delta
	else:
		if is_jumping:
			is_jumping = false
			velocity.x = 0

	# 应用击退速度
	if knockback_velocity.length() > 0:
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 2000 * delta)

	# 计算敌人之间的分离力
	_apply_separation(delta)

	# 更新无敌时间
	if invincibility_timer > 0:
		invincibility_timer -= delta

	# 更新闪白效果
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0:
			_stop_flash()

	# 更新血条隐藏计时器
	if health_bar and health_bar.visible:
		health_bar_hide_timer -= delta
		if health_bar_hide_timer <= 0:
			hide_health_bar()

	# 更新攻击冷却
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	# 只在地面时执行状态逻辑和跳跃
	if is_on_floor():
		jump_timer -= delta

		# 根据状态执行行为
		match current_state:
			EnemyState.IDLE:
				_state_idle(delta)
			EnemyState.PATROL:
				_state_patrol(delta)
			EnemyState.CHASE:
				_state_chase(delta)
			EnemyState.ATTACK:
				_state_attack(delta)
			EnemyState.RETURN:
				_state_return(delta)

		# 计时器归零时跳跃
		if jump_timer <= 0 and current_state != EnemyState.DEAD:
			_perform_jump()
			jump_timer = jump_interval
	else:
		# 空中追踪：微调水平方向朝向玩家
		if current_state == EnemyState.CHASE and player != null and player.is_inside_tree():
			var dir = sign(player.global_position.x - global_position.x)
			if dir != 0:
				facing_direction = dir

	# 应用移动
	move_and_slide()

	# 检测是否卡在玩家头顶，如果是则弹开
	_check_stuck_on_player()

	# 更新动画
	_update_animation()

## 执行跳跃
func _perform_jump() -> void:
	is_jumping = true
	velocity.y = -jump_force

	if current_state == EnemyState.CHASE and player != null and player.is_inside_tree():
		# 追踪时朝玩家方向跳跃
		var dir = sign(player.global_position.x - global_position.x)
		if dir != 0:
			facing_direction = dir
		velocity.x = facing_direction * jump_horizontal_speed
	else:
		# 待机时原地小跳
		velocity.x = 0

## 重写 idle 状态
func _state_idle(_delta: float) -> void:
	# 检测玩家 - 如果没有玩家引用，尝试重新获取
	if player == null:
		if GameManager.player:
			player = GameManager.player
	# 检测玩家
	if _can_see_player():
		current_state = EnemyState.CHASE
		return

## 重写 chase 状态（跳跃逻辑在 _perform_jump 中处理）
func _state_chase(_delta: float) -> void:
	if player == null or not player.is_inside_tree():
		current_state = EnemyState.IDLE
		return

	# 始终面向玩家
	var dir = sign(player.global_position.x - global_position.x)
	if dir != 0:
		facing_direction = dir

	var distance = global_position.distance_to(player.global_position)

	# 超出追击距离
	if distance > max_chase_distance:
		current_state = EnemyState.IDLE
		spawn_position = global_position
		return

	# 进入攻击范围
	if distance <= stats.attack_range:
		current_state = EnemyState.ATTACK

## 重写 attack 状态
func _state_attack(_delta: float) -> void:
	if player == null or not player.is_inside_tree():
		current_state = EnemyState.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > stats.attack_range:
		current_state = EnemyState.CHASE
		return

	# 攻击玩家
	if attack_cooldown_timer <= 0:
		_perform_attack()

	# 朝向玩家
	var dir = sign(player.global_position.x - global_position.x)
	if dir != 0:
		facing_direction = dir

## 重写 return 状态（史莱姆不巡逻，直接进入 idle）
func _state_return(_delta: float) -> void:
	current_state = EnemyState.IDLE

## 重写 patrol 状态（史莱姆不巡逻，直接进入 idle）
func _state_patrol(_delta: float) -> void:
	current_state = EnemyState.IDLE

## 重写动画更新
func _update_animation() -> void:
	if not enemy_sprite:
		return
	enemy_sprite.flip_h = facing_direction == -1

	if current_state == EnemyState.DEAD:
		if enemy_sprite.animation != &"Death":
			enemy_sprite.play("Death")
	elif is_jumping:
		if enemy_sprite.animation != &"Jump":
			enemy_sprite.play("Jump")
	else:
		if enemy_sprite.animation != &"Idle":
			enemy_sprite.play("Idle")

## 检测是否卡在玩家头顶，如果是则弹开
func _check_stuck_on_player() -> void:
	if player == null or not player.is_inside_tree():
		return
	if not is_on_floor():
		return

	# 检查碰撞列表中是否有玩家，且法线朝上（说明在玩家头顶）
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player and collision.get_normal().y < -0.5:
			# 弹开：朝远离玩家方向小跳
			var push_dir = sign(global_position.x - player.global_position.x)
			if push_dir == 0:
				push_dir = 1
			facing_direction = push_dir
			velocity.y = -jump_force * 0.6
			velocity.x = push_dir * jump_horizontal_speed
			is_jumping = true
			jump_timer = jump_interval
			return
