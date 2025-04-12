extends Control

var background: TextureRect
var holder: Control
var is_panning: bool = false
var last_mouse_pos: Vector2
var is_hovered: bool = false

#Workspace shenanigans
var optionsVar:OptionButton

#Workspaces
var _workspace_ID:String
var save_name: String = "My Save"
var author_name: String = "Unnamed Author"
var version: String = ProjectSettings.get_setting("application/config/version")
var game_title: String = ProjectSettings.get_setting("application/config/name")
var time_created: String = ""
var last_updated: String = ""


func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		save_everything()

func _ready():
	visible = false
	background = get_node("Background")
	holder = get_node("Holder")
	optionsVar = get_node("MarginContainer/HBoxContainer/OptionButton")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

	_workspace_ID = generate_new_workspace_id()
	populate_workspace_options()
	optionsVar.connect("item_selected", Callable(self, "_on_workspace_selected"))


func _on_mouse_entered():
	is_hovered = true

func _on_mouse_exited():
	is_hovered = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				visible = not visible
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
	
	if holder.get_child_count() == 0:
		return

	for child in holder.get_children():
		child = child.get_child(0)
		if child is not GL_Node:
			print(child.name)
			continue

		var id = "SAVE_" + str(rng.randi())
		var node_data = {
			"path": child.nodePath,
			"name": child._get_title(),
			"uuid": child.uuid,
			"rows": child.rows.duplicate(true),
			"position": child.position
		}

		# Save recording if it's a GL_Record and has enough data
		if child is GL_Record and child.recording != null:
			if child.recording.size() >= 3:
				var recording_file_path = "user://My Precious Save Files/" + str(_workspace_ID) + "/" + child.uuid + "_recording.tres"
				var recording_config = ConfigFile.new()
				recording_config.set_value("recording", "data", child.recording)
				var err = recording_config.save(recording_file_path)
				if err != OK:
					push_error("Failed to save recording for " + child.uuid + ": " + str(err))
				else:
					print("Saved recording for node ", child.uuid)

		# Convert connections to uuid references
		for key in node_data["rows"]:
			if node_data["rows"][key].has("connections"):
				var connections = node_data["rows"][key]["connections"]
				for i in range(connections.size()):
					if connections[i]["target"] is GL_Node:
						connections[i]["target"] = connections[i]["target"].uuid

		saveDict[id] = node_data

	var save_dir = "user://My Precious Save Files/" + str(_workspace_ID)
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file_path = save_dir + "/node_workspace.tres"

	var resource = ConfigFile.new()

	# Metadata section
	if time_created == "":
		time_created = Time.get_datetime_string_from_system(true)
	last_updated = Time.get_datetime_string_from_system(true)

	resource.set_value("meta", "save_name", save_name)
	resource.set_value("meta", "author", author_name)
	resource.set_value("meta", "version", ProjectSettings.get_setting("application/config/version"))
	resource.set_value("meta", "game_title", ProjectSettings.get_setting("application/config/name"))
	resource.set_value("meta", "time_created", time_created)
	resource.set_value("meta", "last_updated", last_updated)

	# Main save data
	resource.set_value("workspace", "data", saveDict)

	var err = resource.save(file_path)
	if err != OK:
		push_error("Failed to save workspace: " + str(err))
	else:
		print("Saved workspace to: ", file_path)

	populate_workspace_options()


		
func load_everything():
	var file_path = "user://My Precious Save Files/" + str(_workspace_ID) + "/node_workspace.tres"
	var resource = ConfigFile.new()
	var err = resource.load(file_path)
	if err != OK:
		push_error("Failed to load workspace: " + str(err))
		return {}

	# Load metadata
	save_name = resource.get_value("meta", "save_name", "Unnamed Save")
	author_name = resource.get_value("meta", "author", "Unknown Author")
	version = resource.get_value("meta", "version", "0.0")
	game_title = resource.get_value("meta", "game_title", "Untitled Game")
	time_created = resource.get_value("meta", "time_created", "")
	last_updated = resource.get_value("meta", "last_updated", "")

	print("Loaded workspace metadata:")
	print("Save Name: ", save_name)
	print("Author: ", author_name)
	print("Version: ", version)
	print("Game Title: ", game_title)
	print("Time Created: ", time_created)
	print("Last Updated: ", last_updated)

	# Load nodes
	var data = resource.get_value("workspace", "data", {})
	for key in data:
		var packed_scene = load(data[key]["path"])
		if packed_scene == null:
			printerr("Could not load resource at: " + data[key]["path"])
			continue
		var node = packed_scene.instantiate() as Control
		holder.add_child(node)
		node = node.get_child(0) as GL_Node
		node.position = data[key].get("position",Vector2.ZERO)
		node.nodePath = data[key].get("path","ERR")
		node.uuid = data[key].get("uuid","ERR_" + key + str(Time.get_ticks_msec()))
		node._set_title(data[key].get("name","???"))
		node.rows = data[key].get("rows",{})
		node._update_visuals()
		if node is GL_Record:
			var recording_file = "user://My Precious Save Files/" + str(_workspace_ID) + "/" + node.uuid + "_recording.tres"
			var config = ConfigFile.new()
			if config.load(recording_file) == OK:
				node.recording = config.get_value("recording", "data", {})


func generate_new_workspace_id() -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	return str(rng.randi())

func clear_holder():
	for node in holder.get_children():
		node.queue_free()
	await get_tree().process_frame  # ensure all nodes are freed
	
func populate_workspace_options():
	optionsVar.clear()
	optionsVar.add_item("New Workspace")

	var dir := DirAccess.open("user://My Precious Save Files")
	if dir:
		dir.list_dir_begin()
		var name = dir.get_next()
		while name != "":
			if dir.current_is_dir() and name != "." and name != "..":
				optionsVar.add_item(name)
			name = dir.get_next()
		dir.list_dir_end()

func _on_workspace_selected(index: int):
	save_everything()

	if index == 0:  # New Workspace
		clear_holder()
		_workspace_ID = generate_new_workspace_id()
		save_name = "My Save"
		author_name = "Unnamed Author"
		version = ProjectSettings.get_setting("application/config/version")
		game_title = ProjectSettings.get_setting("application/config/name")
		time_created = ""
		last_updated = ""
		print("Created new workspace: ", _workspace_ID)
	else:
		var selected_name = optionsVar.get_item_text(index)
		_workspace_ID = selected_name
		clear_holder()
		load_everything()
