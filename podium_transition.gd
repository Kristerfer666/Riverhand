extends Node2D

signal finished

const HAND_SCENE_PATH = "res://scenes/card.tscn"

@export var cell_size := 60
@export var delay_between := 0.003
@export var grow_time := 0.5

var grid := []
var cols
var rows

var podium

func _ready():
	podium = $"../GameMaster".podium
	
func transition_signal():
	var big_rect = ColorRect.new()
	big_rect_setting(big_rect)
	big_rect.modulate.a = 0
	create_grid()
	transition_proccess()
	await big_rect_transition(big_rect, 1, 2.5).finished
	big_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"../Deck".podium_display()
	
func enter_transition_signal():
	var big_rect = ColorRect.new()
	big_rect_setting(big_rect)
	big_rect.modulate.a = 1
	big_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await big_rect_transition(big_rect, 0, 2).finished
	big_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func final_transition_signal():
	var big_rect = ColorRect.new()
	big_rect_setting(big_rect)
	big_rect.z_index = 100
	big_rect.color = Color(0, 0, 0, 1)
	big_rect.modulate.a = 0
	var label = get_node("../CanvasLayer/Control/Label")
	var game_end_label = get_node("../CanvasLayer/GameEndLabel")
	var tween = big_rect_transition(big_rect, 1, 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0, 1.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(game_end_label, "modulate:a", 0, 1.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	return tween

func reset():
	for child in get_children():
		child.queue_free()
	grid.clear()

func play_transition():
	# 播放你的黑色方块动画
	await get_tree().create_timer(1.5).timeout
	emit_signal("finished")

func create_grid():
	var screen_size = get_viewport_rect().size
	cols = ceil(screen_size.x / cell_size)
	rows = ceil(screen_size.y / cell_size)

	for y in range(rows):
		for x in range(cols):
			var rect = ColorRect.new()
			rect.color = Color(0, 0, 0, 0.6)
			rect.size = Vector2(cell_size, cell_size)
			rect.position = Vector2(x * cell_size, y * cell_size)
			rect.scale = Vector2(0.01, 0.01)
			rect.pivot_offset = rect.size / 2
			rect.modulate.a = 0
			add_child(rect)
			grid.append(rect)

func transition_proccess():
	var index = 0
	for y in range(rows):
		for x in range(cols):
			var rect = grid[y * cols + x]
			var tween = create_tween()
			tween.tween_property(rect, "scale", Vector2.ONE, grow_time).set_delay(index * delay_between)
			tween.parallel().tween_property(rect, "modulate:a", 1, grow_time).set_delay(index * delay_between)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			index += 1
		
func big_rect_transition(big_rect, alpha, time):
	var tween = create_tween()
	tween.tween_property(big_rect, "modulate:a", alpha, time)\
	.set_trans(Tween.TRANS_CUBIC)\
	.set_ease(Tween.EASE_OUT)
	return tween

func big_rect_setting(big_rect):
	big_rect.color = Color(0, 0, 0, 0.6)
	big_rect.size = get_viewport_rect().size
	big_rect.position = get_viewport_rect().position
	big_rect.scale = get_viewport_rect().size
	add_child(big_rect)
	
