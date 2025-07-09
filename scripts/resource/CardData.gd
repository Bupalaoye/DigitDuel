# CardData.gd
@tool
extends Resource
class_name CardData

# 使用枚举来定义卡牌类型，这比用字符串更安全、更清晰
enum CardType { NUMBER, FUNCTION }

@export var card_name: String = "New Card"
@export var card_type: CardType = CardType.NUMBER
@export_multiline var description: String = ""

# 仅当卡牌类型为 NUMBER 时，此值有意义
@export var base_value: int = 1

# 功能牌的唯一标识符，用于代码逻辑
# 例如："kingship", "zero_out", "usurp"
@export var function_id: String = ""
