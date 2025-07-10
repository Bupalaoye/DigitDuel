# GameBoard.gd
# 游戏主板的控制脚本，负责将GameManager的数据变化，同步到视觉表现上。

extends Control

@onready var player1_hand_container: HBoxContainer = %Player1Hand
@onready var player2_hand_container: HBoxContainer = %Player2Hand
@onready var start_game_button: Button = %StartGameButton

var player_territory:Array[HBoxContainer] = []


func _ready() -> void:
	player_territory.append(%Player1Territory)
	player_territory.append(%Player2Territory)
	# 连接按钮的 "pressed" 信号到我们的处理函数
	start_game_button.pressed.connect(_on_start_game_button_pressed)
	
	# 连接 GameManager 的 "hand_updated" 信号到我们的处理函数
	# 这是解耦的关键：GameManager 不知道任何UI细节，它只负责喊一声"手牌变了！"
	GameManager.hand_updated.connect(update_hand_display)
	GameManager.territory_updated.connect(update_territory_display)
	setup_territory_slots()

# 当开始游戏按钮被点击时
func _on_start_game_button_pressed() -> void:
	# 调用GameManager的全局方法来开始游戏
	print('_on_start_game_button_pressed')
	GameManager.start_new_game()
	# 开始后可以隐藏按钮
	start_game_button.hide()


# 更新指定玩家的手牌显示
func update_hand_display(player_id: int) -> void:
	var hand_container: HBoxContainer
	
	# 根据 player_id 选择正确的容器
	if player_id == 0:
		hand_container = player1_hand_container
	elif player_id == 1:
		hand_container = player2_hand_container
	else:
		return # 无效的玩家ID

	# 1. 清空当前手牌显示
	for child in hand_container.get_children():
		child.queue_free()

	# 2. 获取最新的手牌数据
	var player_hand_data: Array[CardRuntimeData] = GameManager.players[player_id].hand

	# 3. 重新根据数据创建所有卡牌的视觉实例
	for card_runtime_data in player_hand_data:
		var card_visual: CardVisual = GameManager.CardVisualScene.instantiate()
		hand_container.add_child(card_visual)
		
		# 将数据注入视觉！
		card_visual.display(card_runtime_data)

func setup_territory_slots():
	for _player_id in range(2):
		# 设置玩家1的卡槽
		for i in range(player_territory[_player_id].get_child_count()):
			var slot: TerritorySlot = player_territory[_player_id].get_child(i)
			slot.player_id = 0
			slot.slot_index = i
			slot.selected.connect(_on_territory_slot_selected)


# 当一个领地卡槽被点击时
func _on_territory_slot_selected(slot: TerritorySlot):
	print("Territory slot clicked! Owner: %d, Index: %d" % [slot.player_id, slot.slot_index])
	# 通知GameManager，玩家尝试对这个卡槽进行操作
	GameManager.on_territory_slot_selected(slot.player_id, slot.slot_index)


func _on_card_in_hand_clicked(card_visual: CardVisual):
	print("Hand card clicked: %s" % card_visual.runtime_data.definition.common_name)
	# 通知 GameManager
	GameManager.on_hand_card_selected(card_visual.runtime_data)

# 在 update_display 中也需要更新领地
func update_display() -> void:
	update_hand_display(0)
	update_hand_display(1)
	update_territory_display(0)
	update_territory_display(1)

func update_territory_display(player_id: int) -> void:
	var territory_container = player_territory[player_id]
	var territory_data: Array = GameManager.players[player_id].territory

	for i in range(territory_container.get_child_count()):
		var slot_node: TerritorySlot = territory_container.get_child(i)
		var card_runtime: CardRuntimeData = territory_data[i]

		if card_runtime:
			# 如果卡槽里有牌
			# 检查卡槽是否已经有对应的视觉实例，避免重复创建
			if not is_instance_valid(slot_node.current_card_visual) or slot_node.current_card_visual.runtime_data.unique_instance_id != card_runtime.unique_instance_id:
				var card_visual = GameManager.CardVisualScene.instantiate()
				card_visual.display(card_runtime)
				slot_node.set_card(card_visual)
			else:
				# 如果已经是正确的卡，只更新显示（比如点数变化）
				slot_node.current_card_visual.display(card_runtime)
		else:
			# 如果卡槽里没牌
			slot_node.clear_card()


func _on_territory_slot_3_mouse_entered() -> void:
	print('_on_territory_slot_3_mouse_entered')
