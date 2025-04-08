extends GL_Node

func _ready():
	_set_title("Sine")
	_create_row("Output",null,0.0,false,null,0)
	_create_row("Time",0.01,null,true,0.01,0.05)
	pass 

func _process(delta):
	super._process(delta)
	if rows["Time"]["picker"] == true && rows["Time"]["backConnected"] == false:
		rows["Time"]["input"] = rows["Time"]["pickValue"]
	rows["Output"]["output"] = (sin(Time.get_ticks_msec() * rows["Time"].get("input",1)) / 2) + 0.5
	_send_input("Output")
