extends GL_Node_Picker

func color_changed(value:Color):
	mainNode.rows[valueName]["pickValue"] = value
