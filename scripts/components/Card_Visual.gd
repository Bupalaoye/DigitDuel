# Card_Visual.gd
# 这个脚本控制 Card_Visual.tscn 场景的显示和基本交互。
# 它的核心职责是接收一个 CardRuntimeData 对象，并根据其数据更新UI。

class_name CardVisual
extends Control

# --- 信号 (Signals) ---
# CardVisual 只负责发出“发生了什么事”的信号，具体如何响应由外部管理器决定。
signal clicked(card_visual: CardVisual)

# --- 节点引用 (@onready) ---
# 使用 % 语法可以确保引用的节点路径是唯一的，更健壮。
@onready var name_label: Label = %NameLabel
@onready var artwork_rect: TextureRect = %Artwork
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var value_label: Label = %ValueLabel
@onready var highlight_rect: ColorRect = %Highlight
@onready var immune_icon: TextureRect = %ImmuneIcon

var scale_tween: Tween

# --- 数据存储 ---
# 存储传入的运行时数据，这是卡牌所有显示内容的来源。
var runtime_data: CardRuntimeData

# --- Godot 生命周期函数 ---
func _ready() -> void:
	# 连接内置的信号到我们的处理函数
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# =============================================================================
# 核心公共方法 (Public API)
# =============================================================================

# 这是该组件最重要的函数。外部代码通过调用它来“绘制”一张卡牌。
func display(data: CardRuntimeData) -> void:
	if not data or not is_instance_valid(data.definition):
		print("CardVisual: 提供了无效的 CardRuntimeData 或其定义。")
		# 可以选择隐藏卡牌或显示一个“错误”状态
		hide()
		return

	self.runtime_data = data
	var definition = data.definition

	# 1. 更新通用内容
	name_label.text = definition.common_name
	artwork_rect.texture = definition.common_artwork
	description_label.text = definition.common_description

	# 2. 根据卡牌类型更新特定内容
	if definition.type == CardData.CardType.NUMBER:
		value_label.text = str(data.current_value)
		value_label.show()
		description_label.hide() # 数字牌通常不显示描述
	else: # Function Card
		value_label.hide()
		description_label.show()

	# 3. 更新状态图标
	immune_icon.visible = data.is_immune
	
	# 确保更新后卡牌是可见的
	show()


# 控制高亮效果的开关
func set_highlight(is_on: bool) -> void:
	highlight_rect.visible = is_on


# =============================================================================
# 信号处理函数 (Private Signal Handlers)
# =============================================================================

func _on_gui_input(event: InputEvent) -> void:
	# 当在卡牌区域内发生鼠标点击事件时
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# 发出信号，并把自己作为参数传递出去
		print('clicked')
		GameManager.on_hand_card_selected(runtime_data)

func _on_mouse_entered() -> void:
	print('_on_mouse_entered')
	highlight_rect.visible = true
	# 1. 如果有正在进行的缩放动画，先杀掉它
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()

	# 2. 创建一个新的 Tween 实例
	scale_tween = create_tween()
	
	# 3. 在这个 Tween 上 "预定" 一个属性动画
	#    参数：对象, 属性名, 最终值, 持续时间
	scale_tween.tween_property(self, "scale", Vector2.ONE * 1.05, 0.1)\
			   .set_trans(Tween.TRANS_SINE)\
			   .set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	# 恢复原状
	print('_on_mouse_exited')
	highlight_rect.visible = false
	# 1. 同样，先杀掉可能存在的旧动画
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
		
	# 2. 创建一个新的 Tween 来恢复原状
	scale_tween = create_tween()
	
	# 3. 预定恢复动画
	scale_tween.tween_property(self, "scale", Vector2.ONE, 0.1)\
			   .set_trans(Tween.TRANS_SINE)\
			   .set_ease(Tween.EASE_OUT)
