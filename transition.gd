extends Control

#signal finished
#
#const HAND_SCENE_PATH = "res://scenes/card.tscn"
#
#@export var cell_size := 60
#@export var delay_between := 0.003
#@export var grow_time := 0.5
#
#var grid := []
#var cols
#var rows
#var big_rect
#
#var podium = game_master.podium
#
#func _ready():
	#create_grid()
	#transition_proccess()
	#await big_rect_transition().finished
	#game_master.podium_display_signal()
	#
#func play_transition():
	## 播放你的黑色方块动画
	#await get_tree().create_timer(1.5).timeout
	#emit_signal("finished")
#
#func create_grid():
	#var screen_size = get_viewport_rect().size
	#cols = ceil(screen_size.x / cell_size)
	#rows = ceil(screen_size.y / cell_size)
#
	#big_rect = ColorRect.new()
	#big_rect.color = Color(0, 0, 0, 0.3)
	#big_rect.size = get_viewport_rect().size
	#big_rect.position = get_viewport_rect().position
	#big_rect.scale = get_viewport_rect().size
	#big_rect.modulate.a = 0
	#add_child(big_rect)
#
	#for y in range(rows):
		#for x in range(cols):
			#var rect = ColorRect.new()
			#rect.color = Color(0, 0, 0, 0.3)
			#rect.size = Vector2(cell_size, cell_size)
			#rect.position = Vector2(x * cell_size, y * cell_size)
			#rect.scale = Vector2(0.01, 0.01)
			#rect.pivot_offset = rect.size / 2
			#rect.modulate.a = 0
			#add_child(rect)
			#grid.append(rect)
#
#func transition_proccess():
	#var index = 0
	#for y in range(rows):
		#for x in range(cols):
			#var rect = grid[y * cols + x]
			#var tween = create_tween()
			#tween.tween_property(rect, "scale", Vector2.ONE, grow_time).set_delay(index * delay_between)
			#tween.parallel().tween_property(rect, "modulate:a", 0.618, grow_time).set_delay(index * delay_between)\
			#.set_trans(Tween.TRANS_CUBIC)\
			#.set_ease(Tween.EASE_OUT)
			#index += 1
		#
#func big_rect_transition():
	#var tween = create_tween()
	#tween.tween_property(big_rect, "modulate:a", 0.618, 2.5)\
	#.set_trans(Tween.TRANS_CUBIC)\
	#.set_ease(Tween.EASE_OUT)
	#return tween
#
	#
