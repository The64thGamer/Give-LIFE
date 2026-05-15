extends RefCounted
class_name GL_ChannelData

# Channel type constants
const TYPE_BOOL   = "bool"
const TYPE_FLOAT  = "float"
const TYPE_COLOR  = "color"
const TYPE_AUDIO  = "audio"
const TYPE_VIDEO  = "video"
const TYPE_IMAGE  = "image"
const TYPE_STRING = "string"

const TIME_UNITS = 1.0 / 120.0
const NULL_TERMINATOR = 0x00


static func get_type(channel_data: Dictionary) -> String:
	return channel_data.get("type", TYPE_BOOL)

static func is_bool(channel_data: Dictionary) -> bool:
	return get_type(channel_data) == TYPE_BOOL

static func is_event_type(type: String) -> bool:
	# Types that are single-point events (vertical bars), not ranges
	return type in [TYPE_COLOR, TYPE_AUDIO, TYPE_VIDEO, TYPE_IMAGE, TYPE_STRING]

static func uses_byte_data(type: String) -> bool:
	return type != TYPE_BOOL


static func time_to_int(t: float) -> int:
	return int(t / TIME_UNITS)

static func int_to_time(i: int) -> float:
	return i * TIME_UNITS

static func encode_time(t_int: int) -> PackedByteArray:
	var b = PackedByteArray()
	b.resize(4)
	b[0] = (t_int >> 24) & 0xFF
	b[1] = (t_int >> 16) & 0xFF
	b[2] = (t_int >> 8)  & 0xFF
	b[3] =  t_int        & 0xFF
	return b

static func decode_time(b: PackedByteArray, offset: int) -> int:
	return (b[offset] << 24) | (b[offset+1] << 16) | (b[offset+2] << 8) | b[offset+3]

static func encode_float(v: float) -> PackedByteArray:
	var tmp = PackedFloat32Array([v])
	return tmp.to_byte_array()

static func decode_float(b: PackedByteArray, offset: int) -> float:
	var tmp = b.slice(offset, offset + 4)
	return tmp.to_float32_array()[0]

static func encode_color(c: Color) -> PackedByteArray:
	var b = PackedByteArray()
	b.resize(4)
	b[0] = int(clamp(c.r, 0.0, 1.0) * 255)
	b[1] = int(clamp(c.g, 0.0, 1.0) * 255)
	b[2] = int(clamp(c.b, 0.0, 1.0) * 255)
	b[3] = int(clamp(c.a, 0.0, 1.0) * 255)
	return b

static func decode_color(b: PackedByteArray, offset: int) -> Color:
	return Color(b[offset]/255.0, b[offset+1]/255.0, b[offset+2]/255.0, b[offset+3]/255.0)

static func encode_string(s: String) -> PackedByteArray:
	var encoded = s.to_utf8_buffer()
	encoded.append(NULL_TERMINATOR)
	return encoded

static func decode_string(b: PackedByteArray, offset: int) -> Array:
	var end = offset
	while end < b.size() and b[end] != NULL_TERMINATOR:
		end += 1
	var s = b.slice(offset, end).get_string_from_utf8()
	return [s, (end - offset) + 1]  # +1 to consume the terminator

static func encode_float_entry(t_int: int, value: float) -> PackedByteArray:
	var b = encode_time(t_int)
	b.append_array(encode_float(value))
	return b  # 8 bytes total

static func encode_color_entry(t_int: int, color: Color) -> PackedByteArray:
	var b = encode_time(t_int)
	b.append_array(encode_color(color))
	return b  # 8 bytes total

static func encode_audio_entry(t_int: int, filename: String, offset_sec: float) -> PackedByteArray:
	var b = encode_time(t_int)
	b.append_array(encode_string(filename))
	b.append_array(encode_float(offset_sec))
	return b

static func encode_video_entry(t_int: int, filename: String, offset_sec: float) -> PackedByteArray:
	return encode_audio_entry(t_int, filename, offset_sec)  # identical format

static func encode_image_entry(t_int: int, filename: String) -> PackedByteArray:
	var b = encode_time(t_int)
	b.append_array(encode_string(filename))
	return b

static func encode_string_entry(t_int: int, value: String) -> PackedByteArray:
	var b = encode_time(t_int)
	b.append_array(encode_string(value))
	return b

static func encode_entries(type: String, entries: Array) -> String:
	if entries.is_empty():
		return ""
	var b = PackedByteArray()
	for entry in entries:
		match type:
			TYPE_FLOAT:
				b.append_array(encode_float_entry(entry["time"], entry["value"]))
			TYPE_COLOR:
				b.append_array(encode_color_entry(entry["time"], entry["color"]))
			TYPE_AUDIO, TYPE_VIDEO:
				b.append_array(encode_audio_entry(entry["time"], entry.get("file", "null"), entry.get("offset", 0.0)))
			TYPE_IMAGE:
				b.append_array(encode_image_entry(entry["time"], entry.get("file", "null")))
			TYPE_STRING:
				b.append_array(encode_string_entry(entry["time"], entry.get("value", "null")))
	return Marshalls.raw_to_base64(b)


static func decode_entries(type: String, raw_data) -> Array:
	var entries = []
	if raw_data == null or not raw_data is String or raw_data == "":
		return entries
	var base64_data: String = raw_data
	var b: PackedByteArray = Marshalls.base64_to_raw(base64_data)
	var i = 0
	while i + 4 <= b.size():
		var t_int = decode_time(b, i)
		i += 4
		match type:
			TYPE_FLOAT:
				if i + 4 > b.size():
					break
				entries.append({ "time": t_int, "value": decode_float(b, i) })
				i += 4
			TYPE_COLOR:
				if i + 4 > b.size():
					break
				entries.append({ "time": t_int, "color": decode_color(b, i) })
				i += 4
			TYPE_AUDIO, TYPE_VIDEO:
				var res = decode_string(b, i)
				i += res[1]
				if i + 4 > b.size():
					break
				var offset_sec = decode_float(b, i)
				i += 4
				entries.append({ "time": t_int, "file": res[0], "offset": offset_sec })
			TYPE_IMAGE:
				var res = decode_string(b, i)
				i += res[1]
				entries.append({ "time": t_int, "file": res[0] })
			TYPE_STRING:
				var res = decode_string(b, i)
				i += res[1]
				entries.append({ "time": t_int, "value": res[0] })
	return entries

static func get_float_at_time(entries: Array, t_int: int) -> float:
	if entries.is_empty():
		return 0.0
	if t_int <= entries[0]["time"]:
		return entries[0]["value"]
	if t_int >= entries[entries.size() - 1]["time"]:
		return entries[entries.size() - 1]["value"]
	for i in range(entries.size() - 1):
		var a = entries[i]
		var b = entries[i + 1]
		if t_int >= a["time"] and t_int <= b["time"]:
			var span = float(b["time"] - a["time"])
			if span == 0.0:
				return b["value"]
			var t = float(t_int - a["time"]) / span
			return lerp(a["value"], b["value"], t)
	return 0.0

static func insert_entry(entries: Array, entry: Dictionary) -> Array:
	if not entries.is_empty() and not entries[0] is Dictionary:
		push_error("GL_ChannelData.insert_entry called on non-dict array (bool channel?)")
		return entries
	var result = entries.duplicate()
	for i in range(result.size() - 1, -1, -1):
		if result[i]["time"] == entry["time"]:
			result.remove_at(i)
	result.append(entry)
	result.sort_custom(func(a, b): return a["time"] < b["time"])
	return result

static func remove_entry_at_time(entries: Array, t_int: int) -> Array:
	var result = entries.duplicate()
	for i in range(result.size() - 1, -1, -1):
		if result[i]["time"] == t_int:
			result.remove_at(i)
	return result
