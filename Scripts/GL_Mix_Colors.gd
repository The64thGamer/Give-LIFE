extends GL_Node

func _ready():
	_set_title("Mix Colors")
	_create_row("Factor",0.0,Color.WHITE,false,null,0)
	_create_row("Color A",Color.RED,null,true,Color.RED,0)
	_create_row("Color B",Color.BLUE,null,true,Color.BLUE,0)
	pass 

func _process(delta):
	super._process(delta)
	
	for key in rows:
		if rows[key]["picker"] == true && rows[key]["backConnected"] == false:
			rows[key]["input"] = rows[key]["pickValue"]
			
	rows["Factor"]["output"] = rows["Color A"]["input"].lerp(rows["Color B"]["input"],rows["Factor"]["input"])
	_send_input("Factor")
