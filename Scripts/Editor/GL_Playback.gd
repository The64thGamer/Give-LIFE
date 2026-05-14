extends Node
class_name GL_Playback

@onready var master : GL_Master = $".."
@onready var timeline : GL_Timeline = $"../../Full Editor/Data Timeline"
@onready var audioPlayer : AudioStreamPlayer2D = $"../AudioStreamPlayer2D"

const _TIME_UNITS = 1.0 / 120.0
const AUDIO_EXTENSIONS = ["mp3", "wav", "ogg"]
const VIDEO_EXTENSIONS = ["mp4", "webm", "ogv"]
const _VIDEO_TIMESTAMP_INTERVAL = 0.1

var _lastTime : float = -1.0
var _lastTime_int : int = -1
var _isScrubbing : bool = false
var _scrubTimer : float = 0.0
var _media_state: Dictionary = {}
var _media_timers: Dictionary = {}

const _SCRUB_SEEK_INTERVAL = 0.08
var _scrub_seek_timer: float = 0.0
var _scrub_pending_time: float = -1.0

var _dispatch: Array = []
var _dispatch_valid: bool = false

var _group_node_cache: Dictionary = {} 

func refresh_animatables() -> void:
	_group_node_cache.clear()
	if is_instance_valid(get_tree()):
		var animatables = get_tree().get_nodes_in_group("Animatable")
		for node in animatables:
			for group in node.get_groups():
				if group == "Animatable":
					continue
				if not _group_node_cache.has(group):
					_group_node_cache[group] = []
				_group_node_cache[group].append(node)

func _get_group_nodes(group: String) -> Array:
	return _group_node_cache.get(group, [])

func invalidate_channel_cache(channel_id: String) -> void:
	_lastTime_int = -1

func invalidate_all_cache() -> void:
	_dispatch_valid = false
	_lastTime_int = -1

func prime_group_cache() -> void:
	_build_dispatch_table()

func _build_dispatch_table() -> void:
	_dispatch.clear()
	_dispatch_valid = false

	if master.currentlyLoadedPath == "":
		return

	var channels = master.currentlyLoadedFile["channels"]
	for key in channels:
		var pipe = key.find("|")
		if pipe == -1:
			continue
		var ch = channels[key]
		var type = GL_ChannelData.get_type(ch)
		var group = key.left(pipe)
		var signal_key = key.substr(pipe + 1)
		_dispatch.append({
			"id": key,
			"type": type,
			"group": group,
			"signal_key": signal_key
		})

	_dispatch_valid = true


func _physics_process(delta: float) -> void:
	if master.currentlyLoadedPath == "":
		return

	if not _dispatch_valid:
		_build_dispatch_table()

	var t_int = int(timeline.timeCurrent / _TIME_UNITS)
	var time_changed = (t_int != _lastTime_int)

	if time_changed:
		_lastTime_int = t_int
		var channels = master.currentlyLoadedFile["channels"]

		for rec in _dispatch:
			var id: String    = rec["id"]
			var type: String  = rec["type"]
			var group: String = rec["group"]
			var nodes: Array  = _get_group_nodes(group)

			if nodes.is_empty():
				continue

			var ch   = channels[id]
			var data = ch["data"]

			if type == GL_ChannelData.TYPE_VIDEO or type == GL_ChannelData.TYPE_AUDIO:
				_process_media_channel(rec, data, delta, t_int)
			else:
				var state = _get_state_for_type(type, data, id, t_int)
				var signal_key: String = rec["signal_key"]
				for node in nodes:
					if is_instance_valid(node):
						node._sent_signals(signal_key, state)

	_process_audio(delta, time_changed)


func _process_media_channel(rec: Dictionary, data, delta: float, t_int: int) -> void:
	var entries: Array = data
	if entries.is_empty():
		return

	var channel_id: String = rec["id"]

	var active_entry: Dictionary = {}
	var lo = 0
	var hi = entries.size() - 1
	while lo <= hi:
		var mid = (lo + hi) / 2
		if entries[mid]["time"] <= t_int:
			active_entry = entries[mid]
			lo = mid + 1
		else:
			hi = mid - 1

	if active_entry.is_empty():
		return

	var prev = _media_state.get(channel_id, {})
	var entry_changed = prev.get("entry_time", -1) != active_entry["time"]

	if entry_changed:
		_media_state[channel_id] = {
			"file": active_entry.get("file", "null"),
			"offset": active_entry.get("offset", 0.0),
			"stamp_time": GL_ChannelData.int_to_time(active_entry["time"]),
			"entry_time": active_entry["time"]
		}
		_media_timers[channel_id] = _VIDEO_TIMESTAMP_INTERVAL

	_media_timers[channel_id] = _media_timers.get(channel_id, 0.0) + delta

	if _media_timers[channel_id] >= _VIDEO_TIMESTAMP_INTERVAL:
		_media_timers[channel_id] = 0.0

		var state = _media_state[channel_id]
		var file = state["file"]
		var offset = state["offset"]
		var stamp_time = state["stamp_time"]

		var path_to_send = null
		var time_to_send = 0.0

		if file != "null":
			path_to_send = master.currentlyLoadedPath.path_join(file)
			time_to_send = max(offset + (timeline.timeCurrent - stamp_time), 0.0)

		var signal_key: String = rec["signal_key"]
		var nodes: Array = _get_group_nodes(rec["group"])
		for node in nodes:
			node._sent_signals(signal_key, path_to_send)
			node._sent_signals("Current Time", time_to_send)


func _send_null_media_signals() -> void:
	if not master or master.currentlyLoadedPath == "":
		return
	for rec in _dispatch:
		if rec["type"] != GL_ChannelData.TYPE_VIDEO and rec["type"] != GL_ChannelData.TYPE_AUDIO:
			continue
		var nodes = _get_group_nodes(rec["group"])
		for node in nodes:
			node._sent_signals(rec["signal_key"], null)
			node._sent_signals("Current Time", 0.0)


func clean_sweep() -> void:
	if master.currentlyLoadedPath == "":
		return
	var channels = master.currentlyLoadedFile["channels"]
	for rec in _dispatch:
		var id: String = rec["id"]
		var data = channels[id]["data"]
		var is_empty = (data is Array and data.is_empty()) or (data is String and data == "")
		if not is_empty:
			continue
		var nodes = _get_group_nodes(rec["group"])
		for node in nodes:
			node._sent_signals(rec["signal_key"], 0.0)

func _get_state_for_type(type: String, data, channel_id: String, t_int: int):
	match type:
		GL_ChannelData.TYPE_BOOL:
			var stamps: Array = data
			if timeline.activeEdit.has(channel_id):
				stamps = _merge_active_edit(stamps, channel_id)
			if stamps.is_empty():
				return false
			return get_bool_state_at_time(stamps, t_int)

		GL_ChannelData.TYPE_FLOAT:
			return GL_ChannelData.get_float_at_time(data, t_int)

		GL_ChannelData.TYPE_COLOR:
			if data.is_empty():
				return Color.BLACK
			var result_color: Color = data[0]["color"]
			var lo = 0
			var hi = data.size() - 1
			while lo <= hi:
				var mid = (lo + hi) / 2
				if data[mid]["time"] <= t_int:
					result_color = data[mid]["color"]
					lo = mid + 1
				else:
					hi = mid - 1
			return result_color

		_:
			return 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_send_null_media_signals()


func _seed_default_media() -> void:
	if master.currentlyLoadedPath == "":
		return
	var default_audio = _find_default_file(AUDIO_EXTENSIONS)
	var default_video = _find_default_file(VIDEO_EXTENSIONS)
	for key in master.currentlyLoadedFile["channels"]:
		var ch = master.currentlyLoadedFile["channels"][key]
		var type = GL_ChannelData.get_type(ch)
		if type != GL_ChannelData.TYPE_AUDIO and type != GL_ChannelData.TYPE_VIDEO:
			continue
		var data = ch.get("data", "")
		var is_empty = (data is String and data == "") or (data is Array and data.is_empty()) or data == null
		if not is_empty:
			continue
		var default_file: String = ""
		if type == GL_ChannelData.TYPE_AUDIO and default_audio != "":
			default_file = default_audio
		elif type == GL_ChannelData.TYPE_VIDEO and default_video != "":
			default_file = default_video
		if default_file == "":
			continue
		var entry = { "time": 0, "file": default_file, "offset": 0.0 }
		ch["data"] = GL_ChannelData.encode_entries(type, [entry])

func _find_default_file(extensions: Array) -> String:
	var folder = master.currentlyLoadedPath
	var dir = DirAccess.open(ProjectSettings.globalize_path(folder))
	if not dir:
		dir = DirAccess.open(folder)
	if not dir:
		return ""
	dir.list_dir_begin()
	var f = dir.get_next()
	while f != "":
		if not dir.current_is_dir():
			if f.get_extension().to_lower() in extensions:
				dir.list_dir_end()
				return f
		f = dir.get_next()
	dir.list_dir_end()
	return ""

func reload_audio() -> void:
	audioPlayer.stop()
	audioPlayer.stream = null
	if master.currentlyLoadedPath == "":
		return
	var default_audio = _find_default_file(AUDIO_EXTENSIONS)
	if default_audio != "":
		var full_path = master.currentlyLoadedPath.path_join(default_audio)
		var stream = _load_audio_stream(full_path, default_audio.get_extension().to_lower())
		if stream:
			audioPlayer.stream = stream
			print("Audio loaded: ", default_audio)
	_seed_default_media()

func _process_audio(delta: float, time_changed: bool) -> void:
	if not audioPlayer.stream:
		return
	var current = timeline.timeCurrent
	var playing = timeline.playing

	if playing:
		_isScrubbing = false
		_scrubTimer = 0.0
		_scrub_seek_timer = 0.0
		_scrub_pending_time = -1.0
		if not audioPlayer.playing:
			audioPlayer.play(current)
		else:
			if abs(audioPlayer.get_playback_position() - current) > 0.2:
				audioPlayer.seek(current)
	else:
		if audioPlayer.playing and not _isScrubbing:
			audioPlayer.stop()

		if time_changed:
			_isScrubbing = true
			_scrubTimer = 0.15
			_scrub_pending_time = current
			_scrub_seek_timer += delta

			if _scrub_seek_timer >= _SCRUB_SEEK_INTERVAL:
				_scrub_seek_timer = 0.0
				if not audioPlayer.playing:
					audioPlayer.play(_scrub_pending_time)
				else:
					audioPlayer.seek(_scrub_pending_time)
				_scrub_pending_time = -1.0
		else:
			_scrub_seek_timer += delta

		if _isScrubbing:
			_scrubTimer -= delta
			if _scrubTimer <= 0.0:
				_isScrubbing = false
				_scrub_seek_timer = 0.0
				_scrub_pending_time = -1.0
				audioPlayer.stop()

	_lastTime = current

func _load_audio_stream(path: String, ext: String) -> AudioStream:
	var absolute_path = ProjectSettings.globalize_path(path)
	match ext:
		"mp3":
			return AudioStreamMP3.load_from_file(absolute_path)
		"wav":
			return AudioStreamWAV.load_from_file(absolute_path)
		"ogg":
			return AudioStreamOggVorbis.load_from_file(absolute_path)
	return null

func get_bool_state_at_time(stamps: Array, t_int_or_time) -> bool:
	var current_time_int: int
	if t_int_or_time is float:
		current_time_int = int(t_int_or_time / _TIME_UNITS)
	else:
		current_time_int = t_int_or_time
	var lo: int = 0
	var hi: int = stamps.size() - 1
	var result_idx: int = -1
	while lo <= hi:
		var mid: int = (lo + hi) / 2
		if stamps[mid] <= current_time_int:
			result_idx = mid
			lo = mid + 1
		else:
			hi = mid - 1
	if result_idx == -1:
		return false
	return result_idx % 2 == 0

func _merge_active_edit(base: Array, channel_id: String) -> Array:
	var stamps = base.duplicate()
	var edit = timeline.activeEdit[channel_id]
	var range_start = min(edit["start"], timeline.timeCurrent)
	var range_end = max(edit["start"], timeline.timeCurrent)
	if range_end - range_start < (1.0 / 120.0):
		range_end = range_start + (1.0 / 120.0)
	var start_int = timeline.time_to_int(range_start)
	var end_int = timeline.time_to_int(range_end)
	var insert_idx = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] >= start_int:
			insert_idx = i
			break
	var state_before: bool = insert_idx % 2 == 0
	var end_idx = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] > end_int:
			end_idx = i
			break
	var state_after: bool = end_idx % 2 == 0
	for i in range(stamps.size() - 1, -1, -1):
		if stamps[i] >= start_int and stamps[i] <= end_int:
			stamps.remove_at(i)
	var ins = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] >= start_int:
			ins = i
			break
	if state_before:
		stamps.insert(ins, start_int)
		ins += 1
	if not state_after:
		stamps.insert(ins, end_int)
	return stamps
