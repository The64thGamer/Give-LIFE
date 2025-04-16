extends GL_Node

func _ready():
	super._ready()
	_set_title("Mix Floats")
	_create_row("Factor",0.0,0.0,false,null,0)
	_create_row("Float A",0.0,null,true,0.0,1.0)
	_create_row("Float B",0.0,null,true,0.0,1.0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
			
	rows["Factor"]["output"] = lerp(float(rows["Float A"]["input"]),float(rows["Float B"]["input"]),rows["Factor"]["input"])
	_send_input("Factor")
