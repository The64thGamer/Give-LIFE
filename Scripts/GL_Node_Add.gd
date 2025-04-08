extends OptionButton
class_name GL_Node_Add

var mainNode:GL_Node
var setIndex:int

func _selected(index:int):
	disabled = true
	setIndex = index
	(get_node("Panel") as PanelContainer).visible = true

func _named(name:String):
	(get_node("Panel") as PanelContainer).visible = false
	if name == "":
		name = "my_property"
	disabled = false
	match(setIndex):
		0:
			mainNode._create_row(name,0.0,0.0,true,0.0,1.0)
		1:
			mainNode._create_row(name,false,false,true,false,0)
		2:
			mainNode._create_row(name,Color.WHITE,Color.WHITE,true,Color.WHITE,0)
	mainNode._update_visuals()
func _cancelled():
	disabled = false
	(get_node("Panel") as PanelContainer).visible = false
