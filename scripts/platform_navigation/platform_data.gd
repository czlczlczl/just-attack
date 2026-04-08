## 平台数据 - 表示一个可行走的平台表面
class_name PlatformData
extends RefCounted

## 唯一标识 (如 "ground", "L1_1")
var id: String = ""

## 顶部可行走表面 (x范围, y=顶面坐标, height=0)
var surface_rect: Rect2 = Rect2()

## 平台中心的世界坐标
var center: Vector2 = Vector2.ZERO


func left_edge() -> float:
	return surface_rect.position.x


func right_edge() -> float:
	return surface_rect.position.x + surface_rect.size.x


func top_y() -> float:
	return surface_rect.position.y


func contains_x(x: float) -> bool:
	return x >= left_edge() and x <= right_edge()
