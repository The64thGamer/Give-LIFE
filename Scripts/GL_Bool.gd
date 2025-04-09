extends GL_Node

func _ready():
	super._ready()
	_set_title("Bool")
	_create_row("Output",null,false,true,false,0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	_send_input("Output")
