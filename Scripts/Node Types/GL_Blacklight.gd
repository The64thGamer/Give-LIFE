extends GL_Node

func _ready():
	super._ready()
	_set_title("Blacklight")
	_create_row("Output",null,Color("#746ca7"),false,0,0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	_send_input("Output")
