extends GL_Node

func _ready():
	super._ready()
	_set_title("Sawtooth")
	_create_row("Output",null,0.0,false,null,0)
	_create_row("Time",0.01,null,true,0.01,0.05)
	_update_visuals()
	pass 

func _process(delta):
	super._process(delta)
	apply_pick_values()
	rows["Output"]["output"] = fmod(Time.get_ticks_msec() * rows["Time"].get("input",1),1)
	_send_input("Output")
