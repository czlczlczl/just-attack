## 游戏管理器 - 全局游戏状态管理
## AutoLoad 单例，通过 GameManager 访问
extends Node

## 游戏状态枚举
enum GameState { PLAYING, PAUSED, GAME_OVER, VICTORY }

## 玩家引用
var player: Node2D = null

## 当前关卡索引
var current_level: int = 0

## 当前游戏状态
var game_state: GameState = GameState.PLAYING:
	set(value):
		game_state = value
		_on_game_state_changed(value)

## 玩家得分
var score: int = 0

## 玩家生命值
var player_health: int = 100

## 信号：游戏状态改变
signal game_state_changed(new_state: GameState)

## 信号：玩家死亡
signal player_died

## 信号：得分改变
signal score_changed(new_score: int)

## 信号：生命值改变
signal health_changed(new_health: int)

func _ready() -> void:
	print("[GameManager] Initialized")

## 注册玩家引用
func register_player(player_node: Node2D) -> void:
	player = player_node

## 改变游戏状态
func change_state(new_state: GameState) -> void:
	if game_state == new_state:
		return

	game_state = new_state

func _on_game_state_changed(new_state: GameState) -> void:
	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.GAME_OVER:
			get_tree().paused = true
			print("[GameManager] Game Over!")
		GameState.VICTORY:
			get_tree().paused = true
			print("[GameManager] Victory!")

## 玩家受伤
func take_damage(amount: int) -> void:
	player_health = max(0, player_health - amount)
	health_changed.emit(player_health)

	if player_health <= 0:
		change_state(GameState.GAME_OVER)
		player_died.emit()

## 玩家得分
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

## 重新开始游戏
func restart_game() -> void:
	score = 0
	player_health = 100
	current_level = 0
	change_state(GameState.PLAYING)
	get_tree().reload_current_scene()
