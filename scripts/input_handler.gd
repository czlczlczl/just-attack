## 输入处理器 - 统一处理键盘和手柄输入
## AutoLoad 单例，通过 InputHandler 访问
extends Node

## 移动方向输入
var move_direction: Vector2 = Vector2.ZERO

## 是否下蹲
var is_crouching: bool = false

## 当前选择的武器索引
var current_weapon_index: int = 0

## 信号：移动输入改变
signal move_input_changed(direction: Vector2)

## 信号：跳跃按下
signal jump_pressed

## 信号：下蹲输入改变
signal crouch_input_changed(is_crouching: bool)

## 信号：攻击按下
signal attack_pressed(attack_index: int)

## 信号：武器切换按下
signal weapon_switch_pressed(direction: int)

## 信号：暂停按下
signal pause_pressed

## 信号：切换帮助面板
signal toggle_help_pressed

## 手柄震动强度 (0-1)
var controller_vibration: float = 0.0

func _ready() -> void:
	print("[InputHandler] Initialized")

func _input(event: InputEvent) -> void:
	# 只处理按下事件，避免重复触发
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_keyboard_input(event)
	elif event is InputEventJoypadButton and event.pressed:
		_handle_controller_input(event)
	elif event is InputEventJoypadMotion:
		_handle_joypad_motion(event)

func _handle_keyboard_input(event: InputEventKey) -> void:
	var prev_x: float = move_direction.x

	match event.physical_keycode:
		KEY_A, KEY_LEFT:
			if event.pressed:
				move_direction.x = -1
			else:
				if move_direction.x < 0:
					move_direction.x = 0
			move_input_changed.emit(move_direction)
		KEY_D, KEY_RIGHT:
			if event.pressed:
				move_direction.x = 1
			else:
				if move_direction.x > 0:
					move_direction.x = 0
			move_input_changed.emit(move_direction)
		KEY_SPACE:
			jump_pressed.emit()
		KEY_S:
			is_crouching = event.pressed
			crouch_input_changed.emit(is_crouching)
		KEY_J:
			attack_pressed.emit(0)
		KEY_K:
			attack_pressed.emit(1)
		KEY_L:
			attack_pressed.emit(2)
		KEY_Q:
			weapon_switch_pressed.emit(-1)
		KEY_E:
			weapon_switch_pressed.emit(1)
		KEY_ESCAPE:
			pause_pressed.emit()
		KEY_H:
			toggle_help_pressed.emit()

func _handle_controller_input(event: InputEventJoypadButton) -> void:
	match event.button_index:
		JOY_BUTTON_A:
			jump_pressed.emit()
		JOY_BUTTON_X:
			attack_pressed.emit(0)
		JOY_BUTTON_Y:
			attack_pressed.emit(1)
		JOY_BUTTON_B:
			attack_pressed.emit(2)
		JOY_BUTTON_LEFT_SHOULDER:
			weapon_switch_pressed.emit(-1)
		JOY_BUTTON_RIGHT_SHOULDER:
			weapon_switch_pressed.emit(1)
		JOY_BUTTON_START:
			pause_pressed.emit()

func _handle_joypad_motion(event: InputEventJoypadMotion) -> void:
	match event.axis:
		JOY_AXIS_LEFT_X:
			if abs(event.axis_value) < 0.2:
				move_direction.x = 0
			else:
				move_direction.x = sign(event.axis_value)
			move_input_changed.emit(move_direction)
		JOY_AXIS_LEFT_Y:
			# 下蹲使用十字键下
			pass
		JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT:
			# 肩键用于切换武器
			pass

## 获取归一化的移动方向
func get_normalized_move() -> Vector2:
	return move_direction.normalized()

## 触发手柄震动
func trigger_vibration(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	Input.start_joy_vibration(0, weak_magnitude, strong_magnitude, duration)
