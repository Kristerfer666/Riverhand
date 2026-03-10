extends Node2D

const ACE_Y_POS = 900
const CARD_WIDTH = 120

var AOS_pos
var AOH_pos
var AOC_pos
var AOD_pos

#var podium = ["AOD", "AOS", "AOC"]
var podium = []
var all_initial: Array = []

var player_ace

var deck_ref
var transition_ref
var card_ref
var hand_ref
var restart_btn_ref

var any_move
var degrade_suit
var transition_started = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for i in 3:
		#podium.append("a")
	deck_ref = get_node("/root/Main/Deck")
	transition_ref = get_node("/root/Main/PodiumTransition")
	card_ref = $"../card"
	hand_ref = get_node("/root/Main/Hand")
	restart_btn_ref = get_node("/root/Main/CanvasLayer/Control/CenterContainer/Button")
	for v in ["AOS_pos", "AOH_pos", "AOC_pos", "AOD_pos"]:
		set(v, 0)
	deck_ref.podium_finished.connect(_on_podium_finished)
	transition_started = false
	restart_btn_ref.hide()


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
			await card.move_ace(target_pos)
			degrade_ace()

func degrade_ace():
	for order in range(1, 6): 
		if AOS_pos > order and AOH_pos > order and AOC_pos > order and AOD_pos > order:
			for side in all_initial:
				if side.side_order == order and !side.face_up:
					flip_card(side)
					await get_tree().create_timer(0.6).timeout
					calc_degrade(degrade_suit)
					recalculate_ace_y()
		else:
			continue
	if podium.size() == 3 && !transition_started:
		transition_started = true
		deck_ref.clickable_signal = true
		deck_ref.clickable = false
		await get_tree().create_timer(1).timeout
		transition_ref.transition_signal()

func flip_card(card):
	if !card.face_up:
		card.face_up = true
		card.get_node("AOS")
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property($Body/AOS, "scale", 0.0, 0.3)
		var card_image = str("res://materials/Card Faces/ver2/" + card.num + ".png")
		tween.tween_callback(func():
			card.get_node("Body/AOS").texture = load(card_image)
		)
		tween.tween_interval(0.1)
		tween.tween_property($Body/AOS, "scale", 1.0, 0.3)
		degrade_suit = card.suit

func move_ace(card):
	var ace_name = ""
	match card.suit:
		1:
			ace_name = "AOS"
			if AOS_pos < 6:
				AOS_pos += 1
				if AOS_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
				
		2:
			ace_name = "AOH"
			if AOH_pos < 6:
				AOH_pos += 1
				if AOH_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
		3:
			ace_name = "AOC"
			if AOC_pos < 6:
				AOC_pos += 1
				if AOC_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
		4:
			ace_name = "AOD"
			if AOD_pos < 6:
				AOD_pos += 1
				if AOD_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
		_:
			return
	# 统一处理 podium（适用于所有花色）
	#if podium.has(ace_name):
		#podium.erase(ace_name)
	#podium.insert(0, ace_name)
	#print(podium)
	recalculate_ace_y()
	

func calc_degrade(suit_num):
	if suit_num == 1:
		if AOS_pos > 0:
			AOS_pos -= 1
			if podium.has("AOS"):
				podium.erase("AOS")
	elif suit_num == 2:
		if AOH_pos > 0:
			AOH_pos -= 1
			if podium.has("AOH"):
				podium.erase("AOH")
	elif suit_num == 3:
		if AOC_pos > 0:
			AOC_pos -= 1
			if podium.has("AOC"):
				podium.erase("AOC")
	elif suit_num == 4:
		if AOD_pos > 0:
			AOD_pos -= 1
			if podium.has("AOD"):
				podium.erase("AOD")
	else:
		pass

func _on_podium_finished():
	restart_btn_ref.modulate.a = 0
	restart_btn_ref.show()
	
	var tween = create_tween()
	tween.tween_property(restart_btn_ref, "modulate:a", 1.0, 0.5)

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()

func select_ace(ace):
	player_ace = ace
	ace.anim_gold()
	deck_ref.clickable = true
	
#func start_transition():
	#var transition_scene = preload("res://scenes/transition_(control).tscn")
	#var transition = transition_scene.instantiate()
#
	#get_tree().root.add_child(transition) # 加到最顶层
#
	#await transition.finished  # 等动画播放完
#
	#get_tree().change_scene_to_file("res://NextScene.tscn")
