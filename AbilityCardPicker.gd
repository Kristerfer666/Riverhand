extends CanvasLayer

signal card_confirmed(player_card_id: String, computer_card_id: String)

var selected_index: int = -1
var is_active: bool = false
var current_selection: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	_connect_buttons()


func _connect_buttons() -> void:
	for i in range(3):
		var btn = get_node_or_null("Control/CardsContainer/CardOption%d" % i)
		if btn:
			btn.pressed.connect(_on_card_option_pressed.bind(i))
	var confirm_btn = get_node_or_null("Control/ConfirmButton")
	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)


func show_picker() -> void:
	is_active = true
	selected_index = -1
	current_selection = AbilityCardDatabase.get_random_selection(3)
	# [TEST] force all three options to second_chance
	# var _sc = AbilityCardDatabase.CARDS.filter(func(c): return c.get("id") == "second_chance")[0]
	# current_selection = [_sc, _sc, _sc]
	# [TEST] force all three options to anticipate
	# var _ant = AbilityCardDatabase.CARDS.filter(func(c): return c.get("id") == "anticipate")[0]
	# current_selection = [_ant, _ant, _ant]
	_populate_buttons()
	visible = true
	$Control.visible = true
	$Control.modulate.a = 0.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($Control, "modulate:a", 1.0, 0.3)


func _populate_buttons() -> void:
	for i in range(3):
		var btn = get_node_or_null("Control/CardsContainer/CardOption%d" % i)
		if btn and i < current_selection.size():
			var card = current_selection[i]
			btn.text = card.get("name", "???") + "\n[" + card.get("type", "").to_upper() + "]"
			btn.tooltip_text = card.get("description", "")
		elif btn:
			btn.text = "—"
			btn.tooltip_text = ""


# Hides only the picker UI — keeps the CanvasLayer alive for the reveal phase.
func hide_picker() -> void:
	is_active = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property($Control, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): $Control.visible = false)


func _on_card_option_pressed(index: int) -> void:
	if not is_active:
		return
	selected_index = index


func _on_confirm_pressed() -> void:
	if not is_active or selected_index == -1:
		return
	if selected_index >= current_selection.size():
		return
	var player_card: Dictionary = current_selection[selected_index]
	var computer_card: Dictionary = _pick_computer_card()
	hide_picker()
	await get_tree().create_timer(0.25).timeout
	visible = true
	await _show_reveal(player_card, computer_card)
	visible = false
	card_confirmed.emit(player_card.get("id", ""), computer_card.get("id", ""))


func _pick_computer_card() -> Dictionary:
	var pool = AbilityCardDatabase.CARDS.duplicate()
	if pool.is_empty():
		return {}
	pool.shuffle()
	return pool[0]
	# [TEST] force CP to always pick second_chance
	# var _matches = AbilityCardDatabase.CARDS.filter(func(c): return c.get("id") == "second_chance")
	# return _matches[0] if not _matches.is_empty() else {}
	# [TEST] force CP to always pick anticipate
	# var _matches = AbilityCardDatabase.CARDS.filter(func(c): return c.get("id") == "anticipate")
	# return _matches[0] if not _matches.is_empty() else {}


func _show_reveal(player_card: Dictionary, computer_card: Dictionary) -> void:
	var reveal = _build_reveal_panel(player_card, computer_card)
	add_child(reveal)
	reveal.modulate.a = 0.0
	var tween_in = create_tween()
	tween_in.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_in.tween_property(reveal, "modulate:a", 1.0, 0.3)
	await tween_in.finished
	await get_tree().create_timer(1.5).timeout
	var tween_out = create_tween()
	tween_out.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween_out.tween_property(reveal, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	reveal.queue_free()


func _build_reveal_panel(player_card: Dictionary, computer_card: Dictionary) -> Control:
	var screen := get_viewport().get_visible_rect().size
	var cx := screen.x / 2.0
	var cy := screen.y / 2.0

	var root := Control.new()
	root.position = Vector2.ZERO
	root.size = screen

	var gap    := 40.0
	var card_w := 220.0
	var card_h := 280.0

	_add_card_tile(root, player_card, "You",
		Vector2(cx - gap / 2.0 - card_w, cy - card_h / 2.0),
		Vector2(card_w, card_h), Color(0.10, 0.20, 0.12, 0.95))
	_add_card_tile(root, computer_card, "Opponent",
		Vector2(cx + gap / 2.0, cy - card_h / 2.0),
		Vector2(card_w, card_h), Color(0.22, 0.08, 0.08, 0.95))
	return root


func _add_card_tile(parent: Control, card: Dictionary, header: String,
		pos: Vector2, size: Vector2, bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left     = 14
	style.corner_radius_top_right    = 14
	style.corner_radius_bottom_left  = 14
	style.corner_radius_bottom_right = 14

	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.position = pos
	panel.size = size

	var lbl_header := Label.new()
	lbl_header.text = header
	lbl_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_header.position = Vector2(0, 14)
	lbl_header.size = Vector2(size.x, 28)
	panel.add_child(lbl_header)

	var lbl_name := Label.new()
	lbl_name.text = card.get("name", "???")
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_name.position = Vector2(10, size.y / 2.0 - 30)
	lbl_name.size = Vector2(size.x - 20, 60)
	panel.add_child(lbl_name)

	var lbl_type := Label.new()
	lbl_type.text = "[" + card.get("type", "").to_upper() + "]"
	lbl_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_type.position = Vector2(0, size.y - 42)
	lbl_type.size = Vector2(size.x, 28)
	panel.add_child(lbl_type)

	parent.add_child(panel)


func reset() -> void:
	selected_index = -1
	is_active = false
	current_selection = []
	visible = false
	$Control.visible = false
	$Control.modulate.a = 1.0
