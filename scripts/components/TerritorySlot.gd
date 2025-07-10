# TerritorySlot.gd
class_name TerritorySlot
extends Control

# --- 信号 ---
# 当这个卡槽被点击时发出信号，并带上自己的引用。
signal selected(slot: TerritorySlot)

# --- 节点引用 ---
@onready var placeholder: Control = $Placeholder
@onready var card_container: Control = $CardContainer

# --- 状态 ---
var player_id: int
var slot_index: int
var current_card_visual: CardVisual = null

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print('pressed ')
		selected.emit(self)


func setup(_player_id : int , _slot_idx : int):
	player_id = _player_id
	slot_index = _slot_idx


# 显示一张卡牌
func set_card(card_visual: CardVisual) -> void:
	# 清理旧卡
	if is_instance_valid(current_card_visual):
		current_card_visual.queue_free()

	if is_instance_valid(card_visual):
		card_container.add_child(card_visual)
		current_card_visual = card_visual
		placeholder.hide()
	else:
		current_card_visual = null
		placeholder.show()

# 清空卡槽
func clear_card() -> void:
	set_card(null)
