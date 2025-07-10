# GameManager.gd
# 游戏的核心管理器，作为单例(AutoLoad)运行。
# 负责管理游戏状态、玩家数据和核心流程。

extends Node

# --- 常量 ---
const CARD_DATA_PATH = "res://data/cards/numbers/"
const STARTING_HAND_SIZE = 4

# --- 预加载 ---
# 预加载卡牌视觉场景，这样在创建实例时更快。
const CardVisualScene = preload("uid://du3x8q6bpjunk")

# --- 游戏状态与数据 ---
var all_card_definitions: Array[CardData] = []

enum PlayerState {
	IDLE,           # 等待玩家操作
	CARD_SELECTED,  # 玩家已选择一张手牌，等待选择目标
}

enum GameState {
	NORMAL,
	SELECTING_CARD_FROM_HAND, # 玩家正在考虑打哪张手牌
	SELECTING_TARGET_SLOT     # 玩家已选手牌，等待选择目标卡槽
}
var current_player_id: int = 0
var current_state: GameState = GameState.NORMAL
var game_state: PlayerState = PlayerState.IDLE
var selected_card_runtime_data: CardRuntimeData = null


# 玩家数据结构。使用字典可以方便地通过玩家ID访问。
var players: Dictionary = {
	0: {
		"deck": [] as Array[CardData],             # 牌库里存放的是卡牌的定义数据
		"hand": [] as Array[CardRuntimeData],      # 手牌里存放的是卡牌的运行时实例
		"territory": [null, null, null] as Array, # 领地可以混用 CardRuntimeData 和 null，所以用普通 Array 或 Array[CardRuntimeData]
		"graveyard": [] as Array[CardRuntimeData]  # 墓地里也是运行时实例
	},
	1: {
		"deck": [] as Array[CardData],
		"hand": [] as Array[CardRuntimeData],
		"territory": [null, null, null] as Array,
		"graveyard": [] as Array[CardRuntimeData]
	}
}
# --- 信号 ---
# 当手牌UI需要更新时发出信号，由GameBoard监听并执行。
# 我们传递玩家ID，以便知道要更新哪个手牌区域。
signal hand_updated(player_id: int)
signal territory_updated(player_id: int) # 新增信号！
signal display_updated() # 一个更通用的更新信号

# =============================================================================
# Godot 生命周期函数
# =============================================================================

# 当GameManager被AutoLoad时，_ready()会首先被调用。
func _ready() -> void:
	# 1. 加载所有卡牌定义数据到内存中
	load_all_card_definitions()
	
	# 2. 游戏启动时可以立即开始，或者等待按钮触发
	#    这里我们等待一个外部调用来开始游戏，比如按钮。
	print("GameManager is ready. Waiting to start a new game.")


# =============================================================================
# 核心游戏流程
# =============================================================================

# 开始一局新游戏
func start_new_game() -> void:
	print("--- Starting New Game ---")
	
	# 1. 为每个玩家构建并洗牌他们的牌库
	for player_id in players.keys():
		build_deck_for_player(player_id)
		shuffle_deck(player_id)
	
	# 2. 为每个玩家抽取初始手牌
	for player_id in players.keys():
		draw_cards(player_id, STARTING_HAND_SIZE)
		
	print("Game setup complete. Players have drawn their starting hands.")
	current_state = GameState.NORMAL
	display_updated.emit()


# 为指定玩家抽指定数量的牌
func draw_cards(player_id: int, amount: int) -> void:
	var player_deck = players[player_id].deck
	var player_hand = players[player_id].hand

	for i in range(amount):
		# 检查牌库是否为空
		if player_deck.is_empty():
			print("Player %d's deck is empty. Cannot draw." % player_id)
			break
			
		# 从牌库顶部抽一张牌（定义数据）
		var card_def: CardData = player_deck.pop_front()
		
		# 创建这张牌的运行时实例
		var card_runtime = CardRuntimeData.new(card_def, player_id)
		
		# 将运行时实例添加到手牌数据中
		player_hand.append(card_runtime)
		
		print("Player %d drew card: %s" % [player_id, card_def.common_name])
	
	# 发出信号，通知UI层手牌数据已更新
	hand_updated.emit(player_id)


# =============================================================================
# 数据加载与处理
# =============================================================================

# 加载 res://data/cards/ 目录下的所有 .tres 卡牌资源
func load_all_card_definitions() -> void:
	all_card_definitions.clear()
	var dir = DirAccess.open(CARD_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var card_res = load(CARD_DATA_PATH + file_name)
				if card_res is CardData:
					all_card_definitions.append(card_res)
			file_name = dir.get_next()
		print("Successfully loaded %d card definitions." % all_card_definitions.size())
	else:
		print("Failed to open card data directory: " + CARD_DATA_PATH)


# 为玩家构建牌库（当前简单地复制所有卡牌）
func build_deck_for_player(player_id: int) -> void:
	# TODO: 将来这里会根据玩家的卡组配置来构建
	# 现在，我们只是简单地将所有已加载的卡牌定义复制一份作为牌库
	players[player_id].deck = all_card_definitions.duplicate(true)
	print("Built deck for Player %d with %d cards." % [player_id, players[player_id].deck.size()])


# 洗牌
func shuffle_deck(player_id: int) -> void:
	players[player_id].deck.shuffle()
	print("Player %d's deck has been shuffled." % player_id)


# =============================================================================
# 玩家交互处理 (新部分！)
# =============================================================================

# 当一张手牌被点击时，由 GameBoard 调用
func on_hand_card_selected(card_data: CardRuntimeData):
	# 检查是否是当前玩家的卡牌，并且处于空闲状态
	if card_data.owner_player_id != current_player_id or game_state != PlayerState.IDLE:
		return

	# 如果选择的是一张数字牌
	if card_data.definition.type == CardData.CardType.NUMBER:
		game_state = PlayerState.CARD_SELECTED
		selected_card_runtime_data = card_data
		print("Player selected card: %s. Waiting for territory target." % card_data.definition.common_name)
		# TODO: 通知GameBoard高亮可选目标 (空的己方领地)

	# TODO: 处理选择功能牌的逻辑

# 当一个领地卡槽被点击时，由 GameBoard 调用
func on_territory_slot_selected(player_id: int, slot_index: int):
	# 检查是否处于“已选牌”状态，并且点击的是自己的领地
	if game_state != PlayerState.CARD_SELECTED or player_id != current_player_id:
		return

	# 检查目标卡槽是否为空
	if players[player_id].territory[slot_index] == null:
		# 执行出牌逻辑！
		play_card_to_territory(selected_card_runtime_data, player_id, slot_index)
	else:
		print("Target slot is not empty. Cancelling action.")
		reset_player_state()


# 执行出牌的核心逻辑
func play_card_to_territory(card_data: CardRuntimeData, player_id: int, slot_index: int):
	print("Playing card %s to territory %d" % [card_data.definition.common_name, slot_index])

	# 1. 从手牌数据中移除
	players[player_id].hand.erase(card_data)
	
	# 2. 放置到领地数据中
	players[player_id].territory[slot_index] = card_data
	
	# 3. 重置玩家状态
	reset_player_state()

	# 4. 发出信号，通知UI更新
	hand_updated.emit(player_id)
	territory_updated.emit(player_id) # 通知领地也需要更新！

# 重置选择状态
func reset_player_state():
	game_state = PlayerState.IDLE
	selected_card_runtime_data = null
	print("Player state reset to IDLE.")
	# TODO: 通知GameBoard取消所有高亮
	
