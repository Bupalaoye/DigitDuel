extends Node2D
# 在你的 GameManager 或者 GameBoard 脚本里
@onready var hand_container: Node2D = $HandContainer

# 预加载 CardVisual 场景
const CardVisualScene = preload("uid://du3x8q6bpjunk")
func _ready():
	# 1. 加载一张卡牌的定义数据
	var kingship_data_def: CardData = load("uid://21c64ptcc80l")
	
	# 2. 创建这张卡牌的运行时实例
	var kingship_runtime_data = CardRuntimeData.new(kingship_data_def, 0) # 假设属于玩家0
	
	# 3. 创建卡牌的视觉实例
	var card_visual_instance: CardVisual = CardVisualScene.instantiate()
	
	# 4. 把视觉实例添加到场景树中
	$HandContainer.add_child(card_visual_instance) # 假设你有一个叫 HandContainer 的节点
	# 5. 调用 display 方法，将数据注入到视图中！
	card_visual_instance.display(kingship_runtime_data)

	# --- 连接信号 ---
	card_visual_instance.clicked.connect(_on_card_in_hand_clicked)

func _on_card_in_hand_clicked():
	pass
