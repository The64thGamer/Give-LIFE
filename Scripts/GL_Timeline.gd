extends GL_Node

func _ready():
	super._ready()
	_set_title("Timeline")
	_create_row("Time",null,0.0,false,0,0)
	#_create_row("Play Speed",1.0,null,true,1.0,5.0) #Enable when you can default values
	_create_row("Play",false,null,true,false,0)
	_create_row("Rewind",false,null,true,false,0)
	_create_row("Restart",false,null,true,false,0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	#rows["Output"]["output"] = rows["Output"]["pickValue"]
	_send_input("Time")
