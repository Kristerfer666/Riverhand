class_name AbilityCardDatabase

# Types: "counter", "force", "boost", "conspiracy"
const CARDS: Array[Dictionary] = [
	# {
	#   "id":          unique string key used in apply_effect
	#   "type":        "counter" | "force" | "boost" | "conspiracy"
	#   "name":        display name shown on the picker button
	#   "description": flavour / rules text (shown in card art, not in UI)
	# }
	{
		"id": "transpose",
		"type": "force",
		"name": "Transpose",
		"description": "At the end of this turn, swap your ace's position with the last ace that advanced. Card images and suits swap instantly.",
	},
	{
		"id": "bite_dust",
		"type": "force",
		"name": "Bite Dust",
		"description": "All aces immediately retreat to the starting line before this turn's draw.",
	},
	{
		"id": "timeout",
		"type": "conspiracy",
		"name": "Timeout",
		"description": "Until the end of this round, no ace can move.",
	},
	{
		"id": "overextension",
		"type": "conspiracy",
		"name": "Overextension",
		"description": "Any ace that advances this turn retreats instead.",
	},
	{
		"id": "anticipate",
		"type": "boost",
		"name": "Anticipate",
		"description": "This round: when another ace advances, it stays and your ace advances instead. If your own ace is drawn, it retreats one block.",
	},
	{
		"id": "second_chance",
		"type": "boost",
		"name": "Second Chance",
		"description": "This round: after the card is drawn, draw one extra card automatically.",
	},
	{
		"id": "outsmarted",
		"type": "counter",
		"name": "Outsmarted",
		"description": "If the enemy played a boost card this turn, it is disabled and the enemy's ace retreats one block.",
	},
	{
		"id": "called_out",
		"type": "counter",
		"name": "Called Out",
		"description": "If the enemy played a conspiracy card this turn, it is disabled and the enemy's ace retreats one block.",
	},
	{
		"id": "hold_the_line",
		"type": "counter",
		"name": "Hold the Line",
		"description": "If the enemy played a force card this turn, it is disabled and the enemy's ace retreats one block.",
	},
]


static func get_random_selection(count: int) -> Array[Dictionary]:
	var pool = CARDS.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))


static func get_card_type(card_id: String) -> String:
	for card in CARDS:
		if card.get("id") == card_id:
			return card.get("type", "")
	return ""


# Returns true if the caller must await recalculate_ace_y() before auto_draw
# (used by cards whose effect needs a visual update before the next draw).
static func apply_effect(card_id: String, game_master: Node, is_player: bool = true) -> bool:
	match card_id:
		"transpose":
			if is_player:
				game_master.transpose_active = true
			else:
				game_master.cp_transpose_active = true
		"bite_dust":
			game_master.retreat_all_aces()
			return true
		"anticipate":
			if is_player:
				game_master.anticipate_active = true
			else:
				game_master.cp_anticipate_active = true
		"second_chance":
			game_master.second_chance_count += 1
		# ── Counter cards — always resolve before the enemy's card effect ────
		# apply_effect for counter cards is called first in the turn-resolution
		# order; if the enemy's pending card type matches, it is disabled.
		"outsmarted":
			var target_type = game_master.enemy_pending_card_type if is_player else game_master.player_pending_card_type
			if target_type == "boost":
				if is_player: game_master.enemy_card_disabled = true
				else: game_master.player_card_disabled = true
		"called_out":
			var target_type = game_master.enemy_pending_card_type if is_player else game_master.player_pending_card_type
			if target_type == "conspiracy":
				if is_player: game_master.enemy_card_disabled = true
				else: game_master.player_card_disabled = true
		"hold_the_line":
			var target_type = game_master.enemy_pending_card_type if is_player else game_master.player_pending_card_type
			if target_type == "force":
				if is_player: game_master.enemy_card_disabled = true
				else: game_master.player_card_disabled = true
		"timeout":
			game_master.timeout_active = true
		"overextension":
			game_master.overextension_active = true
		_:
			pass
	return false
