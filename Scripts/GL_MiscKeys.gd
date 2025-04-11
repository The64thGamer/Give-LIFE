extends GL_Node

func _ready():
	super._ready()
	_set_title("Keystrokes")
	_create_row("Shift",null,false,false,0.0,1)
	_create_row("Control",null,false,false,0.0,1)
	_create_row("Alt",null,false,false,0.0,1)
	_create_row("Space",null,false,false,0.0,1)
	_create_row("Enter",null,false,false,0.0,1)
	_create_row("Backspace",null,false,false,0.0,1)
	_update_visuals()
	
func _process(delta):
	super._process(delta)

	var key_map = {
		"Shift": KEY_SHIFT,
		"Control": KEY_CTRL,
		"Alt": KEY_ALT,
		"Space": KEY_SPACE,
		"Enter": KEY_ENTER,
		"Backspace": KEY_BACKSPACE,
	}

	for key_name in key_map.keys():
		var is_pressed = Input.is_key_pressed(key_map[key_name]) or Input.is_key_pressed(key_map[key_name] + (KEY_KP_0 - KEY_0))
		rows[key_name]["output"] = is_pressed
		_send_input(key_name)
