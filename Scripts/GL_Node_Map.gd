extends Control

var background: TextureRect
var holder: Control
var is_panning: bool = false
var last_mouse_pos: Vector2
var is_hovered: bool = false
var _workspace_ID:String

func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		save_everything()

func _ready():
	visible = false
	background = get_node("Background")
	holder = get_node("Holder")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	_workspace_ID = str(rng.randi())

func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				visible = not visible
				if visible:
					background.self_modulate.a = 1
			KEY_TAB:
				background.self_modulate.a = abs(background.self_modulate.a - 1)
	if not visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if not is_hovered:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			if is_panning:
				last_mouse_pos = event.position

		if event.pressed and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var mouse_pos = event.position
			var global_xform = holder.get_global_transform()
			var local_mouse_pos = global_xform.affine_inverse().basis_xform(mouse_pos)

			var zoom_factor := 1.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_factor = 1.1
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_factor = 0.9

			holder.scale *= zoom_factor

			var new_global_xform = holder.get_global_transform()
			var new_local_mouse_pos = new_global_xform.affine_inverse().basis_xform(mouse_pos)

			var delta = (new_local_mouse_pos - local_mouse_pos)
			holder.position += delta * holder.scale

	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - last_mouse_pos
		holder.position += delta
		last_mouse_pos = event.position

func save_everything():
	var saveDict := {}
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()

	for child in holder.get_children():
		child = child.get_child(0)
		if child is not GL_Node:
			continue
		var id = "SAVE_" + str(rng.randi())
		saveDict[id] = {
			"path": child.nodePath,
			"name": child._get_title(),
			"uuid": child.uuid,
			"rows": child.rows.duplicate(true), # deep copy
		}
		for key in saveDict[id]["rows"]:
			if saveDict[id]["rows"][key].has("connections"):
				var connections = saveDict[id]["rows"][key]["connections"]
				for i in range(connections.size()):
					if connections[i]["target"] is GL_Node:
						connections[i]["target"] = connections[i]["target"].uuid

	var save_dir = "user://My Precious Save Files/" + str(_workspace_ID)
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file_path = save_dir + "/node_workspace.tres"

	var resource = ConfigFile.new()
	resource.set_value("workspace", "data", saveDict)
	var err = resource.save(file_path)
	if err != OK:
		push_error("Failed to save workspace: " + str(err))
	else:
		print("Saved workspace to: ", file_path)
		
func load_everything():
	var file_path = "user://My Precious Save Files/" + str(_workspace_ID) + "/node_workspace.tres"
	var resource = ConfigFile.new()
	var err = resource.load(file_path)
	if err != OK:
		push_error("Failed to load workspace: " + str(err))
		return {}
	
	var data = resource.get_value("workspace", "data", {})
	print("Loaded workspace from: ", file_path)
	
	for key in data:
		var node := load(data[key]["path"]).instantiate() as GL_Node
		holder.add_child(node)
		node.uuid = data[key]["uuid"]
		node._set_title(data[key]["name"])
		node.rows = data[key]["rows"]
		node._update_visuals()
