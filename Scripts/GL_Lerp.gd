extends GL_Node


func _ready():
	_set_title("Lerp")
	_create_row("Value",0.0,0.0,true,0.0,1.0)
	_create_row("Speed",1.0,null,true,1.0,25.0)
	pass 

func _process(delta):
	super._process(delta)
	
	for key in rows:
		if rows[key]["picker"] == true && rows[key]["backConnected"] == false:
			rows[key]["input"] = rows[key]["pickValue"]
			
	rows["Value"]["output"] = lerp(float(rows["Value"]["output"]),float(rows["Value"]["input"]),delta * rows["Speed"]["input"])
	_send_input("Value")
