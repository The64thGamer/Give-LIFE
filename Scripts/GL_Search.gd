extends Control

var rows : Dictionary = {"Sine":99}
var searching : bool
var lastMousePos : Vector2

func _ready():
	_set_State(false)
	_set_rows()

func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_set_State(!searching)

func _set_State(state:bool):
	searching = state
	visible = searching
	lastMousePos = get_viewport().get_mouse_position()

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
		container.call_deferred("add_child",row)

func _create_node(name:String):
	var node = load("res://Scenes/Node Types/" + name + ".tscn").instantiate()
	get_tree().root.add_child(node)
	print("res://Scenes/Node Types/" + name + ".tscn")
	node = node as GL_Node
	node._create_uuid()
	
