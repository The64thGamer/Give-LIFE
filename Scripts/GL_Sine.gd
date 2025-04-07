extends GL_Node

func _ready():
	_set_title("Sine")
	_create_row("Output",null,0.0,false,null,0)
	_create_row("Length",0.01,null,true,0.01,0.05)
	pass 

func _process(delta):
	super._process(delta)
	if rows["Length"]["picker"] == true && rows["Length"]["backConnected"] == false:
		rows["Length"]["input"] = rows["Length"]["pickValue"]
	rows["Output"]["output"] = (sin(Time.get_ticks_msec() * rows["Length"].get("input",1)) / 2) + 0.5
	_send_input("Output")
