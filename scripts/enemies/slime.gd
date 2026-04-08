## 绿色史莱姆 - 跳跃追踪玩家（含平台导航寻路）
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

## 当前导航路径
var current_nav_path: PlatformPath = null

## 路径重算计时器
var path_recalc_timer: float = 0.0

## 路径重算间隔
var path_recalc_interval: float = 1.0

## 上次玩家所在平台（用于检测平台变化触发重算）
var last_player_platform: String = ""

## 上次自己所在平台
var last_my_platform: String = ""

## 路径模式下的跳跃请求
var _path_jump_requested: bool = false

## 路径模式下的水平速度覆盖
var _path_velocity_x: float = 0.0

## 是否处于路径导航模式
var _is_pathfinding: bool = false


func _ready() -> void:
	super._ready()
	path_follower = PathFollower.new()


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
		# 击退时中断路径
		_cancel_path()

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

	# 路径相关重置
	_path_jump_requested = false
	_path_velocity_x = 0.0

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

		# 路径模式下的跳跃由 PathFollower 触发
		if _path_jump_requested and current_state == EnemyState.CHASE:
			_do_path_jump()
			jump_timer = jump_interval
		elif not _is_pathfinding and jump_timer <= 0 and current_state != EnemyState.DEAD:
			_perform_jump()
			jump_timer = jump_interval
	else:
		# 空中状态
		if _is_pathfinding and path_follower and path_follower.state == PathFollower.FollowerState.EXECUTING_TRANSITION:
			# 路径执行中的空中控制
			var result = path_follower.update(delta, is_on_floor(), global_position)
			if abs(result["velocity_x"]) > 0:
				velocity.x = result["velocity_x"]
			if result["done"]:
				_is_pathfinding = false
		elif current_state == EnemyState.CHASE and player != null and player.is_inside_tree():
			# 原始行为：空中微调方向
			var dir = sign(player.global_position.x - global_position.x)
			if dir != 0:
				facing_direction = dir

	# 应用移动
	move_and_slide()

	# 检测是否站在敌人头顶，如果是则弹开
	_check_stuck_on_enemy()

	# 检测是否卡在玩家头顶，如果是则弹开
	_check_stuck_on_player()

	# 更新动画
	_update_animation()


## 重写 idle 状态
func _state_idle(_delta: float) -> void:
	_cancel_path()

	# 检测玩家
	if player == null:
		if GameManager.player:
			player = GameManager.player
	if _can_see_player():
		current_state = EnemyState.CHASE
		return


## 重写 chase 状态 - 集成路径寻路
func _state_chase(_delta: float) -> void:
	if player == null or not player.is_inside_tree():
		current_state = EnemyState.IDLE
		_cancel_path()
		return

	var distance = global_position.distance_to(player.global_position)

	# 超出追击距离
	if distance > max_chase_distance:
		current_state = EnemyState.IDLE
		spawn_position = global_position
		_cancel_path()
		return

	# 进入攻击范围
	if distance <= stats.attack_range:
		current_state = EnemyState.ATTACK
		_cancel_path()
		return

	# 尝试获取玩家和自己的平台
	var my_plat = PlatformGraph.get_platform_at(global_position)
	var player_plat = PlatformGraph.get_platform_at(player.global_position)

	print("[Slime] chase: my_plat=%s player_plat=%s pos=(%.0f,%.0f) player_pos=(%.0f,%.0f)" % [my_plat, player_plat, global_position.x, global_position.y, player.global_position.x, player.global_position.y])

	# 同平台或无法确定平台 → 直接水平追踪
	if my_plat == player_plat or my_plat == "" or player_plat == "":
		_is_pathfinding = false
		_direct_chase()
		return

	# 需要跨平台导航
	print("[Slime] needs pathfinding: %s → %s" % [my_plat, player_plat])
	path_recalc_timer += _delta

	# 检查是否需要重新计算路径
	var need_recalc = false
	if current_nav_path == null or path_follower.state == PathFollower.FollowerState.IDLE:
		need_recalc = true
	elif path_follower.state == PathFollower.FollowerState.PATH_FAILED:
		need_recalc = true
	elif path_follower.state == PathFollower.FollowerState.PATH_COMPLETE:
		need_recalc = true
	elif last_player_platform != player_plat:
		need_recalc = true
	elif last_my_platform != my_plat:
		# 自己所在平台变了 (可能掉下去了), 必须重算
		need_recalc = true
		_cancel_path()
	elif path_recalc_timer >= path_recalc_interval:
		need_recalc = true

	last_my_platform = my_plat

	if need_recalc:
		_compute_path(my_plat, player_plat)
		path_recalc_timer = 0.0
		last_player_platform = player_plat

	# 如果有活跃路径，执行路径
	if _is_pathfinding and path_follower and path_follower.state != PathFollower.FollowerState.IDLE:
		var result = path_follower.update(_delta, is_on_floor(), global_position)

		if abs(result["velocity_x"]) > 0:
			_path_velocity_x = result["velocity_x"]
			velocity.x = result["velocity_x"]
			facing_direction = sign(result["velocity_x"]) if sign(result["velocity_x"]) != 0 else facing_direction

		if result["should_jump"]:
			_path_jump_requested = true
			_path_velocity_x = result["velocity_x"]

		if result["done"]:
			_is_pathfinding = false
			# 路径完成后，如果还在 CHASE 状态，下一帧会重新评估
	else:
		# 没有活跃路径，回退到直接追踪
		_is_pathfinding = false
		_direct_chase()


## 直接水平追踪（同平台或无路径时的回退）
func _direct_chase() -> void:
	if player == null or not player.is_inside_tree():
		return
	var dir = sign(player.global_position.x - global_position.x)
	if dir != 0:
		facing_direction = dir
	velocity.x = dir * stats.move_speed


## 计算导航路径
func _compute_path(my_plat: String, player_plat: String) -> void:
	var path = PlatformGraph.find_path(my_plat, player_plat)
	print("[Slime] compute_path: %s → %s, result=%s" % [my_plat, player_plat, "null" if path == null else str(path.steps.size()) + " steps"])
	if path != null and not path.is_empty():
		current_nav_path = path
		path_follower.start_path(path, jump_horizontal_speed)
		_is_pathfinding = true
	else:
		_cancel_path()
		# 回退到直接追踪
		_direct_chase()


## 取消当前路径
func _cancel_path() -> void:
	_is_pathfinding = false
	current_nav_path = null
	if path_follower:
		path_follower.stop()


## 执行路径模式下的跳跃
func _do_path_jump() -> void:
	print("[Slime] PATH JUMP: vx=%.1f vy=%.1f pos=(%.0f,%.0f)" % [_path_velocity_x, -jump_force, global_position.x, global_position.y])
	is_jumping = true
	velocity.y = -jump_force
	velocity.x = _path_velocity_x
	if abs(_path_velocity_x) > 0:
		facing_direction = sign(_path_velocity_x)


## 执行跳跃（非路径模式）
func _perform_jump() -> void:
	is_jumping = true
	velocity.y = -jump_force

	if current_state == EnemyState.CHASE and player != null and player.is_inside_tree():
		var dir = sign(player.global_position.x - global_position.x)
		if dir != 0:
			facing_direction = dir
		velocity.x = facing_direction * jump_horizontal_speed
	else:
		var random_dir = 1 if randi() % 2 == 0 else -1
		facing_direction = random_dir
		velocity.x = random_dir * jump_horizontal_speed * 0.5


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
	enemy_sprite.flip_h = facing_direction == 1

	if current_state == EnemyState.DEAD:
		if enemy_sprite.animation != &"Death":
			enemy_sprite.play("Death")
	elif is_jumping:
		if enemy_sprite.animation != &"Jump":
			enemy_sprite.play("Jump")
	else:
		if enemy_sprite.animation != &"Idle":
			enemy_sprite.play("Idle")


## 检测是否站在敌人头顶，如果是则弹开
func _check_stuck_on_enemy() -> void:
	if not is_on_floor():
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is CharacterBody2D and collider != player and collision.get_normal().y < -0.5:
			var push_dir = sign(global_position.x - collider.global_position.x)
			if push_dir == 0:
				push_dir = 1
			facing_direction = push_dir
			velocity.y = -jump_force * 0.4
			velocity.x = push_dir * jump_horizontal_speed * 0.5
			is_jumping = true
			jump_timer = jump_interval
			return


## 检测是否卡在玩家头顶，如果是则弹开
func _check_stuck_on_player() -> void:
	if player == null or not player.is_inside_tree():
		return
	if not is_on_floor():
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player and collision.get_normal().y < -0.5:
			var push_dir = sign(global_position.x - player.global_position.x)
			if push_dir == 0:
				push_dir = 1
			facing_direction = push_dir
			velocity.y = -jump_force * 0.6
			velocity.x = push_dir * jump_horizontal_speed
			is_jumping = true
			jump_timer = jump_interval
			return
