extends OptionButton
class_name GL_Animatable_Enum
var currentKey:String
var mainNode
var output:GL_Output
var complete:bool = false
	
func set_up_enum(node):
	mainNode = node
	output = mainNode as GL_Output
	for key in output.customRows:
		currentKey = key
		break
	for key in output.customRows:
		add_item(key)
	
func selected(index:int):
	currentKey = get_item_text(index)
	reset()
	
func reset():
	mainNode.rows = {}
	for key in output.customRows[currentKey]:
		mainNode._create_row(key,output.customRows[currentKey][key],null,false,0,0)
	mainNode._set_title(currentKey)
	mainNode._update_visuals()


func _process(delta):
	mainNode.apply_pick_values()
	
	for node in get_tree().get_nodes_in_group(currentKey):
		if node is GL_Animatable:
			for key in mainNode.rows:
				node._sent_signals(key,mainNode.rows[key]["input"])
