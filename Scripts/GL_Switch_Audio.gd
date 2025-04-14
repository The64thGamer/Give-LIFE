extends GL_Node

func _ready():
	super._ready()
	_set_title("Switch Audio")
	_create_row("Toggle",false,GL_AudioType.new(),true,false,0)
	_create_row("Audio A",GL_AudioType.new(),null,true,GL_AudioType.new(),0)
	_create_row("Audio B",GL_AudioType.new(),null,true,GL_AudioType.new(),0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	if(rows["Toggle"]["input"] == false):
		rows["Toggle"]["output"] = rows["Audio A"]["input"]
	else:
		rows["Toggle"]["output"] = rows["Audio B"]["input"]
	_send_input("Toggle")
