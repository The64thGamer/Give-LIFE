extends Area2D
class_name GL_Node_Point

var mainNode : GL_Node
@export var isOutput:bool

var valueName:String
var dragging:bool

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_finish_drag()

func _start_drag():
	if (not isOutput):
		return 
		
	dragging = true
	

func _finish_drag():
	if not dragging:
		return

	dragging = false
