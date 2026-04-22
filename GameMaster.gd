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
var pick_ace_label_ref
var game_end_label_ref

var any_move
var degrade_suit
var transition_started = false
var chosing_ace = false
var game_generation = 0

var ability_picker_ref
var picker_triggered_this_cycle = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#for i in 3:
		#podium.append("a")
	deck_ref = get_node("/root/Main/Deck")
	transition_ref = get_node("/root/Main/PodiumTransition")
	card_ref = $"../card"
	hand_ref = get_node("/root/Main/Hand")
	restart_btn_ref = get_node("/root/Main/CanvasLayer/Control")
	pick_ace_label_ref = get_node("/root/Main/CanvasLayer/PickAceLabel")
	game_end_label_ref = get_node("/root/Main/CanvasLayer/GameEndLabel")
	for v in ["AOS_pos", "AOH_pos", "AOC_pos", "AOD_pos"]:
		set(v, 0)
	deck_ref.podium_finished.connect(_on_podium_finished)
	var picker_scene = preload("res://scenes/ability_card_picker.tscn")
	ability_picker_ref = picker_scene.instantiate()
	get_node("/root/Main/CanvasLayer").add_child(ability_picker_ref)
	ability_picker_ref.card_confirmed.connect(_on_ability_card_confirmed)
	transition_started = false
	restart_btn_ref.hide()
	await transition_ref.enter_transition_signal()
	deck_ref.draw_card()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_initial(card):
	all_initial.append(card)

func recalculate_ace_y():
	var gen = game_generation
	var AOS_y = ACE_Y_POS - AOS_pos * CARD_WIDTH
	var AOH_y = ACE_Y_POS - AOH_pos * CARD_WIDTH
	var AOC_y = ACE_Y_POS - AOC_pos * CARD_WIDTH
	var AOD_y = ACE_Y_POS - AOD_pos * CARD_WIDTH
	for card in all_initial:
		if not is_instance_valid(card) or not card.ace:
			continue
		var target_y = 0
		match card.suit:
			1: target_y = AOS_y
			2: target_y = AOH_y
			3: target_y = AOC_y
			4: target_y = AOD_y
		var target_pos = Vector2(card.position.x, target_y)
		await get_tree().create_timer(0.1).timeout
		if game_generation != gen or not is_instance_valid(card):
			return
		await card.move_ace(target_pos)
		if game_generation != gen:
			return
	await get_tree().create_timer(0.2).timeout
	if game_generation != gen:
		return

func degrade_ace():
	var gen = game_generation
	for order in range(1, 6):
		if AOS_pos > order and AOH_pos > order and AOC_pos > order and AOD_pos > order:
			for side in all_initial:
				if not is_instance_valid(side):
					continue
				if side.side_order == order and !side.face_up:
					flip_card(side)
					await get_tree().create_timer(0.7).timeout
					if game_generation != gen:
						return
					calc_degrade(degrade_suit)
					await recalculate_ace_y()
					if game_generation != gen:
						return
					await degrade_ace()
					return
		else:
			continue
	if game_generation != gen:
		return
	if podium.size() == 3 && !transition_started:
		transition_started = true
		deck_ref.clickable_signal = true
		deck_ref.clickable = false
		await get_tree().create_timer(1).timeout
		if game_generation != gen:
			return
		transition_ref.transition_signal()
	if not picker_triggered_this_cycle and not transition_started:
		picker_triggered_this_cycle = true
		ability_picker_ref.show_picker()

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
	picker_triggered_this_cycle = false
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
				await get_tree().create_timer(1.0).timeout
				deck_ref.auto_draw()
				return
		2:
			ace_name = "AOH"
			if AOH_pos < 6:
				AOH_pos += 1
				if AOH_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
				await get_tree().create_timer(1.0).timeout
				deck_ref.auto_draw()
				return
		3:
			ace_name = "AOC"
			if AOC_pos < 6:
				AOC_pos += 1
				if AOC_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
				await get_tree().create_timer(1.0).timeout
				deck_ref.auto_draw()
				return
		4:
			ace_name = "AOD"
			if AOD_pos < 6:
				AOD_pos += 1
				if AOD_pos == 6 && ace_name not in podium:
					podium.append(ace_name)
			else:
				any_move = false
				await get_tree().create_timer(1.0).timeout
				deck_ref.auto_draw()
				return
		_:
			return
	# 统一处理 podium（适用于所有花色）
	#if podium.has(ace_name):
		#podium.erase(ace_name)
	#podium.insert(0, ace_name)
	#print(podium)
	await recalculate_ace_y()
	await degrade_ace()
	

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
	await transition_ref.final_transition_signal().finished
	full_reset()
	await transition_ref.enter_transition_signal()
	deck_ref.draw_card()

func full_reset():
	game_generation += 1
	AOS_pos = 0
	AOH_pos = 0
	AOC_pos = 0
	AOD_pos = 0
	podium.clear()
	all_initial.clear()
	player_ace = null
	any_move = null
	degrade_suit = null
	transition_started = false
	chosing_ace = false
	picker_triggered_this_cycle = false
	# Reset the GameMaster child node, which holds the actual game state used by deck/hand.
	var gm_child = get_node_or_null("GameMaster")
	if gm_child:
		gm_child.game_generation = game_generation
		gm_child.AOS_pos = 0
		gm_child.AOH_pos = 0
		gm_child.AOC_pos = 0
		gm_child.AOD_pos = 0
		gm_child.podium.clear()
		gm_child.all_initial.clear()
		gm_child.player_ace = null
		gm_child.any_move = null
		gm_child.degrade_suit = null
		gm_child.transition_started = false
		gm_child.chosing_ace = false
		gm_child.picker_triggered_this_cycle = false
	ability_picker_ref.reset()
	restart_btn_ref.get_node("Label").modulate.a = 1.0
	restart_btn_ref.hide()
	pick_ace_label_ref.visible = false
	game_end_label_ref.visible = false
	hand_ref.reset()
	get_node("/root/Main/Dealermind").reset()
	transition_ref.reset()
	get_node("/root/Main/Inputmind").reset()
	deck_ref.reset()

func show_game_end():
	game_end_label_ref.modulate.a = 0.0
	game_end_label_ref.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_end_label_ref, "modulate:a", 1.0, 0.5)

func begin_ace_selection():
	chosing_ace = true
	pick_ace_label_ref.modulate.a = 0.0
	pick_ace_label_ref.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(pick_ace_label_ref, "modulate:a", 1.0, 0.5)

func select_ace(ace):
	player_ace = "AO" + ace.suit_to_letter()
	ace.anim_gold()
	chosing_ace = false
	ability_picker_ref.show_picker()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pick_ace_label_ref, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): pick_ace_label_ref.visible = false)
	
func _on_ability_card_confirmed(card_index: int) -> void:
	deck_ref.auto_draw()

#func start_transition():
	#var transition_scene = preload("res://scenes/transition_(control).tscn")
	#var transition = transition_scene.instantiate()
#
	#get_tree().root.add_child(transition) # 加到最顶层
#
	#await transition.finished  # 等动画播放完
#
	#get_tree().change_scene_to_file("res://NextScene.tscn")
