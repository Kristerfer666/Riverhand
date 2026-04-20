extends Node2D


signal left_mouse_button_clicked
signal left_mouse_button_released


const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4


var dealermind_ref
var deck_ref
var hand_ref
var gamemaster_ref

var ace_chosen

func _ready() -> void:
	dealermind_ref = $"../Dealermind"
	deck_ref = $"../Deck"
	hand_ref = $"../Hand"
	gamemaster_ref = $"../GameMaster"
	ace_chosen = false


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			raycast_at_cursor("card")
		else:
			emit_signal("left_mouse_button_released")
			raycast_at_cursor("deck")


func reset():
	ace_chosen = false

func raycast_at_cursor(object):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD | COLLISION_MASK_DECK
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD && object == "card":
			var card_found = result[0].collider.get_parent()
			if card_found && card_found.ace && !ace_chosen:
				ace_chosen = true
				gamemaster_ref.select_ace(card_found)
			#elif card_found && !card_found.drag:
				#dealermind_ref.flip_card(card_found)
