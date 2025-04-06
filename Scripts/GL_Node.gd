extends Node2D
class_name GL_Node
var rows : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	_init_visuals()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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
	
func _send_input(inputName:String,value):
