# CardUI.gd (初始版本)
extends PanelContainer

@onready var name_label = %NameLabel
@onready var value_label = %ValueLabel

signal card_clicked(card_ui_instance)

var card_data: CardData
var current_value: int # 用于追踪游戏中被改变后的值

# 用于从数据更新显示
func update_display():
	if card_data:
		name_label.text = card_data.card_name
		if card_data.card_type == CardData.CardType.NUMBER:
			value_label.text = str(current_value)
		else:
			value_label.text = "[功能]"



func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# 当卡牌被点击时，发出信号，把自己作为参数传出去
		emit_signal("card_clicked", self)
