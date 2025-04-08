extends PanelContainer
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
	var holder = get_node("Margins").get_node("Holder")
	for child in holder.get_children():
		if child.name != "Title":
			child.queue_free()
	for key in rows:
		var nodeRow = load("res://Scenes/Nodes/Node Row.tscn").instantiate()
		holder.add_child(nodeRow)
		(nodeRow.get_node("Label") as Label).text = str(key)
		var input = nodeRow.get_node("Input") as GL_Node_Point
		var output = nodeRow.get_node("Output") as GL_Node_Point
		input.valueName = str(key)
		input.mainNode = self
		output.valueName = str(key)
		output.mainNode = self
		if rows[key]["picker"] == true:
			match typeof(rows[key]["pickValue"]):
				TYPE_FLOAT:
					assignPick(nodeRow.get_node("Pick Float"),str(key))
					var slider = nodeRow.get_node("Pick Float") as HSlider
					slider.max_value = rows[key]["pickFloatMax"]
					slider.value = rows[key]["pickValue"]
				TYPE_COLOR:
					assignPick(nodeRow.get_node("Pick Color"),str(key))
					(nodeRow.get_node("Pick Color") as ColorPickerButton).color = rows[key]["pickValue"]
				TYPE_BOOL:
					assignPick(nodeRow.get_node("Pick Bool"),str(key))
					(nodeRow.get_node("Pick Bool") as CheckButton).button_pressed = rows[key]["pickValue"]
		else:
			(nodeRow.get_node("Label") as Label).size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
		_set_inout_type(nodeRow.get_node("Input") as Button,rows[key]["input"])
		_set_inout_type(nodeRow.get_node("Output") as Button,rows[key]["output"])

func assignPick(pick:GL_Node_Picker,key:String):
	if pick != null:
		pick.mainNode = self
		pick.valueName = key

func give_input_point_pos(name:String) -> Vector2:
	var holder = get_node("Margins").get_node("Holder")
	if holder == null:
		return global_position
	else:
		for child in holder.get_children():
			if child.name != "Title" && (child.get_node("Label") as Label).text == name:
				holder = child.get_node("Input") as GL_Node_Point
				return holder.global_position + Vector2(holder.size.x/2,holder.size.y/2)
	return Vector2.ZERO

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
	(get_node("Margins").get_node("Holder").get_node("Title") as Label).text = name

func _create_row(name:String,input,output,picker:bool,pickDefault,pickFloatMaximum:float):
	rows[name] = {"input": input, "output": output, "connections": [], "picker":picker,"pickValue":pickDefault,"backConnected":false,"pickFloatMax":pickFloatMaximum}
	_update_visuals()

func _recieve_input(inputName:String,value):
	if rows.has(inputName):
		if typeof(rows[inputName]["input"]) == TYPE_FLOAT && typeof(value) == TYPE_BOOL:
			rows[inputName]["input"] = float(value)
		else:
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

func _confirm_backConnection(input_name:String):
	if !rows.has(input_name):
		return
	rows[input_name]["backConnected"] = true

func _create_connection(target:GL_Node,input_name:String,output_name:String):
	if not rows.has(output_name):
		return
		
	var item = target.rows.get(input_name, null)
	if item == null:
		return
		
	if typeof(rows[output_name].get("output", null)) != typeof(target.rows[input_name].get("input",null)):
		if !(typeof(rows[output_name].get("output", null)) == TYPE_BOOL && typeof(target.rows[input_name].get("input",null)) == TYPE_FLOAT):
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
	
	target._confirm_backConnection(input_name)
	
func mouse_enter():
	canDrag = true
func mouse_exit():
	canDrag = false
