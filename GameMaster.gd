extends Node2D

const ACE_Y_POS = 875
const CARD_WIDTH = 120

var AOS_pos
var AOH_pos
var AOC_pos
var AOD_pos

var all_initial: Array = []

var deck_ref
var card_ref

var degrade_suit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deck_ref = get_node("/root/Main/Deck")
	card_ref = $"../card"
	for v in ["AOS_pos", "AOH_pos", "AOC_pos", "AOD_pos"]:
		set(v, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_initial(card):
	all_initial.append(card)


func recalculate_ace_y():
	var AOS_y = ACE_Y_POS - AOS_pos * CARD_WIDTH
	var AOH_y = ACE_Y_POS - AOH_pos * CARD_WIDTH
	var AOC_y = ACE_Y_POS - AOC_pos * CARD_WIDTH
	var AOD_y = ACE_Y_POS - AOD_pos * CARD_WIDTH
	for card in all_initial:
		if card.ace:  # only move aces
			var target_y = 0
			match card.suit:
				1: target_y = AOS_y
				2: target_y = AOH_y
				3: target_y = AOC_y
				4: target_y = AOD_y
			var target_pos = Vector2(card.position.x, target_y)
			await get_tree().create_timer(0.1).timeout
			card.move_ace(target_pos)

func degrade_ace():
	for order in range(1, 6): 
		if AOS_pos > order and AOH_pos > order and AOC_pos > order and AOD_pos > order:
			for side in all_initial:
				if side.side_order == order and !side.face_up:
					flip_card(side)
					await get_tree().create_timer(0.6).timeout
					calc_degrade(degrade_suit)
					recalculate_ace_y()

func flip_card(card):
	if !card.face_up:
		card.face_up = true
		card.get_node("AOS")
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($AOS, "scale", 0.0, 0.3)
		var card_image = str("res://materials/Card Faces/ver2/" + card.num + ".png")
		tween.tween_callback(func():
			card.get_node("AOS").texture = load(card_image)
		)
		tween.tween_interval(0.1)
		tween.tween_property($AOS, "scale", 1.0, 0.3)
		degrade_suit = card.suit

func calc_degrade(suit_num):
	if suit_num == 1:
		if game_master.AOS_pos > 0:
			game_master.AOS_pos -= 1
	elif suit_num == 2:
		if game_master.AOH_pos > 0:
			game_master.AOH_pos -= 1
	elif suit_num == 3:
		if game_master.AOC_pos > 0:
			game_master.AOC_pos -= 1
	elif suit_num == 4:
		if game_master.AOD_pos > 0:
			game_master.AOD_pos -= 1
	else:
		pass
