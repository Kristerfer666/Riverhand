extends Node2D
#
#
#const HAND_COUNT = 40
#const CARD_WIDTH = 60
#const CENTER_X_POS = 250
#
#var deck
#var center_screen_y
#
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#deck = $"../Deck"
	#center_screen_y = get_viewport().size.y / 2
	#
	#for i in range(4):
		#var new_position = Vector2(calculate_initial_card_position(i + 1), CENTER_X_POS)
		#var card = deck.player_deck[i]
		#animate_card_tp(card, new_position)
#
#
#func animate_card_tp(card, new_position):
	#var tween = get_tree().create_tween()
	#tween.tween_property(card, "position", new_position, 0.3)
#
#
#func calculate_initial_card_position(index):
	#var y_dealing = center_screen_y + (index - 3) * -(CARD_WIDTH + 50)
	#return y_dealing
