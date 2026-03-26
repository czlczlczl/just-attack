## 按键控制器 - 管理按键提示面板
extends PanelContainer

## 所有按键绑定
var key_bindings: Array = []

func _ready() -> void:
	_initialize_key_bindings()
	_update_ui()

## 初始化按键绑定
func _initialize_key_bindings() -> void:
	key_bindings = [
		{"action": "移动", "keys": ["A", "D", "←", "→"], "description": "左右移动"},
		{"action": "跳跃", "keys": ["Space"], "description": "跳跃"},
		{"action": "下蹲", "keys": ["S"], "description": "下蹲/蹲下"},
		{"action": "攻击 1", "keys": ["J"], "description": "近战攻击 (剑)"},
		{"action": "攻击 2", "keys": ["K"], "description": "远程攻击 (弓)"},
		{"action": "攻击 3", "keys": ["L"], "description": "法术攻击 (法杖)"},
		{"action": "切换武器", "keys": ["Q", "E"], "description": "切换武器"},
		{"action": "暂停", "keys": ["Escape", "Enter(手柄)"], "description": "暂停/继续游戏"},
		{"action": "帮助", "keys": ["H"], "description": "显示/隐藏本面板"},
	]

## 更新 UI 显示
func _update_ui() -> void:
	var container = $VBoxContainer
	if not container:
		return

	# 清除现有内容
	for child in container.get_children():
		child.queue_free()

	# 添加标题
	var title = Label.new()
	title.text = "操作说明"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(title)

	var separator = HSeparator.new()
	container.add_child(separator)

	# 添加按键绑定
	for binding in key_bindings:
		var hbox = HBoxContainer.new()

		var action_label = Label.new()
		action_label.text = binding["action"] + ":"
		action_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		action_label.custom_minimum_size.x = 100
		hbox.add_child(action_label)

		var keys_label = Label.new()
		keys_label.text = " [ " + " / ".join(binding["keys"]) + " ]"
		keys_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
		hbox.add_child(keys_label)

		var desc_label = Label.new()
		desc_label.text = " - " + binding["description"]
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(desc_label)

		container.add_child(hbox)

## 切换面板显示
func toggle_panel() -> void:
	visible = not visible

## 显示面板
func show_panel() -> void:
	visible = true

## 隐藏面板
func hide_panel() -> void:
	visible = false
