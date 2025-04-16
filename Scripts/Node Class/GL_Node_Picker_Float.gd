extends GL_Node_Picker

func value_changed(value:float):
	mainNode.rows[valueName]["pickValue"] = value
