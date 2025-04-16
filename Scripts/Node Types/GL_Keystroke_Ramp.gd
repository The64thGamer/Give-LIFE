extends GL_Node

var key_to_value = {
	KEY_1: 1.0 / 10,
	KEY_2: 2.0 / 10,
	KEY_3: 3.0 / 10,
	KEY_4: 4.0 / 10,
	KEY_5: 5.0 / 10,
	KEY_6: 6.0 / 10,
	KEY_7: 7.0 / 10,
	KEY_8: 8.0 / 10,
	KEY_9: 9.0 / 10,
	KEY_0: 1.0,
}

var toggle_to_value = {
	KEY_1: 0,
	KEY_2: 1.0 / 9,
	KEY_3: 2.0 / 9,
	KEY_4: 3.0 / 9,
	KEY_5: 4.0 / 9,
	KEY_6: 5.0 / 9,
	KEY_7: 6.0 / 9,
	KEY_8: 7.0 / 9,
	KEY_9: 8.0 / 9,
	KEY_0: 1.0,
}

func _ready():
	super._ready()
	_set_title("Keystroke Ramp")
	_create_row("Output", null, 0.0, false, 0.0, 0)
	_create_row("Toggle", null, null, true, false, 0)
	_update_visuals()

func _process(delta):
	super._process(delta)

	if rows["Toggle"]["pickValue"]:
		for key in toggle_to_value.keys():
			if Input.is_key_pressed(key) or Input.is_key_pressed(key + (KEY_KP_0 - KEY_0)):
				rows["Output"]["output"] = toggle_to_value[key]
				break
	else:
		var output_value := 0.0
		for key in key_to_value.keys():
			if Input.is_key_pressed(key) or Input.is_key_pressed(key + (KEY_KP_0 - KEY_0)):
				output_value = key_to_value[key]
				break
		rows["Output"]["output"] = output_value

	_send_input("Output")
