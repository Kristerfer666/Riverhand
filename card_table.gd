extends Sprite2D

var object_list = []

func _ready():
	object_list = [
		get_node("../Table-2_png"),
		get_node("../Table-3_png"),
		get_node("../Table-4_png")
	]
	
	var screen_size = get_viewport_rect().size
	var texture_size = texture.get_size()

	self.scale = Vector2(
		screen_size.x / texture_size.x,
		screen_size.y / texture_size.y
	)
	position = screen_size / 2
	
	for i in object_list:
		resize_to_screen(i)

func resize_to_screen(object):
	var screen_size = get_viewport_rect().size
	var texture_size = object.texture.get_size()

	object.scale = Vector2(
		screen_size.x / texture_size.x,
		screen_size.y / texture_size.y
	)
	
	object.position = screen_size / 2
	object.modulate.a = 0.15
