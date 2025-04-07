extends Panel
class_name GL_Node
var rows : Dictionary
var uuid : int #REMEMBER TO SET THIS ON CREATION
var dragging : bool
var canDrag : bool
var dragOffset : Vector2
	
func _process(delta):
	if dragging:
		position = get_viewport().get_mouse_position() + dragOffset
		
func _input(event): 
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed && canDrag:
			dragging = true
			dragOffset = position - get_viewport().get_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT && !event.pressed && dragging:
			dragging = false

func _create_uuid():
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_unix_time_from_system()
	uuid = rand.randi()

func _update_visuals():
	var holder = get_node("Holder")
	for child in holder.get_children():
		if child.name != "Title":
			child.queue_free()
	for key in rows:
		var nodeRow = load("res://Scenes/Nodes/Node Row.tscn").instantiate()
		holder.add_child(nodeRow)
		nodeRow.name = str(key)
		(nodeRow.get_node("Label") as Label).text = str(key)
		var input = nodeRow.get_node("Input") as GL_Node_Point
		var output = nodeRow.get_node("Output") as GL_Node_Point
		input.valueName = str(key)
		input.mainNode = self
		output.valueName = str(key)
		output.mainNode = self
		_set_inout_type(nodeRow.get_node("Input") as Button,rows[key]["input"])
		_set_inout_type(nodeRow.get_node("Output") as Button,rows[key]["output"])

func give_input_point_pos(name:String) -> Vector2:
	var holder = get_node("Holder").get_node(name)
	if holder == null:
		return global_position
	else:
		holder = holder.get_node("Input") as GL_Node_Point
		return holder.global_position + Vector2(holder.size.x/2,holder.size.y/2)

func _set_inout_type(label:Button, value):
	match typeof(value):
		TYPE_FLOAT:
			label.text = "◉"
			label.add_theme_color_override("font_color", Color.ROYAL_BLUE)
		TYPE_BOOL:
			label.text = "◆"
			label.add_theme_color_override("font_color", Color.ORANGE)
		TYPE_COLOR:
			label.text = "▲"
			label.add_theme_color_override("font_color", Color.WHITE_SMOKE)
		_:
			label.visible = false

func _set_title(name:String):
	(get_node("Holder").get_node("Title") as Label).text = name

func _create_row(name:String,input,output):
	rows[name] = {"input": input, "output": output, "connections": []}
	_update_visuals()

func _recieve_input(inputName:String,value):
	if rows.has(inputName):
		rows[inputName]["input"] = value
	
func _send_input(output_name: String):
	if not rows.has(output_name):
		return

	var connections = rows[output_name].get("connections", [])
	for conn in connections:
		var target = conn.get("target", null)
		var input_name = conn.get("input_name", null)
		if target and input_name:
			target._recieve_input(input_name, rows[output_name]["output"])

func _create_connection(target:GL_Node,input_name:String,output_name:String):
	if not rows.has(output_name):
		return
		
	var item = target.rows.get(input_name, null)
	if item == null:
		return
		
	if typeof(rows[output_name].get("output", null)) != typeof(target.rows[input_name].get("input",null)):
		print("Type mismatch: cannot connect " + output_name + " to " + target.name)
		return
	
	var thenew = {
		"target": target,
		"input_name": input_name
	}
	
	var connections = rows[output_name].get("connections",[])
	
	for connection in connections:
		if connection.target == thenew.target and connection.input_name == thenew.input_name:
			print("Connection already exists: " + output_name + " to " + target.name)
			return
	
	connections.append(thenew)
	rows[output_name]["connections"] = connections
	
	
func mouse_enter():
	canDrag = true
func mouse_exit():
	canDrag = false
