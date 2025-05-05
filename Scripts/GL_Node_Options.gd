extends Node
class_name GL_Node_Options

var mainNode : GL_Node
var valueName:String

func mainCheck():
	if mainNode == null:
		queue_free()
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			mainCheck()
		
func clear_row_recording():
	mainCheck()
	
func delete_row():
	mainCheck()
	
func rename_row():
	mainCheck()
