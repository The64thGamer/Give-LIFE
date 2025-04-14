extends GL_Node

func _ready():
	super._ready()
	_set_title("Subtract")
	_create_row("Float A",0.0,0.0,true,0.0,1.0)
	_create_row("Float B",0.0,null,true,0.0,1.0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
			
	rows["Float A"]["output"] = float(rows["Float A"]["input"]) - float(rows["Float B"]["input"])
	_send_input("Float A")
