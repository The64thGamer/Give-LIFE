extends GL_Node

@export var identification : String
@export var names : PackedStringArray
@export var types : PackedStringArray

func _ready():
	super._ready()
	_set_title(identification)
	for i in names.size():
		match(types[i].to_lower()):
			"float":
				_create_row(str(names[i]),0.01,null,true,0.5,1)
			"color":
				_create_row(str(names[i]),Color.WHITE,null,true,Color.WHITE,0)
			"bool":
				_create_row(str(names[i]),false,null,true,false,0)
			"audio":
				_create_row(str(names[i]),GL_AudioType.new(),null,true,GL_AudioType.new(),0)
	_update_visuals()

func _process(delta):
	super._process(delta)
	apply_pick_values()
	
	for node in get_tree().get_nodes_in_group(identification):
		if node is GL_Animatable:
			for key in rows:
				node._sent_signals(key,rows[key]["input"])
