## 平台导航图 - 预计算的平台间可达关系图
extends Node

## 所有平台数据
var platforms: Dictionary = {}  # String -> PlatformData

## 邻接表: platform_id -> Array[NavEdge]
var adjacency: Dictionary = {}

## 史莱姆跳跃参数
const JUMP_FORCE: float = 400.0
const GRAVITY: float = 980.0
const JUMP_H_SPEED: float = 150.0
const MAX_JUMP_HEIGHT: float = 82.0  # v^2 / (2g) ≈ 81.6
## 最大下落距离 (只允许逐层下落，避免穿越中间平台)
const MAX_DROP_DISTANCE: float = 100.0


func _ready() -> void:
	_build_platforms()
	_build_edges()


func _build_platforms() -> void:
	# ground: center (0,300), collision 2000x50, top_y = 300-25 = 275
	_add_platform("ground", -1000, 275, 2000, Vector2(0, 300))

	# L1 platforms: center y=208, collision 16px tall, top_y = 208-8 = 200
	_add_platform("L1_1", -790, 200, 180, Vector2(-700, 208))
	_add_platform("L1_2", -375, 200, 150, Vector2(-300, 208))
	_add_platform("L1_3", 0, 200, 200, Vector2(100, 208))
	_add_platform("L1_4", 370, 200, 160, Vector2(450, 208))
	_add_platform("L1_5", 660, 200, 180, Vector2(750, 208))

	# L2 platforms: center y=133, top_y = 133-8 = 125
	_add_platform("L2_1", -600, 125, 200, Vector2(-500, 133))
	_add_platform("L2_2", -90, 125, 180, Vector2(0, 133))
	_add_platform("L2_3", 420, 125, 160, Vector2(500, 133))

	# L3 platforms: center y=58, top_y = 58-8 = 50
	_add_platform("L3_1", -330, 50, 160, Vector2(-250, 58))
	_add_platform("L3_2", 150, 50, 200, Vector2(250, 58))


func _add_platform(id: String, left_x: float, top_y: float, width: float, center: Vector2) -> void:
	var pd = PlatformData.new()
	pd.id = id
	pd.surface_rect = Rect2(left_x, top_y, width, 0)
	pd.center = center
	platforms[id] = pd
	adjacency[id] = []


func _build_edges() -> void:
	var ids = platforms.keys()

	for i in range(ids.size()):
		for j in range(ids.size()):
			if i == j:
				continue
			var a: PlatformData = platforms[ids[i]]
			var b: PlatformData = platforms[ids[j]]
			_try_add_edge(a, b)

	# 打印调试信息
	var total_edges = 0
	for id in ids:
		total_edges += adjacency[id].size()
		var edges_str = ""
		for edge: NavEdge in adjacency[id]:
			edges_str += "  %s --[%s]--> %s (dep:%.0f,%.0f arr:%.0f,%.0f dir:%d)\n" % [
				edge.from_id,
				"JUMP" if edge.edge_type == NavEdge.EdgeType.JUMP_UP else "DROP" if edge.edge_type == NavEdge.EdgeType.DROP_DOWN else "WALK",
				edge.to_id,
				edge.departure_point.x, edge.departure_point.y,
				edge.arrival_point.x, edge.arrival_point.y,
				edge.jump_direction
			]
		print("[PlatformGraph] %s edges:\n%s" % [id, edges_str])
	print("[PlatformGraph] Total: %d platforms, %d edges" % [ids.size(), total_edges])


func _try_add_edge(a: PlatformData, b: PlatformData) -> void:
	# Godot y轴向下为正:
	# a.top_y > b.top_y → a 在下面 (y值大 = 屏幕下方) → 可以 JUMP_UP 到 b
	# a.top_y < b.top_y → a 在上面 (y值小 = 屏幕上方) → 可以 DROP_DOWN 到 b
	var vert_gap = a.top_y() - b.top_y()

	if abs(vert_gap) < 5.0:
		_try_walk_edge(a, b)
	elif vert_gap > 0 and vert_gap <= MAX_JUMP_HEIGHT:
		# a 在下面, 跳跃上升到 b
		_try_jump_up_edge(a, b, vert_gap)
	elif vert_gap < 0 and abs(vert_gap) <= MAX_DROP_DISTANCE:
		# a 在上面, 跳下到 b
		_try_drop_edge(a, b, abs(vert_gap))


func _try_walk_edge(a: PlatformData, b: PlatformData) -> void:
	var gap = _horizontal_gap(a, b)
	if gap > 30.0:
		return

	var dep_x = _clamp_to_platform(b.center.x, a)
	var arr_x = _clamp_to_platform(dep_x, b)
	var dir = sign(arr_x - dep_x)
	if dir == 0:
		dir = 1

	var edge = NavEdge.new()
	edge.from_id = a.id
	edge.to_id = b.id
	edge.edge_type = NavEdge.EdgeType.WALK
	edge.departure_point = Vector2(dep_x, a.top_y())
	edge.arrival_point = Vector2(arr_x, b.top_y())
	edge.jump_direction = dir
	edge.cost = 0.5
	adjacency[a.id].append(edge)


func _try_jump_up_edge(a: PlatformData, b: PlatformData, vert_gap: float) -> void:
	# 计算跳跃到达目标高度的下降时间点
	# y(t) = a.top_y - JUMP_FORCE*t + 0.5*GRAVITY*t^2 = b.top_y
	# 解方程得到两个时间点, 取下降段的时间
	var peak_height = JUMP_FORCE * JUMP_FORCE / (2.0 * GRAVITY)
	var discriminant = peak_height - vert_gap
	if discriminant < 0:
		return

	var t_peak = JUMP_FORCE / GRAVITY
	var half_window = sqrt(2.0 * discriminant / GRAVITY)
	var t_descending = t_peak + half_window  # 下降到目标高度的时间

	# 从 a 上各候选点找最佳出发点
	var best_dep_x: float = NAN
	var best_score: float = 999999.0
	# 安全边距: 史莱姆碰撞宽度32px, 至少离边缘20px
	var margin = 25.0

	var candidates = [
		a.left_edge() + margin,
		a.right_edge() - margin,
		_clamp_to_platform(b.center.x, a),
		_clamp_to_platform((b.left_edge() + b.right_edge()) / 2.0, a),
	]

	for cand_x in candidates:
		if cand_x < a.left_edge() + margin or cand_x > a.right_edge() - margin:
			continue
		# 计算以 cand_x 为出发点, 需要的水平速度
		# 目标: 着陆在 b 平台内 (尽量靠近中心)
		var target_x = _clamp_to_platform(cand_x, b)
		# 如果 cand_x 在 b 范围上方, 瞄准 b 的中心附近
		if cand_x >= b.left_edge() and cand_x <= b.right_edge():
			target_x = cand_x  # 直接上方, 瞄准正上方

		var needed_vx = (target_x - cand_x) / t_descending if t_descending > 0 else 0.0

		# 检查所需水平速度是否可达
		if abs(needed_vx) > JUMP_H_SPEED:
			continue

		# 计算实际着陆点
		var landing_x = cand_x + needed_vx * t_descending
		if landing_x < b.left_edge() + 2.0 or landing_x > b.right_edge() - 2.0:
			continue  # 着陆点超出目标平台

		# 评分: 偏好需要水平速度小且着陆在平台中央的
		var score = abs(needed_vx) * 2.0 + abs(landing_x - b.center.x) * 0.01
		if score < best_score:
			best_score = score
			best_dep_x = cand_x

	if best_dep_x != best_dep_x:  # NAN check
		return

	var dep_x = best_dep_x
	var arr_x = _clamp_to_platform(dep_x, b)
	if dep_x >= b.left_edge() and dep_x <= b.right_edge():
		arr_x = dep_x  # 正上方, 着陆在出发点正上方

	var final_vx = (arr_x - dep_x) / t_descending if t_descending > 0 else 0.0
	var dir = sign(final_vx) if abs(final_vx) > 1.0 else 0

	var edge = NavEdge.new()
	edge.from_id = a.id
	edge.to_id = b.id
	edge.edge_type = NavEdge.EdgeType.JUMP_UP
	edge.departure_point = Vector2(dep_x, a.top_y())
	edge.arrival_point = Vector2(arr_x, b.top_y())
	edge.jump_direction = dir
	edge.cost = 1.5
	adjacency[a.id].append(edge)


func _try_drop_edge(a: PlatformData, b: PlatformData, vert_gap: float) -> void:
	var fall_time = sqrt(2.0 * vert_gap / GRAVITY)
	var h_range = JUMP_H_SPEED * fall_time
	var margin = 25.0

	# 尝试多个候选出发点
	var candidates = [
		_clamp_to_platform(b.center.x, a),
		a.left_edge() + margin,
		a.right_edge() - margin,
		_clamp_to_platform((b.left_edge() + b.right_edge()) / 2.0, a),
	]

	var best_dep_x: float = NAN
	var best_gap: float = 999999.0

	for cand_x in candidates:
		if cand_x < a.left_edge() + margin or cand_x > a.right_edge() - margin:
			continue
		var gap = _horizontal_gap_from_point(cand_x, a, b)
		if gap > h_range + 20.0:
			continue
		if gap < best_gap:
			best_gap = gap
			best_dep_x = cand_x

	if best_dep_x != best_dep_x:  # NAN check
		return

	var dep_x = best_dep_x
	var arr_x = _clamp_to_platform(dep_x, b)
	var dir = sign(arr_x - dep_x)
	if dir == 0:
		dir = sign(b.center.x - dep_x)
	if dir == 0:
		dir = 1

	var edge = NavEdge.new()
	edge.from_id = a.id
	edge.to_id = b.id
	edge.edge_type = NavEdge.EdgeType.DROP_DOWN
	edge.departure_point = Vector2(dep_x, a.top_y())
	edge.arrival_point = Vector2(arr_x, b.top_y())
	edge.jump_direction = dir
	edge.cost = 1.0 + vert_gap / 200.0
	adjacency[a.id].append(edge)


## 计算两个平台最近边之间的水平间距
func _horizontal_gap(a: PlatformData, b: PlatformData) -> float:
	if a.right_edge() < b.left_edge():
		return b.left_edge() - a.right_edge()
	elif b.right_edge() < a.left_edge():
		return a.left_edge() - b.right_edge()
	return 0.0


## 从 a 上某点出发到 b 的最近水平距离
func _horizontal_gap_from_point(x: float, _a: PlatformData, b: PlatformData) -> float:
	if x >= b.left_edge() and x <= b.right_edge():
		return 0.0
	if x < b.left_edge():
		return b.left_edge() - x
	return x - b.right_edge()


## 将 x 坐标限制在平台范围内
func _clamp_to_platform(x: float, p: PlatformData) -> float:
	return clampf(x, p.left_edge(), p.right_edge())


## 获取指定世界坐标所在的平台 ID
func get_platform_at(world_pos: Vector2) -> String:
	var best_id = ""
	var best_dist = 999999.0

	for id in platforms:
		var p: PlatformData = platforms[id]
		# 检查 x 是否在平台范围内 (留容差)
		if world_pos.x < p.left_edge() - 10.0 or world_pos.x > p.right_edge() + 10.0:
			continue
		# y 距离: 实体 global_position 在平台表面上方 (y更小)
		# 允许的最大距离: 实体高度的一半 + 一些容差
		var y_dist = abs(world_pos.y - p.top_y())
		# 只考虑距离表面40px以内的平台
		if y_dist > 40.0:
			continue
		if y_dist < best_dist:
			best_dist = y_dist
			best_id = id

	return best_id


## 使用 BFS 查找从 from_id 到 to_id 的最短路径
func find_path(from_id: String, to_id: String) -> PlatformPath:
	if from_id == "" or to_id == "":
		return null
	if from_id == to_id:
		return null
	if not platforms.has(from_id) or not platforms.has(to_id):
		return null

	var queue: Array[String] = [from_id]
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	visited[from_id] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		if current == to_id:
			return _reconstruct_path(parent, from_id, to_id)

		for edge: NavEdge in adjacency[current]:
			if not visited.has(edge.to_id):
				visited[edge.to_id] = true
				parent[edge.to_id] = edge
				queue.append(edge.to_id)

	return null


func _reconstruct_path(parent: Dictionary, from_id: String, to_id: String) -> PlatformPath:
	var path = PlatformPath.new()
	var edges: Array[NavEdge] = []

	var current = to_id
	while current != from_id:
		var edge: NavEdge = parent[current]
		edges.append(edge)
		current = edge.from_id

	edges.reverse()

	for edge in edges:
		var step = PlatformPath.PathStep.new(edge, edge.to_id)
		path.steps.append(step)

	return path
