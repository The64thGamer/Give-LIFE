extends GL_Node

func _ready():
	super._ready()
	_set_title("Keystrokes")
	_create_row("KEY #1",null,false,false,0.0,1)
	_create_row("KEY #2",null,false,false,0.0,1)
	_create_row("KEY #3",null,false,false,0.0,1)
	_create_row("KEY #4",null,false,false,0.0,1)
	_create_row("KEY #5",null,false,false,0.0,1)
	_create_row("KEY #6",null,false,false,0.0,1)
	_create_row("KEY #7",null,false,false,0.0,1)
	_create_row("KEY #8",null,false,false,0.0,1)
	_create_row("KEY #9",null,false,false,0.0,1)
	_create_row("KEY #0",null,false,false,0.0,1)
	_update_visuals()
	
func _process(delta):
	super._process(delta)

	var key_map = {
		"KEY #1": KEY_1,
		"KEY #2": KEY_2,
		"KEY #3": KEY_3,
		"KEY #4": KEY_4,
		"KEY #5": KEY_5,
		"KEY #6": KEY_6,
		"KEY #7": KEY_7,
		"KEY #8": KEY_8,
		"KEY #9": KEY_9,
		"KEY #0": KEY_0,
	}

	for key_name in key_map.keys():
		var is_pressed = Input.is_key_pressed(key_map[key_name]) or Input.is_key_pressed(key_map[key_name] + (KEY_KP_0 - KEY_0))
		rows[key_name]["output"] = is_pressed
		_send_input(key_name)
