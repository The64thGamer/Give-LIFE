extends Control
var background:TextureRect

func _ready():
	visible = false
	background = get_node("Background")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match(event.keycode):
			KEY_ESCAPE:
				visible = not visible
				if visible:
					background.self_modulate.a = 1
			KEY_TAB:
				background.self_modulate.a = abs(background.self_modulate.a - 1)
	
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
