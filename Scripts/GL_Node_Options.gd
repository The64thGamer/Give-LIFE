extends Node
class_name GL_Node_Options

var mainNode : GL_Node
var valueName:String
@export var lineEdit:LineEdit

func mainCheck():
	if mainNode == null:
		queue_free()
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			mainCheck()
		
func clear_row_recording():
	mainCheck()
	(mainNode as GL_Record)._clear_row_recordings(valueName)
	queue_free()
	
func delete_row():
	mainCheck()
	mainNode.delete_node_row(valueName)
	queue_free()
	
func set_line_name(name:String):
	lineEdit.text = name
	
func finish_rename(name:String):
	mainCheck()
	if name != "Recording" && name != "Current Time" && name != "":
		var check = false
		for key in mainNode.rows:
			if name == key:
				check = true
		if !check:
			(mainNode as GL_Record)._rename_row(valueName,name)
	queue_free()
