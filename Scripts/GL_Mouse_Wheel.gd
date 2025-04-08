extends GL_Node

func _ready():
	_set_title("Mouse Wheel")
	_create_row("Output", null, 0.0, false, 0.0, 0)
	_create_row("Step Size", 0.0, null, true, 0.1, 1.0)

func _process(delta):
	super._process(delta)
	
	for key in rows:
		if rows[key]["picker"] == true && rows[key]["backConnected"] == false:
			rows[key]["input"] = rows[key]["pickValue"]
	
	_send_input("Output")

func _input(event):
	# Check if the mouse wheel up or down button is pressed
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			rows["Output"]["output"] = clamp(rows["Output"]["output"] + rows["Step Size"]["input"], 0, 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			rows["Output"]["output"] = clamp(rows["Output"]["output"] - rows["Step Size"]["input"], 0, 1)
