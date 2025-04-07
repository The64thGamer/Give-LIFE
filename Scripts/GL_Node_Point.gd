extends Button
class_name GL_Node_Point

var mainNode : GL_Node
var valueName:String
var dragging:bool
var previewLine:Line2D = null
var mouseInside:bool
var lastToDrag:bool

func _process(delta):
	if dragging:
		if previewLine == null:
			previewLine = Line2D.new()
			previewLine.position = Vector2.ZERO
			add_child(previewLine)
			previewLine.width = 5
			previewLine.default_color = Color.WHITE
			previewLine.add_point(Vector2.ZERO)
			previewLine.add_point(Vector2.ZERO)
			previewLine.points[0] = Vector2(size.x / 2, size.y / 2)
			previewLine.begin_cap_mode = Line2D.LINE_CAP_ROUND
			previewLine.end_cap_mode = Line2D.LINE_CAP_ROUND
		previewLine.points[1] = get_viewport().get_mouse_position() - previewLine.global_position


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
		print("YESSS")
		for node in get_tree().get_nodes_in_group("Outputs"):
			if node is GL_Node_Point:
				node._node_connect(mainNode,valueName)

func _node_connect(node:GL_Node,inputValue:String):
	if not lastToDrag:
		return
	mainNode._create_connection(node,inputValue,valueName)
