extends GL_Node_Picker

func toggled(value:bool):
	mainNode.rows[valueName]["pickValue"] = value
