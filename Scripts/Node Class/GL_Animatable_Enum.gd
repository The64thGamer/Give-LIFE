extends OptionButton
class_name GL_Animatable_Enum
var mainNode:GL_Node
var output:GL_Output
var complete:bool = false
	
func set_up_enum(node):
	mainNode = node
	output = mainNode as GL_Output
	if mainNode.special_saved_values.get("currentKey","") == "":
		for key in output.customRows:
			mainNode.special_saved_values = {"currentKey":key}
			break
	var index := 0
	for key in output.customRows:
		add_item(key)
		if key == mainNode.special_saved_values.get("currentKey",""):
			select(index) # <-- Sets without emitting signal
		index += 1 
	
func selected(index:int):
	mainNode.special_saved_values = {"currentKey":get_item_text(index)}
	reset()
	
func reset():
	mainNode.rows = {}
	var mainKey = mainNode.special_saved_values.get("currentKey","")
	for key in output.customRows[mainKey]:
		mainNode._create_row(key,output.customRows[mainKey][key],null,false,0,0)
	mainNode._set_title(mainKey)
	mainNode._update_visuals()


func _process(delta):
	mainNode.apply_pick_values()
	for node in get_tree().get_nodes_in_group(mainNode.special_saved_values.get("currentKey","")):
		if node is GL_Animatable:
			for key in mainNode.rows:
				node._sent_signals(key,mainNode.rows[key]["input"])
