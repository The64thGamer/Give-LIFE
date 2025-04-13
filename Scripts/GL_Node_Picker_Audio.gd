extends GL_Node_Picker

var audio_selector:OptionButton
var file_dialog:FileDialog

func _ready():
	file_dialog = get_node("FileDialog")
	audio_selector = get_node("HBox").get_node("OptionButton")
	DirAccess.make_dir_recursive_absolute(find_audio_path())
	file_dialog.file_selected.connect(_on_audio_file_selected)
	_update_audio_options()
	
func _on_audio_button_pressed():
	file_dialog.clear_filters()
	file_dialog.current_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	file_dialog.add_filter("*.wav ; WAV Audio")
	file_dialog.add_filter("*.mp3 ; MP3 Audio")
	file_dialog.add_filter("*.ogg ; OGG Audio")
	file_dialog.popup_centered()
	
func _on_audio_file_selected(path: String):
	var filename = path.get_file()
	var dest_path = find_audio_path() + "/" + filename

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_buffer(file.get_length())
		file.close()

		var save_file = FileAccess.open(dest_path, FileAccess.WRITE)
		if save_file:
			save_file.store_buffer(data)
			save_file.close()
			print("Saved audio to: ", dest_path)
			_update_audio_options(filename)  # repopulate and select this one
		else:
			push_error("Failed to write audio file.")
	else:
		push_error("Failed to read selected audio.")
		
func _update_audio_options(select_filename := ""):
	audio_selector.clear()
	var audio_files := []

	var dir := DirAccess.open(find_audio_path())
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if not dir.current_is_dir():
				audio_files.append(file)
			file = dir.get_next()
		dir.list_dir_end()

	audio_files.sort()
	for i in range(audio_files.size()):
		audio_selector.add_item(audio_files[i])
		if audio_files[i] == select_filename:
			audio_selector.select(i)
			_set_audio_path(audio_files[i])
			
func _on_audio_option_selected(index: int):
	var file = audio_selector.get_item_text(index)
	_set_audio_path(file)
	
func _set_audio_path(file: String):
	var path = find_audio_path() + "/" + file
	if mainNode and mainNode.rows.has(valueName):
		var audio = GL_AudioType.new()
		audio.value = path
		mainNode.rows[valueName]["pickValue"] = audio
		print("Audio set: ", path)
	else:
		push_error("mainNode or rows[valueName] not found.")

func find_audio_path() -> String:
	for node in get_tree().get_nodes_in_group("Node Map"):
		if node is GL_Node_Map:
			return "user://My Precious Save Files/" + node._workspace_ID + "/Audio"
	printerr("Uhhhhh")
	return ""
