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
		"description": "At the end of this turn, swap your ace's position with the last ace that advanced.",
	},
	{
		"id": "bite_dust",
		"type": "force",
		"name": "Bite Dust",
		"description": "All aces retreat to the starting line.",
	},
	{
		"id": "timeout",
		"type": "conspiracy",
		"name": "Timeout",
		"description": "Until the end of this turn, no ace can move.",
	},
	{
		"id": "overextension",
		"type": "conspiracy",
		"name": "Overextension",
		"description": "Any ace that advances this turn retreat 1 instead.",
	},
	{
		"id": "anticipate",
		"type": "boost",
		"name": "Anticipate",
		"description": "When an ace advances, it stays and your ace advances instead. If it was yours, it retreats 1 instead.",
	},
	{
		"id": "second_chance",
		"type": "boost",
		"name": "Second Chance",
		"description": "This turn, after an card is drawn, draw one extra card.",
	},
	{
		"id": "outsmarted",
		"type": "counter",
		"name": "Outsmarted",
		"description": "If the enemy played a boost card this turn, it is disabled and the enemy's ace retreats 1.",
	},
	{
		"id": "called_out",
		"type": "counter",
		"name": "Called Out",
		"description": "If the enemy played a conspiracy card this turn, it is disabled and the enemy's ace retreats 1.",
	},
	{
		"id": "hold_the_line",
		"type": "counter",
		"name": "Hold the Line",
		"description": "If the enemy played a force card this turn, it is disabled and the enemy's ace retreats 1.",
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
		"outsmarted", "called_out", "hold_the_line":
			const _COUNTER_BLOCKS := {"outsmarted": "boost", "called_out": "conspiracy", "hold_the_line": "force"}
			var opponent_type: String = game_master.enemy_pending_card_type if is_player else game_master.player_pending_card_type
			if opponent_type == _COUNTER_BLOCKS[card_id]:
				if is_player: game_master.enemy_card_disabled = true
				else: game_master.player_card_disabled = true
		"timeout":
			game_master.timeout_active = true
		"overextension":
			game_master.overextension_active = true
		_:
			pass
	return false
