# GameManager.gd (初始版本)
extends Node

# 游戏状态
enum GameState { P1_TURN, P2_TURN, GAME_OVER }
var current_state: GameState

# 玩家数据
var p1_deck: Array[CardData]
var p1_hand: Array[CardData]
var p1_territory: Array # 将存储 CardUI 节点的实例
var p1_graveyard: Array[CardData]

var p2_deck: Array[CardData]
var p2_hand: Array[CardData]
var p2_territory: Array # 将存储 CardUI 节点的实例
var p2_graveyard: Array[CardData]

var has_extra_action: bool = false # 用于倍数连击
var pass_counter: int = 0

enum TargetingState { NONE, SELECT_OWN_CARD, SELECT_ENEMY_CARD }
var targeting_state: TargetingState = TargetingState.NONE
var pending_function_card: CardData

var p1_score = 0
var p2_score = 0

# 信号，用于通知UI更新
signal turn_changed(player_name)
signal hand_updated(player_id, hand)
signal territory_updated(player_id, territory)
signal round_over(winner_text)


func _ready():
	# 为了测试，我们先硬编码一个牌库
	setup_test_decks()
	start_game()

func setup_test_decks():
	# 加载之前创建的卡牌资源
	var num2 = load("res://number_2.tres")
	var num4 = load("res://number_4.tres") # 假设你已创建
	var kingship = load("res://function_kingship.tres")

	p1_deck = [num2, num2, num4, num4, kingship]
	p2_deck = [num2, num2, num4, num4, kingship]
	# 在真实游戏中，这里会从一个完整的牌库列表中构建30张牌

func start_game():
	p1_deck.shuffle()
	p2_deck.shuffle()
	# ... 初始化手牌、领地等 ...
	for i in 4:
		draw_card(1)
		draw_card(2)

	current_state = GameState.P1_TURN
	emit_signal("turn_changed", "玩家1")

func draw_card(player_id):
	if player_id == 1 and not p1_deck.is_empty():
		var card = p1_deck.pop_front()
		p1_hand.append(card)
		emit_signal("hand_updated", 1, p1_hand)
	# ... 为玩家2实现相同的逻辑 ...
	

# 当玩家从手牌点击一张牌时，由Game.gd调用此函数
func play_card_from_hand(card_data, player_id):
	# 检查是否是该玩家的回合等...
	# ...
	
	# 如果是数字牌
	if card_data.card_type == CardData.CardType.NUMBER:
		# 假设玩家总是放到第一个空位
		var target_territory = p1_territory if player_id == 1 else p2_territory
		if target_territory.size() < 3:
			# 从手牌移除
			p1_hand.erase(card_data) # 或 p2_hand
			# 添加到领地 (这里我们暂时只存数据)
			target_territory.append(card_data)
			
			# 更新UI
			emit_signal("hand_updated", player_id, p1_hand if player_id == 1 else p2_hand)
			emit_signal("territory_updated", player_id, target_territory)
			
			# 检查倍数连击
			check_for_combo(card_data, target_territory)
			
			# 如果没有连击，则结束回合
			if not has_extra_action:
				end_turn()
			else:
				print("倍数连击！获得额外行动！")
				has_extra_action = false # 重置标志
	if card_data.card_type == CardData.CardType.FUNCTION:
		pending_function_card = card_data
		# 根据功能牌ID设置目标状态
		match card_data.function_id:
			"kingship":
				targeting_state = TargetingState.SELECT_OWN_CARD
				print("请选择一张你的数字牌进行翻倍。")
			"zero_out":
				targeting_state = TargetingState.SELECT_ENEMY_CARD
				print("请选择一张对手的数字牌进行归零。")

func check_for_combo(played_card, territory):
	for existing_card in territory:
		if existing_card == played_card: continue # 跳过自己
		
		# GDD规则：倍数或被整除
		if (played_card.base_value % existing_card.base_value == 0) or \
		   (existing_card.base_value % played_card.base_value == 0):
			has_extra_action = true
			return # 找到一个即可

func end_turn():
	if current_state == GameState.P1_TURN:
		current_state = GameState.P2_TURN
		emit_signal("turn_changed", "玩家2")
		draw_card(2) # 下个玩家抽牌
	else:
		current_state = GameState.P1_TURN
		emit_signal("turn_changed", "玩家1")
		draw_card(1)


func apply_function_effect(target_card_ui):
	var target_card_data = target_card_ui.card_data
	
	match pending_function_card.function_id:
		"kingship":
			# 在CardUI实例上直接修改 current_value
			target_card_ui.current_value *= 2
			target_card_ui.update_display()
		"zero_out":
			target_card_ui.current_value = 0
			target_card_ui.update_display()
		# ... 其他效果 ...

	# 重置状态
	targeting_state = TargetingState.NONE
	pending_function_card = null
	end_turn() # 使用功能牌后结束回合


func player_pass():
	pass_counter += 1
	if pass_counter >= 2:
		end_round()
	else:
		end_turn() # 只是传递，不是结束回合
		


func end_round():
	current_state = GameState.GAME_OVER
	var p1_total = 0
	for card_ui in p1_territory_ui_nodes: # 你需要一个地方存储领地UI节点的引用
		p1_total += card_ui.current_value
		
	var p2_total = 0
	# ... 计算玩家2的总分 ...

	var winner_text = ""
	if p1_total > p2_total:
		p1_score += 1
		winner_text = "玩家1 获胜! P1: %d, P2: %d" % [p1_total, p2_total]
	elif p2_total > p1_total:
		p2_score += 1
		winner_text = "玩家2 获胜! P1: %d, P2: %d" % [p1_total, p2_total]
	else:
		winner_text = "平局! P1: %d, P2: %d" % [p1_total, p2_total]
		
	emit_signal("round_over", winner_text)
	
	# 之后可以添加开始新一局的逻辑
