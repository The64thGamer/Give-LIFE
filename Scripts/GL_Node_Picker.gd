extends Control
class_name GL_Node_Picker
var mainNode : GL_Node
var valueName:String

func _process(delta):
	if mainNode == null:
		return
	visible = !mainNode.rows[valueName]["backConnected"]
