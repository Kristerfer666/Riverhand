extends Node2D

signal podium_finished

const HAND_SCENE_PATH = "res://scenes/card.tscn"
const DECK_SCALE = Vector2(2.8, 2.8)
const HAND_COUNT = 40
const CARD_WIDTH = 125
const CARD_LENGTH = 50
const CENTER_X_POS = 250
const ACE_Y_POS = 900


var deck
var clickable
var clickable_signal = false
var center_screen_y
var center_screen_x
var initial_deal = true

var aces = ["Aces/AOS", "Aces/AOH", "Aces/AOC", "Aces/AOD"]
var player_deck = ["S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10", "H2", "H3", "H4", "H5", "H6", "H7", "H8", "H9", "H10", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "Sj", "Sq", "Sk", "Hj", "Hq", "Hk", "Cj", "Cq", "Ck", "Dj", "Dq", "Dk"]
var card_backs_list = ["Back0", "Back1", "Back2", "BackEye", "BackEyeR", "BackW"]
var card_pick
var last_card
var last_last_card

var card_back_calc = card_backs_list[0]
var back_image = str("res://materials/Card Back/" + card_back_calc + ".png")

var card_database_ref
var gamemaster_ref


func _ready() -> void:
	scale = DECK_SCALE
	$Area2D/CollisionShape2D.scale = DECK_SCALE
	initial_deal = true
	center_screen_y = get_viewport_rect().size.y / 2
	center_screen_x = get_viewport_rect().size.x / 2
	player_deck.shuffle()
	card_database_ref = preload("res://carddatabase.gd")
	card_database_ref.init_cards()
	card_database_ref.init_card_backs()
	gamemaster_ref = $"../GameMaster"
	$Sprite2D.texture = load(back_image)
	resize_to_screen()
	
func _process(delta: float) -> void:
	#draw_card()
	pass
	
func resize_to_screen():
	position.y = get_viewport_rect().size.y / 8 * 2
	position.x = get_viewport_rect().size.x / 6 * 5


func draw_card():
	if initial_deal:
		clickable = false
		initial_dealing()
	elif !initial_deal && clickable:
		var card_drawn_name = player_deck[0]
		player_deck.erase(card_drawn_name)
		if player_deck.size() == 0:
			$Area2D/CollisionShape2D.disabled = true
			$Sprite2D.visible = false
		var card_scene = preload(HAND_SCENE_PATH)
		var new_card = card_scene.instantiate()
		var card_image = str("res://materials/Card Faces/ver2/" + card_drawn_name + ".png")
		new_card.get_node("Body/AOS").texture = load(card_image)
		$"../Dealermind".add_child(new_card)
		new_card.name = "Card"
		new_card.drag = false
		new_card.face_up = true
		new_card.podium = false
		new_card.z_index = 3
		new_card.num = card_drawn_name
		new_card.position = self.position
		detect_suit(new_card)
		$"../Hand".add_card_to_hand(new_card)
		if last_last_card:
			var tween = create_tween()
			tween.tween_property(last_last_card,"modulate:a", 0.0, 0.3)
			$"../Hand".remove_card_from_hand(last_last_card)
		if last_card:
			last_card.z_index = 0
			var tween = create_tween()
			tween.tween_property(last_card,"modulate:a", 0.8, 0.3)
			$"../Hand".remove_card_from_hand(last_card)
		last_last_card = last_card
		last_card = new_card
		clickable = false
		await get_tree().create_timer(0.618).timeout
		if is_instance_valid(new_card) and new_card == last_card:
			gamemaster_ref.any_move = true
			# clickable is not re-enabled here; the ability picker confirmation
			# calls auto_draw() which sets clickable before each draw
		
		
func auto_draw() -> void:
	if not initial_deal:
		clickable = true
		draw_card()


func initial_dealing():
	for i in range(4):
		var tween = create_tween()
		var card_scene = preload(HAND_SCENE_PATH)
		var new_ace = card_scene.instantiate()
		new_ace.ace = true
		new_ace.small = true
		var x_dealing = CENTER_X_POS + (5 - (i + 1)) * (CARD_WIDTH)
		var ace_position = Vector2(x_dealing, ACE_Y_POS)
		var ace_image = str("res://materials/Card Faces/ver2/" + aces[-(i + 1)] + ".png")
		new_ace.num = aces[-(i + 1)]
		detect_suit(new_ace)
		new_ace.drag = false
		new_ace.face_up = true
		new_ace.podium = false
		initial_deal = false
		gamemaster_ref.register_initial(new_ace)
		new_ace.position = self.position
		new_ace.get_node("Body/AOS").texture = load(ace_image)
		$"../Dealermind".add_child(new_ace)
		tween.tween_property(new_ace, "position", ace_position, 0.3)
		await get_tree().create_timer(0.1).timeout
	for i in range(5):
		var card_drawn_name = player_deck[0]
		player_deck.erase(card_drawn_name)
		var card_scene = preload(HAND_SCENE_PATH)
		var new_card = card_scene.instantiate()
		new_card.small = true
		new_card.get_node("Body/AOS").texture = load(back_image)
		new_card.name = "Card"
		var new_position = Vector2(CENTER_X_POS, calculate_initial_card_position(i + 1))
		new_card.num = card_drawn_name
		detect_suit(new_card)
		new_card.drag = false
		new_card.face_up = false
		new_card.side = true
		new_card.podium = false
		new_card.side_order = i + 1
		gamemaster_ref.register_initial(new_card)
		new_card.position = self.position
		$"../Dealermind".add_child(new_card)
		animate_initial_card_tp(new_card, new_position)
		await get_tree().create_timer(0.1).timeout
	gamemaster_ref.begin_ace_selection()
	#clickable = true


func reset():
	player_deck = ["S2", "S3", "S4", "S5", "S6", "S7", "S8", "S9", "S10", "H2", "H3", "H4", "H5", "H6", "H7", "H8", "H9", "H10", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9", "C10", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "Sj", "Sq", "Sk", "Hj", "Hq", "Hk", "Cj", "Cq", "Ck", "Dj", "Dq", "Dk"]
	player_deck.shuffle()
	clickable = false
	clickable_signal = false
	initial_deal = true
	last_card = null
	last_last_card = null
	$Area2D/CollisionShape2D.disabled = false
	$Sprite2D.visible = true

func animate_initial_card_tp(card, initial_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", initial_position, 0.3)


func calculate_initial_card_position(index):
	var y_dealing = center_screen_y - 20 - (index - 3) * CARD_WIDTH
	return y_dealing

func detect_suit(card):
	if "S" in card.num:
		card.suit = 1
	elif "H" in card.num:
		card.suit = 2
	elif "C" in card.num:
		card.suit = 3
	elif "D" in card.num:
		card.suit = 4
	else:
		pass
	
func podium_display():
	gamemaster_ref.show_game_end()
	for i in range(1, 4):
		var podium_image = "res://materials/Card Faces/ver2/Aces/" + detect_chosen(i) + gamemaster_ref.podium[i - 1] + ".png"
		print(podium_image)
		podium_display_card(i, podium_image)
		await get_tree().create_timer(0.4).timeout
	emit_signal("podium_finished")
	
func detect_chosen(i):
	var texture
	if gamemaster_ref.podium[i - 1] == gamemaster_ref.player_ace:
		texture = "GoldAces/Gold"
	else:
		texture = ""
	return texture
	
func podium_display_card(index, card_image):
	var x_pos
	var card_scene = preload(HAND_SCENE_PATH)
	var new_card = card_scene.instantiate()
	new_card.get_node("Body/AOS").texture = load(card_image)
	new_card.name = "Card"
	new_card.drag = false
	new_card.face_up = true
	new_card.podium = true
	new_card.z_index = 3
	new_card.position.y = get_viewport_rect().size.y / 2
	if index == 1:
		x_pos = 0
		new_card.podium_index = 1.15
	elif index == 2:
		x_pos = -1
		new_card.podium_index = 1.05
	elif index == 3:
		x_pos = 1
		new_card.podium_index = 1.05
	new_card.position.x = get_viewport_rect().size.x / 2 + (x_pos * 300)
	$"../Dealermind".add_child(new_card)
	
