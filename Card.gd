extends Node2D

signal hovered
signal hovered_off
signal ace_selected(card)

const ACE_SCALE = Vector2(2.6, 2.6)
const CARD_SCALE = Vector2(2.8, 2.8)
const PODIUM_SCALE = Vector2(5, 5)
const CARD_HITBOX_SIZE = Vector2(40, 55)

var rot_degree_x
var rot_degree_y

var inhand_position
var drag
var animating
var face_up
var num
var suit
var ace = false
var side = false
var small = false
var podium = false
var podium_index
var side_order
var ace_pos
var correct_y
var last_move_pos
var move_tween: Tween
var screen_mid_y

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent().connect_signals(self)
	shade_initial()
	resize_to_screen()
	
func _process(delta: float) -> void:
	pass
	

func shade_initial():
	$Shade.position.x = $AOS.position.x + 4
	$Shade.position.y = $AOS.position.y + 4

func random_rotate():
	rot_degree_x = randf_range(-2, 2)
	rot_degree_y = randf_range(-2, 2)
	$Shade.position.x += rot_degree_x
	$Shade.position.y += rot_degree_y
	

func resize_to_screen():
	#position.y = deck.position.y
	#position.x = deck.position.x
	rescale()
	
func rescale():
	var scale_to_use = Vector2(1, 1)
	
	if podium:
		scale_to_use = PODIUM_SCALE
		podium_display_start()
	else:
		if small == true:
			scale_to_use = ACE_SCALE
			random_rotate()
		else:
			scale_to_use = CARD_SCALE
			random_rotate()
		

	# visual
	$AOS.scale = scale_to_use
	$Shade.scale = scale_to_use
	$AnimatedSprite2D.scale = scale_to_use
	$AnimatedSprite2D.visible = false

	# collision (do NOT scale node)
	var shape = $Area2D/CollisionShape2D.shape
	if shape != null:
		if shape is RectangleShape2D:
			shape.extents = CARD_HITBOX_SIZE * scale_to_use * 0.5

func move_ace(new_pos): 
	if new_pos != position:
		move_tween = create_tween().bind_node(self)
		if move_tween:
			move_tween.kill()
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "global_position", new_pos, 0.6)
		var shadow_track = create_tween()
		var shade_new_pos = calc_shade_new_pos(new_pos)
		shadow_track.tween_property($Shade, "position", shade_new_pos, 0.4)
		shadow_track.parallel().tween_property($Shade, "modulate:a", 0.2, 0.4)
		shadow_track.parallel().tween_property($Shade, "scale", ACE_SCALE * 0.9, 0.4)
		shadow_track.parallel().tween_property($AOS, "scale", ACE_SCALE * 1.1, 0.4)
		shadow_track.tween_interval(0.05)
		var shade_last_pos = calc_shade_last_pos()
		shadow_track.tween_property($Shade, "position", shade_last_pos, 0.15)
		shadow_track.parallel().tween_property($Shade, "modulate:a", 0.5, 0.15)
		shadow_track.parallel().tween_property($Shade, "scale", ACE_SCALE, 0.15)
		shadow_track.parallel().tween_property($AOS, "scale", ACE_SCALE, 0.15)
		shadow_track.tween_callback(func():
			random_rotate()
		)
		await tween.finished
	
func calc_shade_new_pos(ace_pos):
	var shade_pos = Vector2($Shade.position.x + 14, $Shade.position.y + 30)
	return shade_pos
	
func calc_shade_last_pos():
	var shade_pos = Vector2($AOS.position.x + 4, $AOS.position.y + 4)
	return shade_pos

func podium_display_start():
	screen_mid_y = get_viewport_rect().size.y / 2
	var tween = create_tween().bind_node(self)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($AOS, "scale", PODIUM_SCALE * 1.2, 0.6)
	tween.parallel().tween_property($AOS, "global_position:y", screen_mid_y - 60, 0.6)
	tween.parallel().tween_property($Shade, "modulate:a", 0.2, 0.6)
	tween.parallel().tween_property($Shade, "scale", PODIUM_SCALE * 0.9, 0.6)
	tween.parallel().tween_property($Shade, "global_position:y", screen_mid_y + 1, 0.6)
	tween.tween_interval(1)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property($AOS, "scale", PODIUM_SCALE * podium_index, 0.4)
	tween.parallel().tween_property($AOS, "global_position:y", screen_mid_y - 3, 0.4)
	tween.parallel().tween_property($Shade, "modulate:a", 0.5, 0.4)
	tween.parallel().tween_property($Shade, "scale", PODIUM_SCALE, 0.4)
	tween.parallel().tween_property($Shade, "global_position:y", screen_mid_y, 0.4)

func anim_gold():
	#$AnimatedSprite2D.visible = true
	animating = true
	emit_signal("hovered_off", self)
	#$AnimatedSprite2D.play("Anim-GoldAO" + suit_to_letter())
	var gold_image = str("res://materials/Card Faces/ver2/Aces/GoldAces/GoldAO" + suit_to_letter() + ".png")
	print(gold_image)
	$AOS.texture = load(gold_image)
	#await $AnimatedSprite2D.animation_finished
	animating = false
	$AnimatedSprite2D.visible = false
	
func suit_to_letter():
	var suit_letter
	match suit:
		1: suit_letter = "S"
		2: suit_letter = "H"
		3: suit_letter = "C"
		4: suit_letter = "D"
	return suit_letter

func _on_area_2d_mouse_entered() -> void:
	if !animating:
		emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	if !animating:
		emit_signal("hovered_off", self)
