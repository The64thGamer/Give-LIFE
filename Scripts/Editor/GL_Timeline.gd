extends Control
class_name GL_Timeline
@onready var master : GL_Master= $"../../Master"
@onready var timelineBox : VBoxContainer = $MarginContainer/TimelineBox
@onready var playButton : Button = $"../TimeManager/HBoxContainer/Play Button"
@onready var timeStartText : Label = $"../TimeManager/MarginContainer/StartTime"
@onready var timeEndText : Label = $"../TimeManager/MarginContainer/EndTime"
@onready var timelinePositionBar : ColorRect = $TimelineBar
@onready var currentTimeText : Label = $TimelineBar/currentTime

var channelPrefab = preload("res://New New/Prefabs/Channel.tscn")
var scrolledIndex = 0
var timeStart = 0.0
var timeEnd = 10.0
var timeCurrent = timeStart
var playing = false
var channelXs = 0
var channelWidths = 1920
var activeEdit: Dictionary = {}
var channelBinds: Dictionary = {}
var _last_axis_values: Dictionary = {}

const zoomMultOut = 1.1
const zoomMultIn = 0.9
const zoomMin = 0.1
const zoomMax = 60
const panAmount = 0.1
const MAX_VISIBLE_CHANNELS = 10

var _timeline_dirty: bool = false
var _last_start_text: String = ""
var _last_end_text: String = ""
var _scrub_handled_this_frame: bool = false
var channelControllerBinds: Dictionary = {} 
var _last_axis_write_time: Dictionary = {}
var controller_poll_rate: float = 1.0 / 10.0 
var _controller_poll_accum: float = 0.0
const AXIS_COMPONENT_ANGLE = "angle"
const AXIS_ANGLE_DEADZONE_MAG  = 0.5
const AXIS_ANGLE_DEAD_DEG_LOW  = 10.0
const AXIS_ANGLE_DEAD_DEG_HIGH = 10.0
const MMB_ZOOM_SPEED = 0.01
const MMB_VELOCITY_SMOOTH = 0.15

var _mmb_held: bool = false
var _mmb_velocity: Vector2 = Vector2.ZERO

const CONTROLLER_BUTTONS = [
	JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y,
	JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER,
	JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK,
	JOY_BUTTON_BACK, JOY_BUTTON_START,
	JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT
]

const CONTROLLER_AXES = [
	JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y,
	JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y,
	JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT
]

const AXIS_COMPONENTS = {
	JOY_AXIS_LEFT_X:        ["positive", "negative", "magnitude"],
	JOY_AXIS_LEFT_Y:        ["positive", "negative", "magnitude"],
	JOY_AXIS_RIGHT_X:       ["positive", "negative", "magnitude"],
	JOY_AXIS_RIGHT_Y:       ["positive", "negative", "magnitude"],
	JOY_AXIS_TRIGGER_LEFT:  ["value"],
	JOY_AXIS_TRIGGER_RIGHT: ["value"],
}

func _mark_dirty() -> void:
	_timeline_dirty = true

func startEdit(channel_id: String, start_time: float, value: bool) -> void:
	activeEdit[channel_id] = {"start": start_time, "value": value}
	_mark_dirty()

func endEdit(channel_id: String) -> void:
	activeEdit.erase(channel_id)
	_mark_dirty()

func getDataForChannel(channel_id: String) -> Array:
	var channels = master.currentlyLoadedFile.get("channels", {})
	if not channels.has(channel_id):
		return []
	var data = channels[channel_id].get("data", [])
	return data.duplicate() if data is Array else []

func time_to_int(t: float) -> int:
	return int(t / (1.0 / 120.0))

func format_time(seconds: float) -> String:
	var h = int(seconds) / 3600
	var m = (int(seconds) % 3600) / 60
	var s = int(seconds) % 60
	return "%02d:%02d:%02d" % [h, m, s]

func setTimeFromTimeline(local_mouse_x: float, width: float) -> void:
	var t_ratio = clamp(local_mouse_x / width, 0.0, 1.0)
	
	timeCurrent = timeStart + t_ratio * (timeEnd - timeStart)
	
	currentTimeText.text = format_time(timeCurrent)
	_scrub_handled_this_frame = true

func _process(delta: float) -> void:
	_poll_controller_binds(delta)
	_scrub_handled_this_frame = false
	if playing:
		setCurrentTime(delta)

	var t_range = timeEnd - timeStart
	if t_range > 0:
		var t_ratio = (timeCurrent - timeStart) / t_range
		
		var first_chan = _get_first_visible_channel()
		if first_chan:
			var data_area = first_chan.channelTimeline
			
			var start_gx = data_area.global_position.x
			var width_gx = data_area.size.x * data_area.get_global_transform().get_scale().x
			
			timelinePositionBar.global_position.x = start_gx + (t_ratio * width_gx)
			
			if activeEdit.size() > 0:
				for child in timelineBox.get_children():
					if child is GL_Channel and activeEdit.has(child.id):
						child.sync_preview_to_scrubber(t_ratio * data_area.size.x)

func _get_first_visible_channel() -> GL_Channel:
	for child in timelineBox.get_children():
		if child is GL_Channel and child.visible:
			return child
	return null
					
func _physics_process(delta: float) -> void:
	var s_text = format_time(timeStart)
	if s_text != _last_start_text:
		_last_start_text = s_text
		timeStartText.text = s_text

	var e_text = format_time(timeEnd)
	if e_text != _last_end_text:
		_last_end_text = e_text
		timeEndText.text = e_text

	if _timeline_dirty:
		_timeline_dirty = false
		repaintTimeline()
		
func setCurrentTime(delta: float) -> void:
	timeCurrent += delta
	
func togglePlayback():
	playing = !playing
	if playing:
		var playback = _get_playback()
		if playback:
			playback.prime_group_cache()

func _get_playback() -> GL_Playback:
	return master.get_node_or_null("GL_Playback")

func _input(event: InputEvent) -> void:
	if master.currentlyLoadedPath == "":
		return
	if is_visible_in_tree():
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				if event.ctrl_pressed:
					zoom(false)
				elif event.shift_pressed:
					pan(true)
				else:
					scroll(false)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if event.ctrl_pressed:
					zoom(true)
				elif event.shift_pressed:
					pan(false)
				else:
					scroll(true)

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
			_mmb_held = event.pressed
			if not event.pressed:
				_mmb_velocity = Vector2.ZERO

		if event is InputEventMouseMotion and _mmb_held:
			_mmb_velocity = _mmb_velocity.lerp(event.relative, MMB_VELOCITY_SMOOTH)
			var vel_norm = _mmb_velocity.normalized()
			var vertical_weight = clamp(abs(vel_norm.y) - abs(vel_norm.x), 0.0, 1.0)
			vertical_weight = pow(vertical_weight, 2.0)
			var pan_weight = 1.0 - vertical_weight

			var vp_size = get_viewport().get_visible_rect().size
			var t_range = timeEnd - timeStart

			if pan_weight > 0.0:
				var pan_offset = -(event.relative.x / vp_size.x) * t_range * pan_weight
				timeStart += pan_offset
				timeEnd += pan_offset
				if timeStart < 0.0:
					timeEnd += -timeStart
					timeStart = 0.0

			if vertical_weight > 0.0:
				var zoom_factor = 1.0 + event.relative.y * MMB_ZOOM_SPEED * vertical_weight
				zoom_factor = clamp(zoom_factor, 0.5, 2.0)
				var mid = (timeStart + timeEnd) / 2.0
				var new_dist = clamp(t_range * zoom_factor, zoomMin, zoomMax)
				timeStart = mid - new_dist / 2.0
				timeEnd = mid + new_dist / 2.0
				if timeStart < 0.0:
					timeEnd += -timeStart
					timeStart = 0.0

			_last_start_text = ""
			_last_end_text = ""
			_mark_dirty()

	if event.is_action_pressed("Toggle Play"):
		togglePlayback()

	if event is InputEventJoypadButton:
		for channel_id in channelControllerBinds:
			var bind = channelControllerBinds[channel_id]
			if bind["type"] != "button":
				continue
			if event.button_index != bind["input"]:
				continue
			var type = _resolve_channel_type(channel_id)
			master.ensure_channel_exists(channel_id)
			if event.pressed:
				match type:
					GL_ChannelData.TYPE_BOOL:
						startEdit(channel_id, timeCurrent, true)
					GL_ChannelData.TYPE_FLOAT:
						startEdit(channel_id, timeCurrent, true)
					GL_ChannelData.TYPE_COLOR, GL_ChannelData.TYPE_AUDIO, GL_ChannelData.TYPE_VIDEO, \
					GL_ChannelData.TYPE_IMAGE, GL_ChannelData.TYPE_STRING:
						_commit_event(channel_id, type)
			else:
				match type:
					GL_ChannelData.TYPE_BOOL:
						_commit_edit(channel_id)
					GL_ChannelData.TYPE_FLOAT:
						_commit_float(channel_id)

	if event is InputEventKey:
		var all_channel_ids: Array = []
		for group in master.scene_groups:
			for channel_id in master.scene_groups[group]:
				all_channel_ids.append(channel_id)
		for channel_id in master.currentlyLoadedFile.get("channels", {}):
			if not all_channel_ids.has(channel_id):
				all_channel_ids.append(channel_id)

		for channel_id in all_channel_ids:
			var bind = channelBinds.get(channel_id, null)
			if bind == null:
				continue
			if event.keycode != bind:
				continue

			var type: String = GL_ChannelData.TYPE_BOOL
			var pipe = channel_id.find("|")
			var group = channel_id.left(pipe) if pipe != -1 else ""
			if master.currentlyLoadedFile["channels"].has(channel_id):
				type = GL_ChannelData.get_type(master.currentlyLoadedFile["channels"][channel_id])
			else:
				var sg_entry = master.scene_groups.get(group, {}).get(channel_id, {})
				if sg_entry.has("type"):
					type = sg_entry["type"]

			if event.pressed and not event.echo:
				master.ensure_channel_exists(channel_id)
				match type:
					GL_ChannelData.TYPE_BOOL:
						startEdit(channel_id, timeCurrent, true)
					GL_ChannelData.TYPE_FLOAT:
						startEdit(channel_id, timeCurrent, true)
					GL_ChannelData.TYPE_COLOR, GL_ChannelData.TYPE_AUDIO, GL_ChannelData.TYPE_VIDEO, \
					GL_ChannelData.TYPE_IMAGE, GL_ChannelData.TYPE_STRING:
						_commit_event(channel_id, type)

			elif not event.pressed:
				match type:
					GL_ChannelData.TYPE_BOOL:
						_commit_edit(channel_id)
					GL_ChannelData.TYPE_FLOAT:
						_commit_float(channel_id)

func _resolve_channel_type(channel_id: String) -> String:
	var pipe = channel_id.find("|")
	var group = channel_id.left(pipe) if pipe != -1 else ""
	if master.currentlyLoadedFile["channels"].has(channel_id):
		return GL_ChannelData.get_type(master.currentlyLoadedFile["channels"][channel_id])
	var sg_entry = master.scene_groups.get(group, {}).get(channel_id, {})
	if sg_entry.has("type"):
		return sg_entry["type"]
	return GL_ChannelData.TYPE_BOOL

func _commit_edit(channel_id: String) -> void:
	if not activeEdit.has(channel_id):
		return
	var edit_start = activeEdit[channel_id]["start"]
	var range_start = min(edit_start, timeCurrent)
	var range_end = max(edit_start, timeCurrent)
	if range_end - range_start < (1.0 / 120.0):
		range_end = range_start + (1.0 / 120.0)

	var raw = master.currentlyLoadedFile["channels"][channel_id]["data"]
	var stamps: Array = raw if raw is Array else []
	var start_int = time_to_int(range_start)
	var end_int = time_to_int(range_end)

	var insert_idx = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] >= start_int:
			insert_idx = i
			break
	var state_before: bool = insert_idx % 2 != 0
	var end_idx = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] > end_int:
			end_idx = i
			break
	var state_after: bool = end_idx % 2 != 0
	for i in range(stamps.size() - 1, -1, -1):
		if stamps[i] >= start_int and stamps[i] <= end_int:
			stamps.remove_at(i)

	var ins = stamps.size()
	for i in range(stamps.size()):
		if stamps[i] >= start_int:
			ins = i
			break

	if not state_before:
		stamps.insert(ins, start_int)
		ins += 1
	if not state_after:
		stamps.insert(ins, end_int)

	master.currentlyLoadedFile["channels"][channel_id]["data"] = stamps
	call_deferred("endEdit", channel_id)
	_mark_dirty()

func _commit_float(channel_id: String) -> void:
	if not activeEdit.has(channel_id):
		return

	var edit_start = activeEdit[channel_id]["start"]
	var ch_data = master.currentlyLoadedFile["channels"][channel_id]
	
	# FIX: Get the live array directly, no decoding!
	var entries: Array = ch_data.get("data", [])

	var start_int = time_to_int(edit_start)
	var last_value = GL_ChannelData.get_float_at_time(entries, start_int - 1)
	var release_value = clamp(1.0 - last_value, 0.0, 1.0)

	var release_int = time_to_int(timeCurrent)
	if release_int <= start_int:
		release_int = start_int + 1

	entries = GL_ChannelData.insert_entry(entries, { "time": start_int, "value": last_value })
	entries = GL_ChannelData.insert_entry(entries, { "time": release_int, "value": release_value })

	master.currentlyLoadedFile["channels"][channel_id]["data"] = entries
	_invalidate_playback_cache(channel_id)
	call_deferred("endEdit", channel_id)
	_mark_dirty()

func _commit_event(channel_id: String, type: String) -> void:
	var ch_data = master.currentlyLoadedFile["channels"][channel_id]
	
	var entries: Array = ch_data.get("data", [])
	var t_int = time_to_int(timeCurrent)

	var entry: Dictionary
	match type:
		GL_ChannelData.TYPE_COLOR:
			entry = { "time": t_int, "color": Color.WHITE }
		GL_ChannelData.TYPE_AUDIO, GL_ChannelData.TYPE_VIDEO:
			entry = { "time": t_int, "file": "null", "offset": 0.0 }
		GL_ChannelData.TYPE_IMAGE:
			entry = { "time": t_int, "file": "null" }
		GL_ChannelData.TYPE_STRING:
			entry = { "time": t_int, "value": "null" }

	entries = GL_ChannelData.insert_entry(entries, entry)
	
	master.currentlyLoadedFile["channels"][channel_id]["data"] = entries
	_invalidate_playback_cache(channel_id)
	_mark_dirty()
	
func _invalidate_playback_cache(channel_id: String) -> void:
	var playback = _get_playback()
	if playback:
		playback.invalidate_channel_cache(channel_id)

func updateTimelineBarX() -> void:
	if playing:
		var t = (timeCurrent - timeStart) / (timeEnd - timeStart)
		timelinePositionBar.position.x = channelXs + t * channelWidths
	else:
		timelinePositionBar.position.x = get_viewport().get_mouse_position().x

func zoom(out: bool):
	var mid = (timeStart + timeEnd) / 2.0
	var dist = timeEnd - timeStart
	var new_dist = dist * (zoomMultOut if out else zoomMultIn)
	new_dist = clamp(new_dist, zoomMin, zoomMax)
	timeStart = mid - new_dist / 2.0
	timeEnd = mid + new_dist / 2.0
	if timeStart < 0.0:
		timeEnd += -timeStart
		timeStart = 0.0
	_last_start_text = ""   
	_last_end_text = ""
	_mark_dirty()

func pan(left: bool):
	var dist = timeEnd - timeStart
	var offset = dist * panAmount * (-1.0 if left else 1.0)
	timeStart += offset
	timeEnd += offset
	if timeStart < 0.0:
		timeEnd += -timeStart
		timeStart = 0.0
	_last_start_text = ""
	_last_end_text = ""
	_mark_dirty()

func scroll(down: bool):
	if master.currentlyLoadedPath == "":
		return
	var total = _get_displayed_keys().size()
	if down:
		if scrolledIndex < total - 1:
			scrolledIndex += 1
	else:
		if scrolledIndex > 0:
			scrolledIndex -= 1
	_reassign_channel_slots()

func _get_displayed_keys() -> Array:
	if master.displayed_group == "":
		return []
	var group = master.scene_groups.get(master.displayed_group, {})
	var keys = group.keys()
	keys.sort()
	return keys

func _get_channel_slots() -> Array:
	var slots = []
	for child in timelineBox.get_children():
		if child.name != "CreateChannel":
			slots.append(child)
	return slots

func _reassign_channel_slots() -> void:
	if master.currentlyLoadedPath == "":
		return

	await get_tree().process_frame

	var displayed_keys = _get_displayed_keys()
	var slots = _get_channel_slots()

	var resolve_color = func(key: String) -> String:
		var pipe = key.find("|")
		var group = key.left(pipe) if pipe != -1 else ""
		var sg = master.scene_groups.get(group, {}).get(key, {})
		if sg.has("color"):
			return sg["color"]
		if master.currentlyLoadedFile["channels"].has(key):
			return master.currentlyLoadedFile["channels"][key].get("color", "")
		return ""

	for i in range(slots.size()):
		var data_index = scrolledIndex + i
		var slot : GL_Channel = slots[i]
		if data_index < displayed_keys.size():
			var key = displayed_keys[data_index]
			slot.id = key
			var color_hex = resolve_color.call(key)
			if color_hex != "":
				var r = ("0x" + color_hex.substr(0, 2)).hex_to_int() / 255.0
				var g = ("0x" + color_hex.substr(2, 2)).hex_to_int() / 255.0
				var b = ("0x" + color_hex.substr(4, 2)).hex_to_int() / 255.0
				slot.color = Color(r, g, b)
			slot.visible = true
			slot.start()
			slot.renderBits()
		else:
			slot.visible = false

func repaintTimeline() -> void:
	for child in timelineBox.get_children():
		if child.name != "CreateChannel" and child.visible:
			(child as GL_Channel).renderBits()

func _ready() -> void:
	reload_timeline()

func reload_timeline() -> void:
	for child in timelineBox.get_children():
		child.queue_free()

	if master.currentlyLoadedPath == "":
		return

	var total = _get_displayed_keys().size()

	if scrolledIndex >= total:
		scrolledIndex = max(0, total - 1)

	var slots_needed = min(MAX_VISIBLE_CHANNELS, total)
	for i in range(slots_needed):
		var channelBox : GL_Channel = channelPrefab.instantiate()
		timelineBox.add_child(channelBox)

	call_deferred("_prime_playback_deferred")
	_reassign_channel_slots()

func clear_group_binds() -> void:
	for channel_id in _get_displayed_keys():
		channelBinds.erase(channel_id)
		channelControllerBinds.erase(channel_id)
	for child in timelineBox.get_children():
		if child is GL_Channel:
			child.updateBindLabel()
	get_tree().get_first_node_in_group("AnimatableImporter").refresh_bind_alerts()

func on_group_changed() -> void:
	scrolledIndex = 0
	reload_timeline()
	call_deferred("_reassign_channel_slots")

func _prime_playback_deferred() -> void:
	var playback = _get_playback()
	if playback:
		playback.prime_group_cache()

func set_controller_bind(channel_id: String, bind: Dictionary) -> void:
	channelControllerBinds[channel_id] = bind
	for child in timelineBox.get_children():
		if child is GL_Channel and child.id == channel_id:
			child.updateBindLabel()
			break

func clear_controller_bind(channel_id: String) -> void:
	channelControllerBinds.erase(channel_id)

func clear_channel(channel_id: String) -> void:
	if not master.currentlyLoadedFile["channels"].has(channel_id):
		return
	var type = GL_ChannelData.get_type(master.currentlyLoadedFile["channels"][channel_id])
	master.currentlyLoadedFile["channels"][channel_id]["data"] = []
	activeEdit.erase(channel_id)
	_invalidate_playback_cache(channel_id)
	_mark_dirty()

func _get_axis_value(bind: Dictionary) -> float:
	var axis: int = bind["input"]
	var component: String = bind["component"]
	var device: int = 0

	var paired = {
		JOY_AXIS_LEFT_X:  JOY_AXIS_LEFT_Y,
		JOY_AXIS_LEFT_Y:  JOY_AXIS_LEFT_X,
		JOY_AXIS_RIGHT_X: JOY_AXIS_RIGHT_Y,
		JOY_AXIS_RIGHT_Y: JOY_AXIS_RIGHT_X,
	}

	match component:
		"value":
			return Input.get_joy_axis(device, axis)
		"positive":
			return max(0.0, Input.get_joy_axis(device, axis))
		"negative":
			return max(0.0, -Input.get_joy_axis(device, axis))
		"magnitude":
			return abs(Input.get_joy_axis(device, axis))
		"magnitude_2d":
			if paired.has(axis):
				return Vector2(
					Input.get_joy_axis(device, axis),
					Input.get_joy_axis(device, paired[axis])
				).length()
			return abs(Input.get_joy_axis(device, axis))
		"angle":
			if not paired.has(axis):
				return 0.0
			var x_axis = axis if axis in [JOY_AXIS_LEFT_X, JOY_AXIS_RIGHT_X] else paired[axis]
			var y_axis = axis if axis in [JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_Y] else paired[axis]
			var x = Input.get_joy_axis(device, x_axis)
			var y = Input.get_joy_axis(device, y_axis)
			if Vector2(x, y).length() < AXIS_ANGLE_DEADZONE_MAG:
				return 0.0
			var deg = fmod(rad_to_deg(atan2(-y, x)) - 180.0 + 360.0, 360.0)
			if deg <= AXIS_ANGLE_DEAD_DEG_LOW:
				return 0.0
			if deg >= 360.0 - AXIS_ANGLE_DEAD_DEG_HIGH:
				return 1.0
			return (deg - AXIS_ANGLE_DEAD_DEG_LOW) / (360.0 - AXIS_ANGLE_DEAD_DEG_LOW - AXIS_ANGLE_DEAD_DEG_HIGH)
	return 0.0

func convert_channel_type(channel_id: String, to_type: String) -> void:
	if not master.currentlyLoadedFile["channels"].has(channel_id):
		return
	var current_type = GL_ChannelData.get_type(master.currentlyLoadedFile["channels"][channel_id])
	if current_type == to_type:
		return
	master.currentlyLoadedFile["channels"][channel_id]["type"] = to_type
	master.currentlyLoadedFile["channels"][channel_id]["data"] = []
	activeEdit.erase(channel_id)
	_invalidate_playback_cache(channel_id)
	_mark_dirty()

func get_channel_type(channel_id: String) -> String:
	if not master.currentlyLoadedFile["channels"].has(channel_id):
		return ""
	return GL_ChannelData.get_type(master.currentlyLoadedFile["channels"][channel_id])

func clear_channel_bind(channel_id: String) -> void:
	channelBinds.erase(channel_id)
	channelControllerBinds.erase(channel_id)
	for child in timelineBox.get_children():
		if child is GL_Channel and child.id == channel_id:
			child.updateBindLabel()
			break

func _poll_controller_binds(delta: float) -> void:
	if master.currentlyLoadedPath == "":
		return
	if not playing:
		return
	_controller_poll_accum += delta

	var poll_ready = _controller_poll_accum >= controller_poll_rate
	if poll_ready:
		_controller_poll_accum = 0.0

	var did_change := false

	for channel_id in channelControllerBinds:
		var bind: Dictionary = channelControllerBinds[channel_id]
		if bind["type"] != "axis":
			continue
		var value = _get_axis_value(bind)
		var last = _last_axis_values.get(channel_id, -INF)
		if value == last:
			continue
		var last_write_age = _last_axis_write_time.get(channel_id, -INF)
		var time_since_write = Time.get_ticks_msec() / 1000.0 - last_write_age
		if not poll_ready and time_since_write < controller_poll_rate:
			continue
		_last_axis_values[channel_id] = value
		_last_axis_write_time[channel_id] = Time.get_ticks_msec() / 1000.0
		var type = get_channel_type(channel_id)
		match type:
			GL_ChannelData.TYPE_FLOAT:
				master.ensure_channel_exists(channel_id)
				var ch = master.currentlyLoadedFile["channels"][channel_id]
				var data: Array = ch.get("data", [])
				if last != -INF:
					var anchor_int = time_to_int(timeCurrent) - 1
					var current_int = time_to_int(timeCurrent)
					if anchor_int > current_int - 1:
						anchor_int = current_int - 1
					if anchor_int >= 0:
						data = GL_ChannelData.insert_entry(data, { "time": anchor_int, "value": last })
				data = GL_ChannelData.insert_entry(data, { "time": time_to_int(timeCurrent), "value": value })
				ch["data"] = data
				_invalidate_playback_cache(channel_id)
				did_change = true
			GL_ChannelData.TYPE_BOOL:
				var pressed = value > 0.2
				var was_pressed = last > 0.2
				if pressed == was_pressed:
					continue
				if pressed:
					startEdit(channel_id, timeCurrent, true)
				else:
					_commit_edit(channel_id)
				did_change = true
			_:
				continue

	if did_change:
		_mark_dirty()
