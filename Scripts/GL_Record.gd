extends GL_Node

var recording:Dictionary

func _ready():
	super._ready()
	_set_title("Record")
	special_condition = "Record Node"
	_create_row("Recording",false,null,true,false,0)
	_create_row("Current Time",0.0,0.0,false,0,0)
	_update_visuals()
	pass 

func _process(delta):
	super._process(delta)
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	apply_pick_values()
	for key in rows:
		_send_input(key)
