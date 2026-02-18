extends Node2D


const HAND_COUNT = 40
const CARD_WIDTH = 60
const HAND_Y_POS = 260


var player_hand = []
var drawn_cards = []
var center_screen_x
var game_master_ref


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = (get_viewport().size.x / 5) * 3
	game_master_ref = $"../GameMaster"
	


func add_card_to_hand(card):
	if card not in player_hand:
		player_hand.insert(0, card)
		drawn_cards.insert(0, card)
		update_hand_position()
		await get_tree().create_timer(0.2).timeout
		move_ace(card)
	else:
		animate_card_tp(card, card.inhand_position)


func move_ace(card):
	if card.suit == 1:
		if game_master.AOS_pos < 6:
			game_master.AOS_pos += 1
	elif card.suit == 2:
		if game_master.AOH_pos < 6:
			game_master.AOH_pos += 1
	elif card.suit == 3:
		if game_master.AOC_pos < 6:
			game_master.AOC_pos += 1
	elif card.suit == 4:
		if game_master.AOD_pos < 6:
			game_master.AOD_pos += 1
	else:
		pass
	game_master.recalculate_ace_y()


func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(-i), get_viewport().size.y / 8 * 2
		)
		var card = player_hand[i]
		card.inhand_position = new_position
		card.z_index = 2
		animate_card_tp(card, new_position)


func animate_card_tp(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.3)


func calculate_card_position(index):
	var total_width = (player_hand.size() -1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH + total_width / 2
	return x_offset

 
func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_position()
