## 路径数据 - 表示一条计算好的导航路径
class_name PlatformPath
extends RefCounted

## 路径中的一个步骤
class PathStep:
	var edge: NavEdge
	var target_platform: String

	func _init(e: NavEdge, target: String) -> void:
		edge = e
		target_platform = target

## 有序步骤列表
var steps: Array[PathStep] = []

## 当前步骤索引
var current_step_index: int = 0


func is_empty() -> bool:
	return steps.size() == 0


func is_complete() -> bool:
	return current_step_index >= steps.size()


func current_step() -> PathStep:
	if is_complete():
		return null
	return steps[current_step_index]


func advance() -> void:
	current_step_index += 1


func reset() -> void:
	current_step_index = 0


func destination() -> String:
	if steps.size() == 0:
		return ""
	return steps[-1].target_platform
