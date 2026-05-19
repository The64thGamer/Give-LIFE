extends Control
class_name GL_Channel
@onready var title : Label = $ChannelTimeline/title
@onready var bindLabel : Label = $"Bind/Bind Label"
@onready var bindHint : TextureRect = $"Bind/Bind Hint"
@onready var channelTimeline : Control = $ChannelTimeline
@onready var bitHolder = $ChannelTimeline/BitHolder
@onready var controllerIcon : ControllerIcon = $"Bind/ControllerIcon"

var id = ""
var color : Color = Color.YELLOW
var master : GL_Master
var timeline : GL_Timeline
var changingBind = false
var currentBind = null

var _bit_panels: Array = []
var _float_points: Array = []
var _event_bars: Array = []

var _float_line: Line2D = null

const timeUnits = 1.0 / 120.0

var preview_particles_template: PackedScene = preload("res://New New/Prefabs/cpu_particles_2d.tscn")
var _preview_particles: CPUParticles2D = null
enum PreviewEdge { NONE, LEFT, RIGHT }
var _last_preview_edge: PreviewEdge = PreviewEdge.NONE

var _was_mouse_inside: bool = false

func _ready() -> void:
	master = get_tree().get_first_node_in_group("GL_Master") as GL_Master
	timeline = get_tree().get_first_node_in_group("GL_Timeline") as GL_Timeline

func _channel_data() -> Dictionary:
	return master.currentlyLoadedFile["channels"].get(id, {"type": "bool", "data": []})

func _channel_type() -> String:
	return GL_ChannelData.get_type(_channel_data())

func start() -> void:
	title.text = id
	var style = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	channelTimeline.add_theme_stylebox_override("panel", style)
	channelTimeline.self_modulate = color
	channelTimeline.self_modulate.a = 0.4
	updateBindLabel()

func _process(_delta: float) -> void:
	if timeline == null:
		return

	if not timeline.playing and self.is_visible_in_tree():
		if not timeline._scrub_handled_this_frame:
			var mouse_pos = channelTimeline.get_local_mouse_position()
			# Rect2(0,0, size.x, size.y) is the local bounds of the timeline area
			var timeline_rect = Rect2(Vector2.ZERO, channelTimeline.size)
			
			if timeline_rect.has_point(mouse_pos):
				timeline.setTimeFromTimeline(mouse_pos.x, channelTimeline.size.x)

func _input(event: InputEvent) -> void:
	if not changingBind:
		return
	get_viewport().set_input_as_handled()
	
	if event is InputEventMouseButton and event.pressed:
		var mediator = get_tree().get_first_node_in_group("EditChannel")
		if mediator:
			mediator.set_editing_channel(id, self)
		
	if event is InputEventKey and event.pressed:
		if (event.keycode >= KEY_0 and event.keycode <= KEY_9) || event.keycode == KEY_EQUAL ||event.keycode == KEY_MINUS:
			timeline.channelBinds[id] = event.keycode
			timeline.clear_controller_bind(id)
			updateBindLabel()
		elif event.keycode == KEY_BACKSPACE:
			timeline.clear_group_binds()

	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index in GL_Timeline.CONTROLLER_BUTTONS:
			timeline.channelControllerBinds[id] = {
				"type": "button",
				"input": event.button_index,
				"component": "value"
			}
			timeline.channelBinds.erase(id)
			updateBindLabel()
			
func time_to_int(t: float) -> int:
	return int(t / timeUnits)

func int_to_time(i: int) -> float:
	return i * timeUnits

func renderBits() -> void:
	match _channel_type():
		GL_ChannelData.TYPE_BOOL:
			_render_bool()
		GL_ChannelData.TYPE_FLOAT:
			_render_float()
		GL_ChannelData.TYPE_COLOR, GL_ChannelData.TYPE_AUDIO, GL_ChannelData.TYPE_VIDEO, \
		GL_ChannelData.TYPE_IMAGE, GL_ChannelData.TYPE_STRING:
			_render_events()

func _render_bool() -> void:
	_clear_float_nodes()
	_clear_event_bars()

	var raw = _channel_data()["data"]
	var stamps: Array = raw if raw is Array else []

	var width: float = bitHolder.size.x
	var t_start: float = timeline.timeStart
	var t_end: float = timeline.timeEnd
	var t_range: float = t_end - t_start

	var segments: Array = []
	var state = false
	var seg_start_time = 0.0

	for i in range(stamps.size()):
		var t = int_to_time(stamps[i])
		if not state:
			seg_start_time = t
			state = true
		else:
			var seg_end_time = t
			if seg_end_time > t_start and seg_start_time < t_end:
				segments.append([seg_start_time, seg_end_time, i - 1])
			state = false
	if state and seg_start_time < t_end:
		segments.append([seg_start_time, t_end, stamps.size() - 1])

	var needed = segments.size()

	# Pool: grow
	while _bit_panels.size() < needed:
		var panel = Panel.new()
		panel.set_script(GL_BitPanel)
		panel.channel = self
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		panel.add_theme_stylebox_override("panel", style)
		panel.self_modulate = color
		bitHolder.add_child(panel)
		_bit_panels.append(panel)

	# Pool: shrink — hide extras instead of freeing to avoid allocation next time
	for i in range(_bit_panels.size()):
		_bit_panels[i].visible = i < needed

	for i in range(needed):
		var seg = segments[i]
		var clamped_start = clamp(seg[0], t_start, t_end)
		var clamped_end = clamp(seg[1], t_start, t_end)
		var x = ((clamped_start - t_start) / t_range) * width
		var w = ((clamped_end - clamped_start) / t_range) * width
		_bit_panels[i].position = Vector2(x, 0)
		_bit_panels[i].size = Vector2(max(w, 1.0), bitHolder.size.y)
		_bit_panels[i]._open_stamp = stamps[seg[2]]
		_bit_panels[i].self_modulate = color
		_bit_panels[i].self_modulate.a = 1

	_render_bool_preview(width, t_start, t_end, t_range)

func _render_bool_preview(width: float, t_start: float, t_end: float, t_range: float) -> void:
	if not has_node("ChannelTimeline/BitHolder/PreviewPanel"):
		var preview = Panel.new()
		preview.name = "PreviewPanel"
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style = StyleBoxFlat.new()
		style.bg_color = Color(1.0, 1.0, 0.4, 0.5)
		preview.add_theme_stylebox_override("panel", style)
		bitHolder.add_child(preview)

	var preview_panel = bitHolder.get_node("PreviewPanel")
	if timeline.activeEdit.has(id):
		var edit = timeline.activeEdit[id]
		var seg_start = min(edit["start"], timeline.timeCurrent)
		var seg_end = max(edit["start"], timeline.timeCurrent)
		var cs = clamp(seg_start, t_start, t_end)
		var ce = clamp(seg_end, t_start, t_end)
		preview_panel.position = Vector2(((cs - t_start) / t_range) * width, 0)
		preview_panel.size = Vector2(max(((ce - cs) / t_range) * width, 1.0), bitHolder.size.y)
		preview_panel.visible = true
		_ensure_preview_particles(preview_panel)
	else:
		preview_panel.visible = false
		if _preview_particles != null and is_instance_valid(_preview_particles):
			_preview_particles.emitting = false

# ── Float rendering ───────────────────────────────────────────────────────────
func _render_float() -> void:
	_clear_bool_panels()
	_clear_event_bars()
	_hide_preview_panel()

	var ch_data = _channel_data()
	var entries: Array = ch_data.get("data", [])
	
	var width: float = bitHolder.size.x
	var height: float = bitHolder.size.y
	var t_start: float = timeline.timeStart
	var t_end: float = timeline.timeEnd
	var t_range: float = t_end - t_start

	var visible_entries: Array = entries.filter(func(e): 
		var t = int_to_time(e["time"])
		return t >= t_start - 0.1 and t <= t_end + 0.1
	)

	# Pool logic remains the same
	while _float_points.size() < visible_entries.size():
		var pt = Panel.new()
		pt.set_script(GL_FloatPoint)
		pt.channel = self
		bitHolder.add_child(pt)
		_float_points.append(pt)

	for i in range(_float_points.size()):
		_float_points[i].visible = i < visible_entries.size()

	for i in range(visible_entries.size()):
		var e = visible_entries[i]
		var t = int_to_time(e["time"])
		var x = ((t - t_start) / t_range) * width
		var y = (1.0 - e["value"]) * height
		var pt = _float_points[i]
		pt.entry = e
		pt.size = Vector2(GL_FloatPoint.POINT_SIZE, GL_FloatPoint.POINT_SIZE)
		pt.position = Vector2(x - GL_FloatPoint.POINT_SIZE * 0.5, y - GL_FloatPoint.POINT_SIZE * 0.5)
		pt.self_modulate = color

	if _float_line == null or not is_instance_valid(_float_line):
		_float_line = Line2D.new()
		_float_line.width = 2.0
		bitHolder.add_child(_float_line)
		bitHolder.move_child(_float_line, 0)

	_float_line.default_color = Color(color.r, color.g, color.b, 0.7)
	_float_line.clear_points()

	# CHANGE: Only draw points that are visible (or one-step outside) to avoid massive Line2D overhead
	for e in visible_entries:
		var t = int_to_time(e["time"])
		var x = ((t - t_start) / t_range) * width
		var y = (1.0 - e["value"]) * height
		_float_line.add_point(Vector2(x, y))
func _render_events() -> void:
	_clear_bool_panels()
	_clear_float_nodes()
	_hide_preview_panel()

	var type = _channel_type()
	var ch_data = _channel_data()
	
	# CHANGE: Access the live array directly
	var entries: Array = ch_data.get("data", [])
	
	var width: float = bitHolder.size.x
	var t_start: float = timeline.timeStart
	var t_end: float = timeline.timeEnd
	var t_range: float = t_end - t_start

	var visible_entries: Array = entries.filter(func(e):
		var t = GL_ChannelData.int_to_time(e["time"])
		return t >= t_start and t <= t_end
	)

	while _event_bars.size() < visible_entries.size():
		var bar = Panel.new()
		bar.set_script(GL_EventBar)
		bar.channel = self
		bitHolder.add_child(bar)
		_event_bars.append(bar)

	for i in range(_event_bars.size()):
		_event_bars[i].visible = i < visible_entries.size()

	for i in range(visible_entries.size()):
		var e = visible_entries[i]
		var t = GL_ChannelData.int_to_time(e["time"])
		var x = ((t - t_start) / t_range) * width
		var bar = _event_bars[i]
		
		bar.entry = e 
		bar.entry_type = type
		bar.size = Vector2(GL_EventBar.BAR_WIDTH, bitHolder.size.y)
		bar.position = Vector2(x - GL_EventBar.BAR_WIDTH * 0.5, 0)

		if type == GL_ChannelData.TYPE_COLOR:
			bar.self_modulate = e.get("color", color)
		else:
			bar.self_modulate = color

func _clear_bool_panels() -> void:
	for p in _bit_panels:
		p.queue_free()
	_bit_panels.clear()

func _clear_float_nodes() -> void:
	for p in _float_points:
		p.queue_free()
	_float_points.clear()
	if _float_line != null and is_instance_valid(_float_line):
		_float_line.queue_free()
		_float_line = null

func _clear_event_bars() -> void:
	for b in _event_bars:
		b.queue_free()
	_event_bars.clear()

func _hide_preview_panel() -> void:
	var preview_panel = bitHolder.get_node_or_null("PreviewPanel")
	if preview_panel:
		preview_panel.visible = false
	if _preview_particles != null and is_instance_valid(_preview_particles):
		_preview_particles.emitting = false

func updateBindLabel() -> void:
	var kb_bind = timeline.channelBinds.get(id, null)
	var ctrl_bind = timeline.channelControllerBinds.get(id, null)

	# Reset controller icon visibility by default
	controllerIcon.visible = false

	if kb_bind != null:
		var label: String
		match kb_bind:
			KEY_EQUAL:  label = "+"
			KEY_MINUS:  label = "-"
			_:          label = OS.get_keycode_string(kb_bind)
		bindLabel.text = label
		bindHint.visible = false
	elif ctrl_bind != null:
		# Controller bind: try to show icon, fall back to text
		bindHint.visible = false
		var icon_name = _controller_bind_to_icon_name(ctrl_bind)
		if icon_name != "":
			controllerIcon.button_name = icon_name
			controllerIcon._update_texture()
			controllerIcon.visible = true
			bindLabel.text = ""
		else:
			# Unmapped button — fall back to text label
			bindLabel.text = _controller_bind_label(ctrl_bind)
	else:
		bindLabel.text = ""
		bindHint.visible = true

	get_tree().get_first_node_in_group("AnimatableImporter").refresh_bind_alerts()

func _controller_bind_to_icon_name(bind: Dictionary) -> String:
	if bind["type"] == "button":
		match bind["input"]:
			JOY_BUTTON_A:              return "A"
			JOY_BUTTON_B:              return "B"
			JOY_BUTTON_X:              return "X"
			JOY_BUTTON_Y:              return "Y"
			JOY_BUTTON_LEFT_SHOULDER:  return "LB"
			JOY_BUTTON_RIGHT_SHOULDER: return "RB"
			JOY_BUTTON_DPAD_LEFT:      return "Dpad_Left"
			JOY_BUTTON_DPAD_RIGHT:     return "Dpad_Right"
			JOY_BUTTON_DPAD_UP:        return "Dpad_Up"
			JOY_BUTTON_DPAD_DOWN:      return "Dpad_Down"

	elif bind["type"] == "axis":
		var component = bind["component"]
		match bind["input"]:
			JOY_AXIS_TRIGGER_LEFT:  return "LT"
			JOY_AXIS_TRIGGER_RIGHT: return "RT"
			JOY_AXIS_LEFT_X:
				match component:
					"negative":    return "LstickL"
					"positive":    return "LstickR"
					"magnitude":   return "LstickMagnitude"
					"magnitude_2d": return "LstickMagnitude"
					"angle":       return "LstickAngle"
			JOY_AXIS_LEFT_Y:
				match component:
					"negative":    return "LstickUp"
					"positive":    return "LstickDown"
					"magnitude":   return "LstickMagnitude"
					"magnitude_2d": return "LstickMagnitude"
					"angle":       return "LstickAngle"
			JOY_AXIS_RIGHT_X:
				match component:
					"negative":    return "RstickL"
					"positive":    return "RstickR"
					"magnitude":   return "RstickMagnitude"
					"magnitude_2d": return "RstickMagnitude"
					"angle":       return "RstickAngle"
			JOY_AXIS_RIGHT_Y:
				match component:
					"negative":    return "RstickUp"
					"positive":    return "RstickDown"
					"magnitude":   return "RstickMagnitude"
					"magnitude_2d": return "RstickMagnitude"
					"angle":       return "RstickAngle"

	return ""

func _controller_bind_label(bind: Dictionary) -> String:
	if bind["type"] == "button":
		return "BTN %d" % bind["input"]
	return "AXIS %d [%s]" % [bind["input"], bind["component"]]
	
func binder_entered() -> void:
	changingBind = true

func binder_exited() -> void:
	changingBind = false

func _ensure_preview_particles(preview_panel: Panel) -> void:
	if _preview_particles != null and is_instance_valid(_preview_particles):
		return
	if preview_particles_template == null:
		return
	_preview_particles = preview_particles_template.instantiate()
	_preview_particles.emitting = false
	_preview_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_preview_particles.local_coords = true
	preview_panel.add_child(_preview_particles)

func sync_preview_to_scrubber(scrubber_x: float) -> void:
	var preview_panel = bitHolder.get_node_or_null("PreviewPanel")
	if not preview_panel or not timeline.activeEdit.has(id):
		return

	preview_panel.visible = true
	
	var t_start = timeline.activeEdit[id]["start"]
	var t_range = timeline.timeEnd - timeline.timeStart
	var x_start = ((t_start - timeline.timeStart) / t_range) * channelTimeline.size.x
	
	var x_now = scrubber_x
	
	var plot_left = min(x_start, x_now)
	var plot_right = max(x_start, x_now)
	
	preview_panel.position.x = plot_left
	preview_panel.size.x = max(1.0, plot_right - plot_left)
	
	if _preview_particles:
		var ph = preview_panel.size.y
		var edge: PreviewEdge = PreviewEdge.RIGHT if x_now >= x_start else PreviewEdge.LEFT
		
		if edge != _last_preview_edge:
			_last_preview_edge = edge
			_configure_particles_for_edge(edge, ph)
			
		_preview_particles.position = Vector2(preview_panel.size.x if edge == PreviewEdge.RIGHT else 0, ph * 0.5)
		_preview_particles.emitting = true

func _configure_particles_for_edge(edge: PreviewEdge, ph: float) -> void:
	match edge:
		PreviewEdge.LEFT:
			_preview_particles.emission_rect_extents = Vector2(1.0, ph * 0.5)
			_preview_particles.direction = Vector2(1, 0)
		PreviewEdge.RIGHT:
			_preview_particles.emission_rect_extents = Vector2(1.0, ph * 0.5)
			_preview_particles.direction = Vector2(-1, 0)
