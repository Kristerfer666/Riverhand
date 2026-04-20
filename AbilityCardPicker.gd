extends CanvasLayer

signal card_confirmed(card_index: int)

var selected_index: int = -1
var is_active: bool = false


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
	visible = true
	$Control.modulate.a = 0.0
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($Control, "modulate:a", 1.0, 0.3)


func hide_picker() -> void:
	is_active = false
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property($Control, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)


func _on_card_option_pressed(index: int) -> void:
	if not is_active:
		return
	selected_index = index
	# TODO: highlight selected card visually


func _on_confirm_pressed() -> void:
	if not is_active or selected_index == -1:
		return
	var confirmed = selected_index
	hide_picker()
	card_confirmed.emit(confirmed)


func reset() -> void:
	selected_index = -1
	is_active = false
	visible = false
	$Control.modulate.a = 1.0
