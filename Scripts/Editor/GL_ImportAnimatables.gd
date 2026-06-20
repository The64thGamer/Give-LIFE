extends HFlowContainer
class_name GL_AnimatableGroupCompiler

@onready var master: GL_Master = $"../../../../../../../Master"
@onready var timeline: GL_Timeline = $"../../../../../../Data Timeline"

const GROUP_BUTTON_SCENE = preload("res://Scenes/UI/AnimtableGroup.tscn")

const OTHER_GROUP := "Other"

var _group_buttons: Dictionary = {} 

func refresh() -> void:
	_compile_groups()
	_rebuild_buttons()
	_validate_displayed_group()


func _compile_groups() -> void:
	var new_groups: Dictionary = {}

	var animatables: Array = get_tree().get_nodes_in_group("Animatable")
	for node in animatables:
		var object_group := _get_object_group(node)
		if object_group == "":
			continue

		if not new_groups.has(object_group):
			new_groups[object_group] = {
				"channels": {},
				"icon": null,
				"display_name": "",
			}

		var grp: Dictionary = new_groups[object_group]

		if grp["display_name"] == "":
			var grabbed_name: String = ""
			var grabbed_icon: Texture2D = null
			if node.get("animatableName") != null:
				grabbed_name = str(node.animatableName).strip_edges()
			if node.get("animatableIcon") != null:
				grabbed_icon = node.animatableIcon
			grp["display_name"] = grabbed_name if grabbed_name != "" else object_group
			grp["icon"] = grabbed_icon

		var channel_color := "ffffff"
		if node.get("animatableColor") != null:
			channel_color = _color_to_hex(node.animatableColor)

		if node is GL_Animatronic:
			_collect_animatronic(node, object_group, channel_color, grp["channels"])
		elif node is GL_ChaseLight:
			_collect_chase_light(node, object_group, channel_color, grp["channels"])
		elif node is GL_Spotlight:
			_collect_spotlight(node, object_group, channel_color, grp["channels"])
		elif node is GL_Lights:
			_collect_lights(node, object_group, channel_color, grp["channels"])
		elif node is GL_LightProjector:
			_collect_projector(node, object_group, channel_color, grp["channels"])

	var flat_groups: Dictionary = {}
	for group_name in new_groups:
		flat_groups[group_name] = new_groups[group_name]["channels"]

	var other_channels: Dictionary = {}
	var saved_channels: Dictionary = master.currentlyLoadedFile.get("channels", {})
	for channel_id in saved_channels:
		var pipe = channel_id.find("|")
		var channel_group = channel_id.left(pipe) if pipe != -1 else ""
		if flat_groups.has(channel_group):
			continue
		var data = saved_channels[channel_id].get("data", [])
		var has_data: bool = (data is Array and not data.is_empty()) \
			or (data is String and data != "")
		if not has_data:
			continue
		var saved_type: String = saved_channels[channel_id].get("type", "bool")
		other_channels[channel_id] = { "type": saved_type, "color": "ffffff" }

	if not other_channels.is_empty():
		flat_groups[OTHER_GROUP] = other_channels
		new_groups[OTHER_GROUP] = {
			"channels": other_channels,
			"icon": null,
			"display_name": OTHER_GROUP,
		}

	master.scene_groups = flat_groups

	_cached_meta = new_groups

var _cached_meta: Dictionary = {}


func _collect_animatronic(node: GL_Animatronic, group: String, color: String, channels: Dictionary) -> void:
	for param_key in node.animParameters:
		var channel_id = group + "|" + param_key
		if channels.has(channel_id):
			continue 
		var entry = node.animParameters[param_key]
		var anim_type: String = entry.get("type", "standard")
		var channel_type: String
		match anim_type:
			"move_to", "loop":
				channel_type = GL_ChannelData.TYPE_FLOAT
			_:  
				channel_type = GL_ChannelData.TYPE_BOOL
		channels[channel_id] = { "type": channel_type, "color": color }

func _collect_spotlight(node: GL_Spotlight, group: String, color: String, channels: Dictionary) -> void:
	_add_channel(channels, group, "intensity", GL_ChannelData.TYPE_BOOL, color)
	if node.canChangeColor:
		_add_channel(channels, group, "color", GL_ChannelData.TYPE_COLOR, color)
	if node.canChangeSize and node.spotLight != null:
		_add_channel(channels, group, "size", GL_ChannelData.TYPE_FLOAT, color)

func _collect_lights(node: GL_Lights, group: String, color: String, channels: Dictionary) -> void:
	_add_channel(channels, group, "intensity", GL_ChannelData.TYPE_BOOL, color)
	if node.canChangeColor:
		_add_channel(channels, group, "color", GL_ChannelData.TYPE_COLOR, color)
	if node.canChangeSize:
		_add_channel(channels, group, "size", GL_ChannelData.TYPE_FLOAT, color)
	if node.canRotateX:
		_add_channel(channels, group, "moveX", GL_ChannelData.TYPE_FLOAT, color)
	if node.canRotateY:
		_add_channel(channels, group, "moveY", GL_ChannelData.TYPE_FLOAT, color)

func _collect_chase_light(node: GL_ChaseLight, group: String, color: String, channels: Dictionary) -> void:
	_add_channel(channels, group, "intensity", GL_ChannelData.TYPE_BOOL,  color)
	_add_channel(channels, group, "chase",     GL_ChannelData.TYPE_FLOAT, color)
	_add_channel(channels, group, "grouping",  GL_ChannelData.TYPE_FLOAT, color)

func _collect_projector(node: GL_LightProjector, group: String, color: String, channels: Dictionary) -> void:
	_add_channel(channels, group, "intensity", GL_ChannelData.TYPE_BOOL,  color)
	_add_channel(channels, group, "Video",     GL_ChannelData.TYPE_VIDEO, color)
	if node.canChangeColor:
		_add_channel(channels, group, "color", GL_ChannelData.TYPE_COLOR, color)

func _add_channel(channels: Dictionary, group: String, signal_key: String, type: String, color: String) -> void:
	var channel_id := group + "|" + signal_key
	if not channels.has(channel_id):
		channels[channel_id] = { "type": type, "color": color }

func _rebuild_buttons() -> void:
	# Clear old buttons.
	for child in get_children():
		child.queue_free()
	_group_buttons.clear()

	for group_name in master.scene_groups:
		var meta: Dictionary = _cached_meta.get(group_name, {})
		var display_name: String = meta.get("display_name", group_name)
		var icon: Texture2D = meta.get("icon", null)

		var btn: Button = GROUP_BUTTON_SCENE.instantiate()
		add_child(btn)
		_group_buttons[group_name] = btn

		var label := btn.get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/Label") as Label
		var tex   := btn.get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/TextureRect") as TextureRect
		if label:
			label.text = display_name
		if tex and icon:
			tex.texture = icon

		btn.pressed.connect(func():
			_on_group_button_pressed(group_name)
		)

	_refresh_button_highlight()

func refresh_bind_alerts() -> void:
	for group_name in _group_buttons:
		var btn: Button = _group_buttons[group_name]
		var alert := btn.get_node_or_null("MarginContainer/PanelContainer/Alert")
		if not alert:
			continue
		var has_bind := false
		for channel_id in master.scene_groups.get(group_name, {}):
			if timeline.channelBinds.has(channel_id) or timeline.channelControllerBinds.has(channel_id):
				has_bind = true
				break
		alert.visible = has_bind

func _on_group_button_pressed(group_name: String) -> void:
	master.set_displayed_group(group_name)
	_refresh_button_highlight()

func _refresh_button_highlight() -> void:
	for group_name in _group_buttons:
		var btn: Button = _group_buttons[group_name]
		btn.button_pressed = (group_name == master.displayed_group)


func _validate_displayed_group() -> void:
	if master.displayed_group == "":
		return
	if not master.scene_groups.has(master.displayed_group):
		master.set_displayed_group("")

func _get_object_group(node: Node) -> String:
	for g in node.get_groups():
		if g != "Animatable":
			return g
	return ""

func _color_to_hex(c: Color) -> String:
	var r := int(c.r * 255.0) & 0xFF
	var g := int(c.g * 255.0) & 0xFF
	var b := int(c.b * 255.0) & 0xFF
	return "%02x%02x%02x" % [r, g, b]
