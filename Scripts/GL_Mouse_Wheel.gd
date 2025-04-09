extends GL_Node

func _ready():
	super._ready()
	_set_title("Mouse Wheel")
	_create_row("Output", null, 0.0, false, 0.0, 0)
	_create_row("Step Size", 0.0, null, true, 0.1, 1.0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	
	_send_input("Output")

func _unhandled_input(event):
	# Check if the mouse wheel up or down button is pressed
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			rows["Output"]["output"] = float(clamp(rows["Output"]["output"] + rows["Step Size"]["input"], 0, 1))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			rows["Output"]["output"] = float(clamp(rows["Output"]["output"] - rows["Step Size"]["input"], 0, 1))
