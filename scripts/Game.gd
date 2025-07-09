# Game.gd
extends Node2D

@onready var p1_hand_container = $P1_Area/P1_Hand
# ... 获取所有UI节点的引用 ...
@onready var turn_indicator = $TurnIndicatorLabel

func _ready():
	GameManager.turn_changed.connect(on_turn_changed)
	GameManager.hand_updated.connect(on_hand_updated)
	# ... 连接其他信号 ...

func on_turn_changed(player_name):
	turn_indicator.text = player_name + "的回合"

func on_hand_updated(player_id, hand_data):
	if player_id == 1:
		# 清空旧的手牌UI
		for child in p1_hand_container.get_children():
			child.queue_free()
		# 创建新的手牌UI
		for card_data in hand_data:
			var card_ui = preload("uid://mv5dy3rfs8lj").instantiate()
			card_ui.card_clicked.connect(on_card_in_hand_clicked) # 新增连接
			p1_hand_container.add_child(card_ui)
			card_ui.card_data = card_data
			card_ui.current_value = card_data.base_value # 初始化当前值
			card_ui.update_display()
# ... 为玩家2也实现相同的逻辑 ...


# Game.gd 中添加一个新的处理函数
func on_card_in_territory_clicked(card_ui_instance):
	if GameManager.targeting_state != GameManager.TargetingState.NONE:
		# 检查目标是否合法等...
		GameManager.apply_function_effect(card_ui_instance)

# 别忘了在创建领地卡牌UI时，也连接其 clicked 信号到这个新函数
func _on_pass_button_pressed():
	GameManager.player_pass()
