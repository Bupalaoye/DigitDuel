# res://scripts/data/CardRuntimeData.gd
class_name CardRuntimeData
extends RefCounted # 使用 RefCounted 而不是 Object，方便内存管理

var definition: CardData # 卡牌的“出厂设置”
var current_value: int   # 场上的当前点数，会变化
var is_immune: bool = false # 是否被【壁垒】保护
var owner_player_id: int # 属于哪个玩家

# 构造函数
func _init(data: CardData, owner_id: int):
	self.definition = data
	self.owner_player_id = owner_id
	if definition.type == CardData.CardType.NUMBER:
		self.current_value = definition.base_value
	else:
		self.current_value = 0
