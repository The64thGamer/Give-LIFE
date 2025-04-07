extends Panel
class_name GL_Node
var rows : Dictionary
var uuid : int #REMEMBER TO SET THIS ON CREATION
var dragging : bool
var canDrag : bool

func _ready():
	_init_visuals()
	
func _process(delta):
	if dragging:
		position = get_viewport().get_mouse_position()
		
func _on_input_event(viewport, event, shape_idx):
	print(str(event) + "A")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed && canDrag:
			dragging = true
		if event.button_index == MOUSE_BUTTON_LEFT && event.canceled && dragging:
			dragging = false

func _create_uuid():
	var rand = RandomNumberGenerator.new()
	rand.seed = Time.get_unix_time_from_system()
	uuid = rand.randi()

func _init_visuals():
	var nodeVisuals = load("res://Scenes/Nodes/Node.tscn").instantiate()
	call_deferred("add_child",nodeVisuals)

func _update_visuals():
	var holder = get_node("Holder")
	for child in holder.get_children():
		if child.name != "Title":
			child.queue_free()
	for key in rows:
		if rows[key].get("type","default") == "default":
			var nodeRow = load("res://Scenes/Nodes/Node Row.tscn").instantiate()
			holder.add_child(nodeRow)
			(nodeRow.get_node("Label") as Label).text = str(key)
			(nodeRow.get_node("Input") as GL_Node_Point).valueName = str(key)
			(nodeRow.get_node("Output") as GL_Node_Point).valueName = str(key)
			_set_inout_type(nodeRow.get_node("Input") as Button,rows[key]["input"])
			_set_inout_type(nodeRow.get_node("Output") as Button,rows[key]["output"])

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

func mouse_enter():
	canDrag = true
func mouse_exit():
	canDrag = false
