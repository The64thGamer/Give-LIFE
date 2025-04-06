extends Node2D
var rows : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	_init_visuals()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _init_visuals():
	var nodeVisuals = load("res://Scenes/Nodes/Node.tscn")
	call_deferred("add_child",nodeVisuals)

func _update_visuals():
	var holder = get_node("Node").get_node("Holder")
	for child in holder.get_children():
		if child.name != "Title":
			child.queue_free()
	for row in rows:
		if row.get("type","default") == "default":
			var nodeRow = load("res://Scenes/Nodes/Node Row.tscn")
			holder.call_deferred("add_child",nodeRow)
			(nodeRow.get_node("Label") as Label).text = row.get("name","???")
			_set_inout_type(nodeRow.get_node("Input") as Label,row.get("input","null"))
			_set_inout_type(nodeRow.get_node("Output") as Label,row.get("output","null"))

func _set_inout_type(label : Label , type : String):
	match type:
		"null":
			label.visible = false
		"float":
			label.text = "◉"
			label.add_theme_color_override("font_color", Color.ROYAL_BLUE)
		"bool":
			label.text = "◆"
			label.add_theme_color_override("font_color", Color.ORANGE)
		"color":
			label.text = "▲"
			label.add_theme_color_override("font_color", Color.WHITE_SMOKE)
