extends GL_Node

func _ready():
	_set_title("Sine")
	_create_row("Output",null,0.0)
	_create_row("Length",0.01,null)
	pass 

func _process(delta):
	super._process(delta)
	rows["Output"]["output"] = sin(Time.get_ticks_msec() * rows["Length"].get("input",1))
	_send_input("Output")
