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
var computer_ace: String = ""

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

# ── Active effect flags (cleared at end of each round) ──────────────────────
var timeout_active: bool = false         # no ace movement of any kind this round
var overextension_active: bool = false   # advances become retreats this round
var transpose_active: bool = false       # swap player ace with last-advanced ace at round end
var cp_transpose_active: bool = false    # same but targeting the CP's ace
var last_advanced_suit: int = 0          # suit that last advanced this round (for transpose)
var anticipate_active: bool = false      # redirect other-ace advances to player's ace this round
var cp_anticipate_active: bool = false   # same but targeting the CP's ace
var second_chance_active: bool = false   # draw an extra card this round before showing picker

# ── Enemy card tracking (set from reveal before counter resolution) ──────────
# Counter cards are resolved first; if one matches, enemy_card_disabled is set
# and the enemy card's apply_effect call is skipped when the AI system is built.
var enemy_pending_card_id: String = ""
var enemy_pending_card_type: String = ""  # "boost" | "conspiracy" | "force" | "counter" | ""
var enemy_card_disabled: bool = false     # true = a counter card cancelled the enemy's card


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
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


func _process(_delta: float) -> void:
	pass


func register_initial(card):
	all_initial.append(card)


func full_reset():
	game_generation += 1
	AOS_pos = 0
	AOH_pos = 0
	AOC_pos = 0
	AOD_pos = 0
	podium.clear()
	all_initial.clear()
	player_ace = null
	computer_ace = ""
	any_move = null
	degrade_suit = null
	transition_started = false
	chosing_ace = false
	picker_triggered_this_cycle = false
	timeout_active = false
	overextension_active = false
	transpose_active = false
	cp_transpose_active = false
	last_advanced_suit = 0
	anticipate_active = false
	cp_anticipate_active = false
	second_chance_active = false
	enemy_pending_card_id = ""
	enemy_pending_card_type = ""
	enemy_card_disabled = false
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
		gm_child.computer_ace = ""
		gm_child.any_move = null
		gm_child.degrade_suit = null
		gm_child.transition_started = false
		gm_child.chosing_ace = false
		gm_child.picker_triggered_this_cycle = false
		gm_child.timeout_active = false
		gm_child.overextension_active = false
		gm_child.transpose_active = false
		gm_child.cp_transpose_active = false
		gm_child.last_advanced_suit = 0
		gm_child.anticipate_active = false
		gm_child.cp_anticipate_active = false
		gm_child.second_chance_active = false
		gm_child.enemy_pending_card_id = ""
		gm_child.enemy_pending_card_type = ""
		gm_child.enemy_card_disabled = false
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


# ── Internal ace-position primitives (no effect checks) ─────────────────────
# These are the only places that read/write ace positions and the podium list.
# All higher-level code must go through the public API below.

func _suit_to_ace_name(suit: int) -> String:
	match suit:
		1: return "AOS"
		2: return "AOH"
		3: return "AOC"
		4: return "AOD"
	return ""

func _ace_name_to_suit(ace_name: String) -> int:
	match ace_name:
		"AOS": return 1
		"AOH": return 2
		"AOC": return 3
		"AOD": return 4
	return 0

func _get_ace_pos(suit: int) -> int:
	match suit:
		1: return AOS_pos
		2: return AOH_pos
		3: return AOC_pos
		4: return AOD_pos
	return 0

func _set_ace_pos(suit: int, val: int) -> void:
	match suit:
		1: AOS_pos = val
		2: AOH_pos = val
		3: AOC_pos = val
		4: AOD_pos = val

func _advance_ace_pos(suit: int) -> bool:
	var pos = _get_ace_pos(suit)
	if pos >= 6:
		return false
	_set_ace_pos(suit, pos + 1)
	var ace_name = _suit_to_ace_name(suit)
	if _get_ace_pos(suit) == 6 and ace_name not in podium:
		podium.append(ace_name)
	return true

func _retreat_ace_pos(suit: int) -> void:
	var pos = _get_ace_pos(suit)
	if pos <= 0:
		return
	_set_ace_pos(suit, pos - 1)
	var ace_name = _suit_to_ace_name(suit)
	if podium.has(ace_name):
		podium.erase(ace_name)


# ── Public effect-aware ace movement API ─────────────────────────────────────
# All card abilities and game logic that moves aces must call these, never the
# primitives directly. This ensures active effects (timeout, overextension,
# future cards) are always respected.

# Returns "advanced", "retreated", "redirected", "cp_retreated", "cp_redirected",
# "stayed", or "maxed".
# Timeout is handled upstream in move_ace before this is ever called.
func advance_ace(suit: int) -> String:
	if overextension_active:
		_retreat_ace_pos(suit)
		return "retreated"
	var player_suit := _ace_name_to_suit(player_ace) if player_ace != null else 0
	var cp_suit    := _ace_name_to_suit(computer_ace) if computer_ace != "" else 0
	# Own-ace retreat rules take priority over redirects.
	if anticipate_active and suit == player_suit:
		_retreat_ace_pos(player_suit)
		return "retreated"
	if cp_anticipate_active and suit == cp_suit:
		_retreat_ace_pos(cp_suit)
		return "cp_retreated"
	# Redirect: player's anticipate fires first if both are active.
	if anticipate_active:
		if not _advance_ace_pos(player_suit):
			return "stayed"
		return "redirected"
	if cp_anticipate_active:
		if not _advance_ace_pos(cp_suit):
			return "stayed"
		return "cp_redirected"
	if not _advance_ace_pos(suit):
		return "maxed"
	return "advanced"

# Retreats one ace by one step. Respects timeout (no-op when active).
func retreat_ace(suit: int) -> void:
	if timeout_active:
		return
	_retreat_ace_pos(suit)

# Retreats all aces to position 0. Bypasses effect flags (used by Bite Dust
# which fires before the draw, outside any round-effect window).
func retreat_all_aces() -> void:
	for suit in [1, 2, 3, 4]:
		_set_ace_pos(suit, 0)
	podium.clear()

# Instantly swaps two aces' positions AND their visual identities (texture,
# suit, num) so neither node moves on screen. Allowed even during timeout.
func _do_instant_transpose(suit_a: int, suit_b: int) -> void:
	var pos_a = _get_ace_pos(suit_a)
	var pos_b = _get_ace_pos(suit_b)
	_set_ace_pos(suit_a, pos_b)
	_set_ace_pos(suit_b, pos_a)
	for suit in [suit_a, suit_b]:
		var name = _suit_to_ace_name(suit)
		if _get_ace_pos(suit) == 6 and name not in podium:
			podium.append(name)
		elif _get_ace_pos(suit) < 6 and podium.has(name):
			podium.erase(name)
	var node_a: Node = null
	var node_b: Node = null
	for card in all_initial:
		if not is_instance_valid(card) or not card.ace:
			continue
		if card.suit == suit_a:
			node_a = card
		elif card.suit == suit_b:
			node_b = card
	if node_a == null or node_b == null:
		return
	node_a.suit = suit_b
	node_b.suit = suit_a
	var tex = node_a.get_node("Body/AOS").texture
	node_a.get_node("Body/AOS").texture = node_b.get_node("Body/AOS").texture
	node_b.get_node("Body/AOS").texture = tex
	var num = node_a.num
	node_a.num = node_b.num
	node_b.num = num
	# Re-apply visual ownership markers after the swap.
	# Modulates don't follow the suit/texture swap automatically.
	for swapped in [node_a, node_b]:
		var ace_name = _suit_to_ace_name(swapped.suit)
		if ace_name == player_ace:
			swapped.modulate = Color.WHITE
		elif ace_name == computer_ace:
			swapped.modulate = Color(0.7, 0.85, 1.0)
		else:
			swapped.modulate = Color.WHITE

# Swaps the positions of two aces. Allowed even during timeout.
func swap_aces(suit_a: int, suit_b: int) -> void:
	var pos_a = _get_ace_pos(suit_a)
	var pos_b = _get_ace_pos(suit_b)
	_set_ace_pos(suit_a, pos_b)
	_set_ace_pos(suit_b, pos_a)
	for suit in [suit_a, suit_b]:
		var name = _suit_to_ace_name(suit)
		if _get_ace_pos(suit) == 6 and name not in podium:
			podium.append(name)
		elif _get_ace_pos(suit) < 6 and podium.has(name):
			podium.erase(name)


# ── Core game flow ───────────────────────────────────────────────────────────

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
	if not timeout_active:
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
		# Second Chance: trigger extra draw before the picker shows.
		# Other round-scoped flags stay active for the second draw.
		if second_chance_active:
			second_chance_active = false
			deck_ref.auto_draw()
			return
		# Round truly ends here — apply end-of-round effects, clear all flags.
		if transpose_active and last_advanced_suit != 0:
			var player_suit = _ace_name_to_suit(player_ace)
			if player_suit != last_advanced_suit:
				_do_instant_transpose(player_suit, last_advanced_suit)
		if cp_transpose_active and last_advanced_suit != 0:
			var cp_suit = _ace_name_to_suit(computer_ace)
			if cp_suit != last_advanced_suit:
				_do_instant_transpose(cp_suit, last_advanced_suit)
		timeout_active = false
		overextension_active = false
		transpose_active = false
		cp_transpose_active = false
		anticipate_active = false
		cp_anticipate_active = false
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
	if timeout_active:
		# Nothing moves this round — skip directly to end-of-round.
		await _end_round()
		return
	var result = advance_ace(card.suit)
	match result:
		"maxed":
			any_move = false
			await get_tree().create_timer(1.0).timeout
			deck_ref.auto_draw()
			return
		"advanced":
			last_advanced_suit = card.suit
			await recalculate_ace_y()
			await degrade_ace()
		"retreated":
			await recalculate_ace_y()
			await degrade_ace()
		"redirected":
			last_advanced_suit = _ace_name_to_suit(player_ace)
			await recalculate_ace_y()
			await degrade_ace()
		"cp_retreated":
			await recalculate_ace_y()
			await degrade_ace()
		"cp_redirected":
			last_advanced_suit = _ace_name_to_suit(computer_ace)
			await recalculate_ace_y()
			await degrade_ace()
		"stayed":
			await get_tree().create_timer(0.3).timeout
			await degrade_ace()


# Explicitly ends the current round: clears flags, then either starts the
# win transition (if 3 aces are on the podium) or shows the picker.
# Used when no ace movement occurred (timeout) so the normal degrade→picker
# chain would never fire on its own.
func _end_round() -> void:
	var gen = game_generation
	timeout_active = false
	overextension_active = false
	if podium.size() == 3 and not transition_started:
		transition_started = true
		deck_ref.clickable_signal = true
		deck_ref.clickable = false
		await get_tree().create_timer(1).timeout
		if game_generation != gen:
			return
		transition_ref.transition_signal()
		return
	if not picker_triggered_this_cycle and not transition_started:
		if transpose_active and last_advanced_suit != 0:
			var player_suit = _ace_name_to_suit(player_ace)
			if player_suit != last_advanced_suit:
				_do_instant_transpose(player_suit, last_advanced_suit)
		if cp_transpose_active and last_advanced_suit != 0:
			var cp_suit = _ace_name_to_suit(computer_ace)
			if cp_suit != last_advanced_suit:
				_do_instant_transpose(cp_suit, last_advanced_suit)
		timeout_active = false
		overextension_active = false
		transpose_active = false
		cp_transpose_active = false
		anticipate_active = false
		cp_anticipate_active = false
		await get_tree().create_timer(0.3).timeout
		if game_generation != gen:
			return
		picker_triggered_this_cycle = true
		ability_picker_ref.show_picker()


func calc_degrade(suit_num: int) -> void:
	retreat_ace(suit_num)


# ── UI / Events ──────────────────────────────────────────────────────────────

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
	_select_computer_ace()
	ability_picker_ref.show_picker()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(pick_ace_label_ref, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): pick_ace_label_ref.visible = false)


func _select_computer_ace() -> void:
	var all_aces := ["AOS", "AOH", "AOC", "AOD"]
	all_aces.erase(player_ace)
	all_aces.shuffle()
	computer_ace = all_aces[0]
	for card in all_initial:
		if not is_instance_valid(card) or not card.ace:
			continue
		if _suit_to_ace_name(card.suit) == computer_ace:
			card.modulate = Color(0.7, 0.85, 1.0)
			break


func _on_ability_card_confirmed(player_card_id: String, computer_card_id: String) -> void:
	# Register enemy card so counter cards can check the type.
	enemy_pending_card_id = computer_card_id
	enemy_pending_card_type = AbilityCardDatabase.get_card_type(computer_card_id)
	enemy_card_disabled = false
	# Player's card applies first (counter cards check enemy type here).
	var needs_visual_update = AbilityCardDatabase.apply_effect(player_card_id, self, true)
	if needs_visual_update:
		await recalculate_ace_y()
	# If a counter card successfully fired, retreat the CP's ace one block.
	if enemy_card_disabled and computer_ace != "":
		_retreat_ace_pos(_ace_name_to_suit(computer_ace))
		await recalculate_ace_y()
	# Computer's card applies second, unless a counter card disabled it.
	if not enemy_card_disabled and computer_card_id != "":
		var cp_needs_update = AbilityCardDatabase.apply_effect(computer_card_id, self, false)
		if cp_needs_update:
			await recalculate_ace_y()
	deck_ref.auto_draw()


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
