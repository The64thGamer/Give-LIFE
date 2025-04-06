extends Node2D
class_name GL_Node
var rows : Dictionary
var uuid : int #REMEMBER TO SET THIS ON CREATION

func _ready():
	_init_visuals()
	pass 

func _process(delta):
	pass
	
func _create_uuid():
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_unix_time_from_system()
	uuid = rand.randi()

func _init_visuals():
	var nodeVisuals = load("res://Scenes/Nodes/Node.tscn")
	call_deferred("add_child",nodeVisuals)

func _update_visuals():
	var holder = get_node("Node").get_node("Holder")
	for child in holder.get_children():
		if child.name != "Title":
			child.queue_free()
	for key in rows:
		if rows[key].get("type","default") == "default":
			var nodeRow = load("res://Scenes/Nodes/Node Row.tscn")
			holder.call_deferred("add_child",nodeRow)
			(nodeRow.get_node("Label") as Label).text = str(key)
			(nodeRow.get_node("Input").get_note("Point") as GL_Node_Point).valueName = str(key)
			(nodeRow.get_node("Output").get_note("Point") as GL_Node_Point).valueName = str(key)
			_set_inout_type(nodeRow.get_node("Input") as Label,rows[key].get("input","null"))
			_set_inout_type(nodeRow.get_node("Output") as Label,rows[key].get("output","null"))

func _set_inout_type(label:Label, value):
	match typeof(value):
		_:
			label.visible = false
		TYPE_FLOAT:
			label.text = "◉"
			label.add_theme_color_override("font_color", Color.ROYAL_BLUE)
		TYPE_BOOL:
			label.text = "◆"
			label.add_theme_color_override("font_color", Color.ORANGE)
		TYPE_COLOR:
			label.text = "▲"
			label.add_theme_color_override("font_color", Color.WHITE_SMOKE)

func _set_title(name:String):
	(get_node("Node").get_node("Holder").get_node("Title") as Label).text = name

func _create_row(name:String,input,output):
	rows[name] = {"input": input, "output": output}
	_update_visuals()

func _recieve_input(inputName:String,value):
	if rows.has(inputName):
		rows[inputName]["input"] = value
	
func _send_input(output_name: String, value):
	if not rows.has(output_name):
		return

	var connections = rows[output_name].get("connections", [])
	for conn in connections:
		var target = conn.get("target", null)
		var input_name = conn.get("input_name", null)
		if target and input_name:
			target._recieve_input(input_name, value)
