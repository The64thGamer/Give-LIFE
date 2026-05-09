extends Node
class_name GL_SaveLoad

const saveFileVersion : int = 1
const _BYTES_PER_STAMP : int = 4

const _XSHW_FRAME_RATE := 60.0
const _TIME_UNITS := 1.0 / 120.0

var _xshw_bit_charts: Dictionary = {}
var _xshw_unknown_id_cache: Dictionary = {}
var _xshw_audio_data
var _xshw_signal_data
var _xshw_footer

func generate_savefile(title: String) -> String:
	var node_data = {
		"title": title,
		"author": "Anonymous",
		"timeCreated": Time.get_datetime_string_from_system(true),
		"lastUpdated": Time.get_datetime_string_from_system(true),
		"saveFileVersion": str(saveFileVersion),
		"projectVersion": ProjectSettings.get_setting("application/config/version"),
		"projectName": ProjectSettings.get_setting("application/config/name"),
		"channels": {},
		"media": {},
	}
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var save_dir = "user://My Precious Save Files/" + str(rng.randi())
	var dir_err = DirAccess.make_dir_recursive_absolute(save_dir)
	if dir_err != OK:
		push_error("Could not create save directory: " + save_dir)
		return ""
	var file = FileAccess.open(save_dir + "/data.json", FileAccess.WRITE)
	if not file:
		push_error("Could not create data.json in: " + save_dir)
		return ""
	file.store_string(JSON.stringify(node_data, "\t"))
	file.close()
	return save_dir

func load_savefile(save_dir: String) -> Dictionary:
	var file = FileAccess.open(save_dir + "/data.json", FileAccess.READ)
	if not file:
		push_error("Could not open save file at: " + save_dir)
		return {}
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		push_error("Failed to parse save file JSON: " + json.get_error_message())
		return {}
	var data: Dictionary = json.data
	_decompress_channels(data)
	return data
	
func delete_savefile(save_dir: String) -> bool:
	if not DirAccess.dir_exists_absolute(save_dir):
		push_error("Save directory does not exist: " + save_dir)
		return false
	
	var dir = DirAccess.open(save_dir)
	if not dir:
		push_error("Could not open save directory: " + save_dir)
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var err = dir.remove(file_name)
			if err != OK:
				push_error("Could not delete file: " + file_name)
				return false
		file_name = dir.get_next()
	dir.list_dir_end()
	
	var err = DirAccess.remove_absolute(save_dir)
	if err != OK:
		push_error("Could not delete save directory: " + save_dir)
		return false
	
	return true

func save_to_folder(data: Dictionary, save_dir: String) -> void:
	var file = FileAccess.open(save_dir + "/data.json", FileAccess.WRITE)
	if not file:
		push_error("Could not open save file at: " + save_dir)
		return
	var save_data: Dictionary = data.duplicate(true)
	_compress_channels(save_data)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

func copy_file_to_folder(file_path: String, save_dir: String) -> void:
	var err = DirAccess.copy_absolute(file_path, save_dir + "/" + file_path.get_file())
	if err != OK:
		push_error("Could not copy file from: " + file_path + " to: " + save_dir)

func export_save_as_zip(save_dir: String) -> void:
	var data = load_savefile(save_dir)
	if data.is_empty():
		push_error("Cannot export: Save data is invalid or missing.")
		return
	
	var default_name = data.get("title", "ExportedSave").validate_filename() + ".zip"
	
	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.zip ; ZIP Archive"]
	file_dialog.title = "Export Save as ZIP"
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.current_file = default_name
	
	file_dialog.file_selected.connect(func(dest_path: String):
		file_dialog.queue_free()
		_pack_folder_to_zip(save_dir, dest_path)
	)
	file_dialog.canceled.connect(func(): file_dialog.queue_free())
	add_child(file_dialog)
	file_dialog.popup_centered_ratio()

func _pack_folder_to_zip(source_dir: String, dest_zip: String) -> void:
	var writer = ZIPPacker.new()
	var err = writer.open(dest_zip)
	if err != OK:
		push_error("Failed to create ZIP at: " + dest_zip)
		return
		
	var dir = DirAccess.open(source_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var file_path = source_dir + "/" + file_name
				var content = FileAccess.get_file_as_bytes(file_path)
				writer.start_file(file_name)
				writer.write_file(content)
				writer.close_file()
			file_name = dir.get_next()
		writer.close()
		print("Export successful: " + dest_zip)


func import_and_load_zip(zip_path: String) -> Dictionary:
	var reader = ZIPReader.new()
	var err = reader.open(zip_path)
	if err != OK:
		push_error("Failed to open ZIP: " + zip_path)
		return {}
		
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var new_save_dir = "user://My Precious Save Files/" + str(rng.randi())
	DirAccess.make_dir_recursive_absolute(new_save_dir)
	
	var files = reader.get_files()
	for f in files:
		var content = reader.read_file(f)
		var write_path = new_save_dir + "/" + f.get_file()
		var file = FileAccess.open(write_path, FileAccess.WRITE)
		if file:
			file.store_buffer(content)
			file.close()
			
	reader.close()
	print("Imported ZIP to: " + new_save_dir)
	
	return load_savefile(new_save_dir)

func _decompress_channels(data: Dictionary) -> void:
	if not data.has("channels"):
		return
	for id in data["channels"]:
		var channel = data["channels"][id]
		if not channel.has("data"):
			continue
		
		var type = channel.get("type", GL_ChannelData.TYPE_BOOL)
		if type == GL_ChannelData.TYPE_BOOL:
			if channel["data"] is String:
				channel["data"] = _stamps_from_b64(channel["data"])
		else:
			if channel["data"] is String:
				channel["data"] = GL_ChannelData.decode_entries(type, channel["data"])

func _compress_channels(data: Dictionary) -> void:
	if not data.has("channels"):
		return
	for id in data["channels"]:
		var channel = data["channels"][id]
		if not channel.has("data"):
			continue
			
		var type = channel.get("type", GL_ChannelData.TYPE_BOOL)
		if type == GL_ChannelData.TYPE_BOOL:
			if channel["data"] is Array:
				channel["data"] = _stamps_to_b64(channel["data"])
		else:
			if channel["data"] is Array:
				channel["data"] = GL_ChannelData.encode_entries(type, channel["data"])

func _stamps_to_b64(stamps: Array) -> String:
	if stamps.is_empty():
		return ""
	var buf = PackedByteArray()
	buf.resize(stamps.size() * _BYTES_PER_STAMP)
	for i in range(stamps.size()):
		var s: int = stamps[i]
		buf[i * 4 + 0] = (s >> 24) & 0xFF
		buf[i * 4 + 1] = (s >> 16) & 0xFF
		buf[i * 4 + 2] = (s >> 8)  & 0xFF
		buf[i * 4 + 3] =  s        & 0xFF
	return Marshalls.raw_to_base64(buf)

func _stamps_from_b64(b64: String) -> Array:
	if b64 == "":
		return []
	var buf: PackedByteArray = Marshalls.base64_to_raw(b64)
	var stamps: Array = []
	for i in range(0, buf.size(), 4):
		if i + 3 >= buf.size():
			break
		var s: int = (buf[i] << 24) | (buf[i+1] << 16) | (buf[i+2] << 8) | buf[i+3]
		stamps.append(s)
	return stamps

func xshw_load_bit_charts() -> bool:
	_xshw_bit_charts.clear()
	_xshw_unknown_id_cache.clear()

	var mods_path = "res://Mods"
	if not DirAccess.dir_exists_absolute(mods_path):
		push_error("Mods directory not found: " + mods_path)
		return false

	var mods_dir = DirAccess.open(mods_path)
	if mods_dir == null:
		push_error("Failed to open Mods directory: " + mods_path)
		return false

	mods_dir.list_dir_begin()
	var mod_folder = mods_dir.get_next()
	var found_any := false
	while mod_folder != "":
		if mods_dir.current_is_dir() and mod_folder != "." and mod_folder != "..":
			var charts_path = mods_path + "/" + mod_folder + "/Mod Directory/Bit Charts"
			if DirAccess.dir_exists_absolute(charts_path):
				var charts_dir = DirAccess.open(charts_path)
				if charts_dir != null:
					charts_dir.list_dir_begin()
					var fname = charts_dir.get_next()
					while fname != "":
						if not charts_dir.current_is_dir() and fname.to_lower().ends_with(".json"):
							var file_path = charts_path + "/" + fname
							var file = FileAccess.open(file_path, FileAccess.READ)
							if file:
								var json = JSON.new()
								var parsed = json.parse_string(file.get_as_text())
								file.close()
								if typeof(parsed) == TYPE_DICTIONARY:
									var map := {}
									for k in parsed.keys():
										var s = String(k)
										if s == str(s.to_int()):
											map[s.to_int()] = String(parsed[k])
										else:
											push_warning("Skipping non-integer key in %s: %s" % [file_path, str(k)])
									_xshw_bit_charts[fname.get_basename()] = map
									found_any = true
								else:
									push_warning("Failed to parse JSON in: " + file_path)
						fname = charts_dir.get_next()
					charts_dir.list_dir_end()
		mod_folder = mods_dir.get_next()
	mods_dir.list_dir_end()

	if not found_any:
		push_warning("No bit-chart JSON files found.")
	return found_any

func xshw_convert_file(in_path: String, chart_name: String) -> String:
	if not in_path.to_lower().ends_with("shw"):
		push_error("Only .xshw/.shw files supported.")
		return ""
	if not _xshw_bit_charts.has(chart_name):
		push_error("Chart not loaded: " + chart_name)
		return ""

	var id_to_name: Dictionary = _xshw_bit_charts[chart_name]
	_xshw_unknown_id_cache.clear()
	_xshw_audio_data = null
	_xshw_signal_data = []
	_xshw_footer = null

	if not _xshw_read_shw(in_path):
		push_error("Failed to read .shw file: " + in_path)
		return ""
	if _xshw_audio_data == null or _xshw_signal_data.size() == 0:
		push_error("No audio or signal data found.")
		return ""

	# Build stamps (same as before)
	var channel_stamps: Dictionary = {}
	for id_key in id_to_name:
		channel_stamps[id_to_name[id_key]] = []

	var frame_index := 0
	var current_frame_ids := []
	var prev_state: Dictionary = {}
	for id_key in id_to_name:
		prev_state[id_to_name[id_key]] = false

	for i in range(_xshw_signal_data.size()):
		var v := int(_xshw_signal_data[i])
		if v == 0:
			var new_state: Dictionary = {}
			for id_key in id_to_name:
				new_state[id_to_name[id_key]] = false
			for seen_id in current_frame_ids:
				if id_to_name.has(seen_id):
					new_state[id_to_name[seen_id]] = true
				else:
					if not _xshw_unknown_id_cache.has(seen_id):
						_xshw_unknown_id_cache[seen_id] = true
						push_warning("Unknown ID %d in frame %d, chart '%s' — skipping." % [seen_id, frame_index, chart_name])

			var stamp_int := frame_index * 2
			for name_key in new_state:
				if prev_state.get(name_key, false) != new_state[name_key]:
					channel_stamps[name_key].append(stamp_int)

			prev_state = new_state.duplicate(true)
			current_frame_ids.clear()
			frame_index += 1
		else:
			if not current_frame_ids.has(v):
				current_frame_ids.append(v)

	if current_frame_ids.size() > 0:
		var new_state: Dictionary = {}
		for id_key in id_to_name:
			new_state[id_to_name[id_key]] = false
		for seen_id in current_frame_ids:
			if id_to_name.has(seen_id):
				new_state[id_to_name[seen_id]] = true
		var stamp_int := frame_index * 2
		for name_key in new_state:
			if prev_state.get(name_key, false) != new_state[name_key]:
				channel_stamps[name_key].append(stamp_int)
		frame_index += 1

	var eof_stamp := frame_index * 2
	for channel_key in channel_stamps:
		if channel_stamps[channel_key].size() % 2 != 0:
			channel_stamps[channel_key].append(eof_stamp)

	# Build channels directly from the bit chart — no template needed
	var channels: Dictionary = {}
	var index := 0
	for bit_id in id_to_name:
		var channel_key: String = id_to_name[bit_id]
		channels[channel_key] = {
			"type": GL_ChannelData.TYPE_BOOL,
			"data": channel_stamps.get(channel_key, []),
			"index": index,
		}
		index += 1

	var save_data := {
		"title": in_path.get_file().get_basename(),
		"author": "Converted",
		"timeCreated": Time.get_datetime_string_from_system(true),
		"lastUpdated": Time.get_datetime_string_from_system(true),
		"saveFileVersion": str(saveFileVersion),
		"projectVersion": ProjectSettings.get_setting("application/config/version"),
		"projectName": ProjectSettings.get_setting("application/config/name"),
		"channels": channels,
		"media": {},
	}

	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var save_root = "user://My Precious Save Files/" + str(rng.randi())
	DirAccess.make_dir_recursive_absolute(save_root)
	save_to_folder(save_data, save_root)

	var af = FileAccess.open(save_root + "/audio.wav", FileAccess.WRITE)
	if af:
		af.store_buffer(_xshw_audio_data)
		af.close()

	_xshw_copy_video(in_path, save_root)

	print("Conversion complete: " + save_root)
	return save_root

func xshw_convert_with_prompt(chart_name: String) -> void:
	if _xshw_bit_charts.is_empty():
		xshw_load_bit_charts()
	if not _xshw_bit_charts.has(chart_name):
		push_error("Chart not loaded: " + chart_name)
		return

	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.* ; All Files"]
	file_dialog.title = "Select a .shw file"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.file_selected.connect(func(path: String):
		file_dialog.queue_free()
		var result = xshw_convert_file(path, chart_name)
		print("Done: " + result if result != "" else "Conversion failed.")
	)
	file_dialog.canceled.connect(func(): file_dialog.queue_free())
	add_child(file_dialog)
	file_dialog.popup_centered_ratio()

func _xshw_copy_video(shw_path: String, save_root: String) -> void:
	var base = shw_path.get_file().get_basename()
	var folder = shw_path.get_base_dir()
	var dir = DirAccess.open(folder)
	if not dir:
		return
	dir.list_dir_begin()
	var fname = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.get_basename() == base and fname.to_lower().ends_with(".mp4"):
			DirAccess.copy_absolute(folder + "/" + fname, save_root + "/video.mp4")
			print("Copied video: " + fname)
			break
		fname = dir.get_next()
	dir.list_dir_end()

func _xshw_read_shw(path: String) -> bool:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open file: " + path)
		return false
	if f.get_length() < 0xDD:
		push_error("File too small/invalid: " + path)
		f.close()
		return false
	f.seek(0)
	var _header = f.get_buffer(0xDD)
	var wav_length := int(f.get_32())
	var _marker = f.get_8()
	var audio_buf = f.get_buffer(wav_length)
	var _skip = f.get_buffer(5)
	var signalfilesamples := int(f.get_32())
	var _marker2 = f.get_8()
	var signal_list := PackedInt32Array()
	for i in range(signalfilesamples):
		signal_list.append(int(f.get_32()))
	var footer_buf := PackedByteArray()
	if f.get_position() < f.get_length():
		var _term = f.get_8()
		var footer_size = int(f.get_length() - f.get_position())
		if footer_size > 0:
			footer_buf = f.get_buffer(footer_size)
	f.close()
	_xshw_audio_data = audio_buf
	_xshw_signal_data = signal_list
	_xshw_footer = footer_buf
	return true
