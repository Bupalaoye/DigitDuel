# res://scripts/managers/EffectManager.gd
# 设为 AutoLoad 单例
extends Node

# 主入口函数
func execute_effect(card_data: CardData, source_player_id: int, targets: Array[CardRuntimeData]):
	# 使用 match 语句，将卡牌效果的定义 (enum) 映射到具体的执行函数
	# 这是整个框架扩展性的核心！
	match card_data.effect:
		CardData.FunctionEffect.KINGSHIP:
			_execute_kingship(targets[0])
		CardData.FunctionEffect.ZERO_OUT:
			_execute_zero_out(targets[0])
		CardData.FunctionEffect.USURP:
			# 篡夺需要两个目标：自己的牌和对方的牌
			# 这个需要在调用前由GameManager准备好
			_execute_usurp(targets[0], targets[1]) 
		# ... 其他效果 ...

# --- 私有的具体效果实现 ---

func _execute_kingship(target: CardRuntimeData):
	if not target or target.is_immune:
		return
	# 核心逻辑
	target.current_value *= 2
	# TODO: 发出信号或调用UI函数，让卡牌播放一个“翻倍”的动画
	print("卡牌 %s 的点数翻倍为 %d" % [target.definition.card_name, target.current_value])

func _execute_zero_out(target: CardRuntimeData):
	if not target or target.is_immune:
		return
	target.current_value = 0
	print("卡牌 %s 的点数被归零" % target.definition.card_name)

func _execute_usurp(my_card: CardRuntimeData, opponent_card: CardRuntimeData):
	# 这个逻辑比较复杂，需要由GameManager来处理
	# EffectManager只负责发出请求，GameManager来修改领地数据结构
	# 或者，将GameManager的引用传进来
	pass 
