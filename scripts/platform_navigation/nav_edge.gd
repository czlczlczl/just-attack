## 导航边 - 表示两个平台之间的可达转换
class_name NavEdge
extends RefCounted

enum EdgeType {
	WALK,       ## 同高度行走
	JUMP_UP,    ## 跳跃上升
	DROP_DOWN,  ## 跳下/落下
}

## 起始平台 ID
var from_id: String = ""

## 目标平台 ID
var to_id: String = ""

## 转换类型
var edge_type: EdgeType = EdgeType.WALK

## 出发点 (在起始平台上的世界坐标)
var departure_point: Vector2 = Vector2.ZERO

## 到达点 (在目标平台上的世界坐标)
var arrival_point: Vector2 = Vector2.ZERO

## 跳跃方向: 1=右, -1=左
var jump_direction: int = 0

## 预估时间成本 (秒)
var cost: float = 1.0
