extends Node2D

const ACE_SCALE = Vector2(0.6, 0.6)
const CARD_SCALE = Vector2(0.8, 0.8)

var rot_degree
var last_move_pos

func _ready() -> void:
	pass
	#rot_degree = randf_range(-4, 4)
	#var tween = create_tween()
	#tween.set_trans(Tween.TRANS_SINE)
	#tween.tween_property(self, "rotation_degrees", rot_degree, 0.15)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#$Shade.position.x = self.position.x + 2
	#$Shade.position.y = self.position.y + 2

func move_ace(new_pos): 
	last_move_pos = position
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", new_pos, 0.3)
	scale = ACE_SCALE
	#if new_pos != last_move_pos:
		#rot_degree = randf_range(-4, 4)
		#tween.parallel().tween_property(self, "rotation_degrees", rot_degree, 0.15)
	await get_tree().create_timer(0.2).timeout
	game_master.degrade_ace()
