extends Control

var rows : Dictionary = {
	"Sine":99,
	"Random":99,
	"Float":99,
	"Chica":1,
	"ChicaSpot":1,
	"Keystrokes":1,
	"Keystroke Ramp":1,
	"Mix Colors":1,
	"Lerp":1,
	"Mouse Wheel":1,
	}
var searching : bool
var lastMousePos : Vector2

func _ready():
	_set_State(false)
	_set_rows()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT && event.pressed:
				_set_State(!searching)
		#if event.button_index == MOUSE_BUTTON_LEFT && event.pressed && searching:
				#_set_State(false) #fix when not hovered

func _set_State(state:bool):
	searching = state
	visible = searching
	lastMousePos = get_viewport().get_mouse_position()
	position = lastMousePos

func _set_rows():
	var container = get_node("Panel").get_node("ScrollContainer").get_node("Container")
	for child in container.get_children():
		child.queue_free()
	for key in rows:
		var row = load("res://Scenes/UI/Search Row.tscn").instantiate()
		var button = (row.get_node("Button") as Button)
		button.text = str(key)
		button.pressed.connect(func():
			_create_node(button.text)
		)
		button.pressed.connect(func():
			_set_State(false)
		)
		container.call_deferred("add_child",row)

func _create_node(name:String):
	var node = load("res://Scenes/Node Types/" + name + ".tscn").instantiate()
	get_parent().add_child(node)
	node = (node as Control).get_child(0) as GL_Node
	node.position = lastMousePos
	node._create_uuid()
	
