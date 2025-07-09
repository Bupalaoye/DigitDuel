# CardData.gd
# 这是一个资源(Resource)脚本，作为所有卡牌的数据模板。
# 它是“数据驱动”设计的核心，定义了一张卡牌的“出厂设置”。
# @tool 注解让此脚本可以在Godot编辑器中运行，从而实现动态的检查器界面。

@tool
class_name CardData
extends Resource


# =============================================================================
# 1. 枚举定义 (Enums for Type Safety)
# =============================================================================
# 使用枚举来定义卡牌类型，避免使用易出错的字符串或"魔法数字"。

# 卡牌的大分类：数字牌 或 功能牌
enum CardType { 
	NUMBER, 
	FUNCTION 
}

# 所有功能牌的具体效果类型。
# 当你添加新功能牌时，只需在这里加一个新枚举值。
enum FunctionEffect { 
	# GDD中定义的基础效果
	KINGSHIP,     # 王权 (翻倍)
	ZERO_OUT,     # 归零
	USURP,        # 篡夺
	BARRIER,      # 壁垒
	DIVIDE,       # 分裂
	TAX,          # 税收
	# 为未来扩展预留
	# NEW_EFFECT_A,
	# NEW_EFFECT_B,
}


# =============================================================================
# 2. 导出变量 (Exported Variables - The Data Fields)
# =============================================================================
# 这些是会在Godot编辑器的“检查器”中显示的字段，供策划或你来填写。

# --- 核心分类 ---
# 这个变量决定了这张卡是数字牌还是功能牌。
# 我们添加了一个setter函数，当这个值在编辑器中改变时，它会通知编辑器刷新界面。
@export var type: CardType = CardType.NUMBER:
	set(value):
		type = value
		if Engine.is_editor_hint():
			notify_property_list_changed()

# --- 通用属性 (所有卡牌都有) ---
@export_group("common_prop", "common_")
# 唯一的、程序使用的ID，遵循命名规范（如: func_base_kingship）
@export var common_id: String = "new_card_id"
# 游戏中显示的卡牌名称，支持本地化
@export var common_name: String = "新卡牌"
# 游戏中的效果描述文字
@export_multiline var common_description: String = "卡牌效果描述..."
# 卡牌的美术图
@export var common_artwork: Texture2D


# --- 特定属性 (根据类型显示) ---
# 这些变量我们先声明，但它们的显示将由下面的 _get_property_list 函数动态控制。
@export_group("spec value")
var base_value: int = 1
var effect: FunctionEffect = FunctionEffect.KINGSHIP


# =============================================================================
# 3. 编辑器增强 (@tool 模式核心)
# =============================================================================
# 这个函数是 @tool 脚本的精髓。它告诉Godot编辑器如何动态地绘制检查器。

func _get_property_list() -> Array:
	# 我们将手动构建一个属性列表数组
	var properties: Array = []
	
	# 根据当前选择的 `type`，决定要将哪些“特定属性”添加到检查器中。
	if type == CardType.NUMBER:
		properties.append({
			"name": "base_value",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_DEFAULT, # 标准可读写属性
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "1,9,1" # 限制范围为1-9，步长为1
		})
		
	elif type == CardType.FUNCTION:
		properties.append({
			"name": "effect",
			"type": TYPE_INT, # 枚举在底层是整数
			"usage": PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM, # 告诉编辑器这是一个枚举下拉菜单
			# 将 FunctionEffect 枚举的所有项作为字符串提供给下拉菜单
			"hint_string": ",".join(FunctionEffect.keys())
		})
	
	return properties
