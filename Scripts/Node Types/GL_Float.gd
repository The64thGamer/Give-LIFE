extends GL_Node

func _ready():
	super._ready()
	_set_title("Float")
	_create_row("Output",null,0.0,true,0.0,1)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	_send_input("Output")
