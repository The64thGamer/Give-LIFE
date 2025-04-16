extends GL_Node
class_name GL_Output
@export var customRows : Dictionary

func _ready():
	super._ready()
	_set_title("Output")
	special_condition = "Animatable"
	_update_visuals()
