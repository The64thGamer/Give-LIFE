extends GL_Node


func _ready():
	super._ready()
	_set_title("Invert")
	_create_row("Value",0.0,0.0,false,0,0)
	_create_row("On",true,null,true,true,0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	apply_pick_values()

	if rows["On"]["output"] == true:
		rows["Value"]["output"] = 1 - rows["Value"]["input"]
	else:
		rows["Value"]["output"] = rows["Value"]["input"]
	_send_input("Value")
