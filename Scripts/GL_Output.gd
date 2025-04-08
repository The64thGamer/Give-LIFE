extends GL_Node

@export var identification : String
@export var names : PackedStringArray
@export var types : PackedStringArray

func _ready():
	_set_title(identification)
	for i in names.size():
		match(types[i].to_lower()):
			"float":
				_create_row(str(names[i]),0.01,null,true,0.5,1)
			"color":
				_create_row(str(names[i]),Color.WHITE,null,true,Color.WHITE,0)
			"bool":
				_create_row(str(names[i]),false,null,true,false,0)
	pass 

func _process(delta):
	super._process(delta)
	
	for key in rows:
		if rows[key]["picker"] == true && rows[key]["backConnected"] == false:
			rows[key]["input"] = rows[key]["pickValue"]
	
	for node in get_tree().get_nodes_in_group(identification):
		if node is GL_Animatable:
			for key in rows:
				node._sent_signals(key,rows[key]["input"])
