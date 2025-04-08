extends Button
class_name GL_Node_Point

var mainNode : GL_Node
var valueName:String
var dragging:bool
var previewLine:Line2D = null
var mouseInside:bool
var lastToDrag:bool
var allLines: Array

func _process(delta):
	if dragging:
		if previewLine == null:
			previewLine = _create_line()
		previewLine.points[0] = global_position + Vector2(size.x / 2, size.y / 2)
		previewLine.points[1] = get_viewport().get_mouse_position()
		var output = mainNode.rows[valueName]["output"]
		match typeof(output):
			TYPE_FLOAT:
				previewLine.default_color = Color(0.254902 * output, 0.411765 * output, 0.882353 * output, 1) 
			TYPE_BOOL:
				if output:
					previewLine.default_color = Color.ORANGE
				else:
					previewLine.default_color = Color.BLACK
			TYPE_COLOR:
				previewLine.default_color = output
		
	var connections = mainNode.rows[valueName].get("connections",[])
	if connections != []:
		var iter = 0
		for child:Line2D in allLines:
			var output = mainNode.rows[valueName]["output"]
			tooltip_text = str(output)
			match typeof(output):
				TYPE_FLOAT:
					child.default_color = Color(0.254902 * output, 0.411765 * output, 0.882353 * output, 1) 
				TYPE_BOOL:
					if output:
						child.default_color = Color.ORANGE
					else:
						child.default_color = Color.BLACK
				TYPE_COLOR:
					child.default_color = output
			child.points[0] = global_position + Vector2(size.x / 2, size.y / 2)
			child.points[1] = (connections[iter]["target"] as GL_Node).give_input_point_pos(connections[iter]["input_name"])# - child.global_position
			iter += 1

func _create_line() -> Line2D:
	var previewLine = Line2D.new()
	previewLine.position = Vector2.ZERO
	previewLine.width = 5
	previewLine.default_color = Color.WHITE
	previewLine.add_point(Vector2.ZERO)
	previewLine.add_point(Vector2.ZERO)
	previewLine.begin_cap_mode = Line2D.LINE_CAP_ROUND
	previewLine.end_cap_mode = Line2D.LINE_CAP_ROUND
	previewLine.antialiased = true
	previewLine.top_level = true
	add_child(previewLine)
	return previewLine

func update_lines():
	if name == "Input":
		return
	for child in allLines:
		child.queue_free()
	allLines = []
	for child in mainNode.rows[valueName].get("connections",[]):
		allLines.append(_create_line())

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if !event.pressed:
			_finish_drag()
		if event.pressed && !dragging:
			lastToDrag = false

func _start_drag():
	dragging = true
	lastToDrag = true
	
func mouse_enter():
	mouseInside = true
	
func mouse_exit():
	mouseInside = false 

func _finish_drag():
	if dragging:
		previewLine.queue_free()
		dragging = false
	elif mouseInside:
		for node in get_tree().get_nodes_in_group("Outputs"):
			if node is GL_Node_Point:
				node._node_connect(mainNode,valueName)

func _node_connect(node:GL_Node,inputValue:String):
	if not lastToDrag:
		return
	mainNode._create_connection(node,inputValue,valueName)
	update_lines()
