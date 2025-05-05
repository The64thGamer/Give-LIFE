extends Control

var rows : Dictionary = {
	"Add":1,
	"Advanced Spotlight":1,
	"Advanced Stage Lights":1,
	"Animatronic":1,
	"Audio":1,
	"Blacklight":1,
	"Bool":1,
	"Color":1,
	"Float":1,
	"Invert":1,
	"Keystrokes":1,
	"Keystroke Ramp":1,
	"Lerp":1,
	"Mix Colors":1,
	"Mix Floats":1,
	"Mouse Wheel":1,
	"Multiply":1,
	"Random":1,
	"Record":1,
	"Sawtooth":1,
	"Sine":1,
	"Speaker":1,
	"Subtract":1,
	"Switch Audio":1,
	"Timeline":1,
	}
var searching : bool

func _ready():
	_set_State(false)
	_set_rows()

func toggleSearch():
	_set_State(!searching)

func _set_State(state:bool):
	searching = state
	visible = searching

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
	var path = "res://Scenes/Node Types/" + name + ".tscn"
	var node = load(path).instantiate()
	var holder = get_parent().get_node("Holder")
	holder.add_child(node)
	node = (node as Control).get_child(0) as GL_Node
	node.nodePath = path
	node.global_position = (get_viewport().size / 2.0) - (node.get_child(0).size / 2.0)
	node._create_uuid()
	
