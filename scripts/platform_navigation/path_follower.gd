## 路径执行器 - 实时执行导航路径
class_name PathFollower
extends RefCounted

enum FollowerState {
	IDLE,
	WALKING_TO_DEPARTURE,
	EXECUTING_TRANSITION,
	LANDING,
	PATH_COMPLETE,
	PATH_FAILED,
}

var state: FollowerState = FollowerState.IDLE
var current_path: PlatformPath = null
var _move_speed: float = 150.0
var _stabilize_timer: float = 0.0
var _timeout_timer: float = 0.0
var _max_step_time: float = 5.0
var _landing_duration: float = 0.15
var _arrival_threshold: float = 5.0
## 到达平台后还需要水平漂移到目标的额外距离容差
var _landing_threshold: float = 30.0


func start_path(path: PlatformPath, move_speed: float) -> void:
	current_path = path
	current_path.reset()
	_move_speed = move_speed
	_timeout_timer = 0.0
	state = FollowerState.WALKING_TO_DEPARTURE


func stop() -> void:
	state = FollowerState.IDLE
	current_path = null


## 每物理帧调用。返回 { velocity_x: float, should_jump: bool, done: bool }
func update(delta: float, is_on_floor: bool, global_pos: Vector2) -> Dictionary:
	var result = {"velocity_x": 0.0, "should_jump": false, "done": false}

	if state == FollowerState.IDLE or state == FollowerState.PATH_COMPLETE:
		result["done"] = state == FollowerState.PATH_COMPLETE
		return result

	if state == FollowerState.PATH_FAILED:
		result["done"] = true
		return result

	if current_path == null or current_path.is_complete():
		state = FollowerState.PATH_COMPLETE
		result["done"] = true
		return result

	_timeout_timer += delta
	if _timeout_timer > _max_step_time:
		state = FollowerState.PATH_FAILED
		result["done"] = true
		return result

	var step = current_path.current_step()
	if step == null:
		state = FollowerState.PATH_COMPLETE
		result["done"] = true
		return result

	var edge = step.edge

	match state:
		FollowerState.WALKING_TO_DEPARTURE:
			_update_walking_to_departure(edge, is_on_floor, global_pos, result)
		FollowerState.EXECUTING_TRANSITION:
			_update_executing_transition(edge, is_on_floor, global_pos, result)
		FollowerState.LANDING:
			_update_landing(delta, edge, global_pos, result)

	return result


func _update_walking_to_departure(edge: NavEdge, is_on_floor: bool, global_pos: Vector2, result: Dictionary) -> void:
	if not is_on_floor:
		# 等待着地再继续
		return

	var dep_x = edge.departure_point.x
	var dist = abs(global_pos.x - dep_x)
	var dir = sign(dep_x - global_pos.x)

	if dist > _arrival_threshold:
		result["velocity_x"] = dir * _move_speed
	else:
		# 到达出发点，执行转换
		match edge.edge_type:
			NavEdge.EdgeType.JUMP_UP:
				result["should_jump"] = true
				result["velocity_x"] = edge.jump_direction * _move_speed
				state = FollowerState.EXECUTING_TRANSITION
				_timeout_timer = 0.0
			NavEdge.EdgeType.DROP_DOWN:
				result["velocity_x"] = edge.jump_direction * _move_speed * 0.7
				state = FollowerState.EXECUTING_TRANSITION
				_timeout_timer = 0.0
			NavEdge.EdgeType.WALK:
				# 直接完成这一步
				current_path.advance()
				_timeout_timer = 0.0
				if current_path.is_complete():
					state = FollowerState.PATH_COMPLETE
					result["done"] = true
				else:
					state = FollowerState.WALKING_TO_DEPARTURE


func _update_executing_transition(edge: NavEdge, is_on_floor: bool, global_pos: Vector2, result: Dictionary) -> void:
	if is_on_floor:
		# 着陆了 - 检查是否在目标平台附近
		var arr_x = edge.arrival_point.x
		var dist_to_arrival = abs(global_pos.x - arr_x)

		if dist_to_arrival < _landing_threshold:
			# 成功着陆在目标附近
			state = FollowerState.LANDING
			_stabilize_timer = _landing_duration
		else:
			# 着陆但偏离目标点，继续走向目标
			state = FollowerState.LANDING
			_stabilize_timer = _landing_duration * 0.5
	else:
		# 空中：调整水平方向朝向目标
		var arr_x = edge.arrival_point.x
		var dir = sign(arr_x - global_pos.x)
		result["velocity_x"] = dir * _move_speed


func _update_landing(delta: float, edge: NavEdge, global_pos: Vector2, result: Dictionary) -> void:
	_stabilize_timer -= delta
	if _stabilize_timer <= 0:
		current_path.advance()
		_timeout_timer = 0.0
		if current_path.is_complete():
			state = FollowerState.PATH_COMPLETE
		else:
			state = FollowerState.WALKING_TO_DEPARTURE
