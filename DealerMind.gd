extends Node2D

# =====================
# VARIABLES
# =====================

const CARD_SCALE = 2.8
const ACE_SCALE = 2.6

var screen_size: Vector2
var dragged_card = null
var is_hovering = false
var player_hand

# =====================
# READY
# =====================
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand = $"../Hand"
	$"../Inputmind".left_mouse_button_released.connect(_on_mouse_released)

# =====================
# PROCESS (DRAG ONLY)
# =====================
func _process(delta: float) -> void:
	if dragged_card:
		_update_drag_position()

# =====================
# DRAG SYSTEM (CAN REMOVE LATER)
# =====================
func start_drag(card):
	dragged_card = card
	card.scale = Vector2.ONE

func finish_drag():
	if dragged_card.position.y > 650:
		player_hand.add_card_to_hand(dragged_card)
	else:
		player_hand.remove_card_from_hand(dragged_card)

	dragged_card.scale = Vector2(1 + 0.05, 1 + 0.05)
	dragged_card = null

func _update_drag_position():
	var mouse_pos = get_global_mouse_position()
	dragged_card.position.x = clamp(mouse_pos.x, 0, screen_size.x)
	dragged_card.position.y = clamp(mouse_pos.y, 0, screen_size.y)

func _on_mouse_released():
	if dragged_card:
		finish_drag()

# =====================
# HOVER SYSTEM
# =====================
func connect_signals(card):
	card.hovered.connect(_on_card_hovered)
	card.hovered_off.connect(_on_card_unhovered)

func _on_card_hovered(card):
	is_hovering = true
	_highlight(card, true)

func _on_card_unhovered(card):
	if dragged_card:
		return

	is_hovering = false
	_highlight(card, false)

func _highlight(card, on: bool):
	var tween = create_tween().bind_node(card)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	var shade = card.get_node("Shade")
	var body = card.get_node("AOS")
	var base_scale = CARD_SCALE
	if card.small:
		base_scale = ACE_SCALE
	if on:
		tween.tween_property(body, "scale", Vector2(base_scale + 0.2, base_scale + 0.2), 0.4)
		tween.parallel().tween_property(shade, "modulate:a", 0.2, 0.3)
		#tween.parallel().tween_property(shade, "scale", Vector2(base_scale - 0.1, base_scale - 0.1), 0.3)
		tween.parallel().tween_property(shade, "position:y", body.position.y + 10, 0.4)
		card.z_index = 2
	else:
		tween.tween_property(body, "scale", Vector2(base_scale, base_scale), 0.4)
		tween.parallel().tween_property(shade, "modulate:a", 0.5, 0.4)
		#tween.parallel().tween_property(shade, "scale", Vector2(base_scale, base_scale), 0.3)
		tween.parallel().tween_property(shade, "position:y", body.position.y + 4.5, 0.4)
		card.z_index = 0

# =====================
# RAYCAST
# =====================
func _get_card_under_mouse():
	var space = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collide_with_bodies = true

	var results = space.intersect_point(params)
	if results.is_empty():
		return null

	return _get_top_card(results)

func _get_top_card(cards):
	var top_card = cards[0].collider.get_parent()
	for i in range(1, cards.size()):
		var current = cards[i].collider.get_parent()
		if current.z_index > top_card.z_index:
			top_card = current
	return top_card
