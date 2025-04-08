extends GL_Node

func _ready():
	_set_title("Record")
	_create_row("Recording",false,null,true,false,0)
	_create_row("Current Time",0.0,null,false,0,0)
	pass 

func _process(delta):
	super._process(delta)
	#rows["Output"]["output"] = rows["Output"]["pickValue"]
	#_send_input("Output")
