extends Label
class_name GL_Node_R_Click_Row

var mainNode : GL_Node
var valueName:String
var mouseInside:bool = false

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and mouseInside:
		if mainNode != null:
			mainNode.r_click_row(valueName)
		
func mouse_enter():
	mouseInside = true
	
func mouse_exit():
	mouseInside = false 
