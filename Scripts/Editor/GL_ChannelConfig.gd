extends Control
class_name GL_EditChannel

@onready var timeline: GL_Timeline = $"../../../Data Timeline"
@onready var hint: Control = $MarginContainer
@onready var options: Control = $HBoxContainer

@onready var channel_label: Label = $HBoxContainer/VBoxContainer2/Label

@onready var btn_none:  Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonNone
@onready var btn_1:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button1
@onready var btn_2:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button2
@onready var btn_3:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button3
@onready var btn_4:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button4
@onready var btn_5:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button5
@onready var btn_6:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button6
@onready var btn_7:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button7
@onready var btn_8:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button8
@onready var btn_9:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button9
@onready var btn_0:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/Button0
@onready var btn_minus: Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonMinus
@onready var btn_plus:  Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonPlus
@onready var btn_a:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonA
@onready var btn_b:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonB
@onready var btn_x:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonX
@onready var btn_y:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonY
@onready var btn_lb:    Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonLB
@onready var btn_rb:    Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/ButtonRB

@onready var btn_dpad_l:    Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/DpadL
@onready var btn_dpad_up:   Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/DpadUp
@onready var btn_dpad_r:    Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/DpadR
@onready var btn_dpad_down: Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/DpadDown

@onready var btn_rstick_l:         Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickL
@onready var btn_rstick_up:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickUp
@onready var btn_rstick_r:         Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickR
@onready var btn_rstick_down:      Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickDown
@onready var btn_rstick_angle:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickAngle
@onready var btn_rstick_ud:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickUD
@onready var btn_rstick_lr:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickLR
@onready var btn_rstick_magnitude: Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/RstickMagnitude

@onready var btn_lstick_l:         Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickL
@onready var btn_lstick_up:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickUp
@onready var btn_lstick_r:         Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickR
@onready var btn_lstick_down:      Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickDown
@onready var btn_lstick_angle:     Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickAngle
@onready var btn_lstick_ud:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickUD
@onready var btn_lstick_lr:        Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickLR
@onready var btn_lstick_magnitude: Button = $HBoxContainer/VBoxContainer2/PanelContainer/MarginContainer/HFlowContainer/LstickMagnitude

@onready var clear_data_button:    Button = $HBoxContainer/VBoxContainer/erase
@onready var convert_type_button:  Button = $HBoxContainer/VBoxContainer/convert

var _current_channel_id: String = ""
var _current_channel: GL_Channel = null

func _ready() -> void:
	hint.visible = true
	options.visible = false
	add_to_group("EditChannel")
	visible = false

	# ── Channel ops ───────────────────────────────────────────────────────────
	clear_data_button.pressed.connect(_on_clear_data)
	convert_type_button.pressed.connect(_on_convert_type)

	# ── Clear bind ────────────────────────────────────────────────────────────
	btn_none.pressed.connect(_on_clear_bind)

	# ── Keyboard binds ────────────────────────────────────────────────────────
	btn_1.pressed.connect(func(): _set_key(KEY_1))
	btn_2.pressed.connect(func(): _set_key(KEY_2))
	btn_3.pressed.connect(func(): _set_key(KEY_3))
	btn_4.pressed.connect(func(): _set_key(KEY_4))
	btn_5.pressed.connect(func(): _set_key(KEY_5))
	btn_6.pressed.connect(func(): _set_key(KEY_6))
	btn_7.pressed.connect(func(): _set_key(KEY_7))
	btn_8.pressed.connect(func(): _set_key(KEY_8))
	btn_9.pressed.connect(func(): _set_key(KEY_9))
	btn_0.pressed.connect(func(): _set_key(KEY_0))
	btn_minus.pressed.connect(func(): _set_key(KEY_MINUS))
	btn_plus.pressed.connect(func(): _set_key(KEY_EQUAL))  # + is unshifted = on most layouts

	# ── Face / shoulder buttons ───────────────────────────────────────────────
	btn_a.pressed.connect(func():  _set_joy_button(JOY_BUTTON_A))
	btn_b.pressed.connect(func():  _set_joy_button(JOY_BUTTON_B))
	btn_x.pressed.connect(func():  _set_joy_button(JOY_BUTTON_X))
	btn_y.pressed.connect(func():  _set_joy_button(JOY_BUTTON_Y))
	btn_lb.pressed.connect(func(): _set_joy_button(JOY_BUTTON_LEFT_SHOULDER))
	btn_rb.pressed.connect(func(): _set_joy_button(JOY_BUTTON_RIGHT_SHOULDER))

	# ── Dpad ──────────────────────────────────────────────────────────────────
	btn_dpad_l.pressed.connect(func():    _set_joy_button(JOY_BUTTON_DPAD_LEFT))
	btn_dpad_up.pressed.connect(func():   _set_joy_button(JOY_BUTTON_DPAD_UP))
	btn_dpad_r.pressed.connect(func():    _set_joy_button(JOY_BUTTON_DPAD_RIGHT))
	btn_dpad_down.pressed.connect(func(): _set_joy_button(JOY_BUTTON_DPAD_DOWN))

	# ── Right stick ───────────────────────────────────────────────────────────
	btn_rstick_l.pressed.connect(func():         _set_axis(JOY_AXIS_RIGHT_X, "negative"))
	btn_rstick_r.pressed.connect(func():         _set_axis(JOY_AXIS_RIGHT_X, "positive"))
	btn_rstick_up.pressed.connect(func():        _set_axis(JOY_AXIS_RIGHT_Y, "negative"))
	btn_rstick_down.pressed.connect(func():      _set_axis(JOY_AXIS_RIGHT_Y, "positive"))
	btn_rstick_lr.pressed.connect(func():        _set_axis(JOY_AXIS_RIGHT_X, "magnitude"))
	btn_rstick_ud.pressed.connect(func():        _set_axis(JOY_AXIS_RIGHT_Y, "magnitude"))
	btn_rstick_magnitude.pressed.connect(func(): _set_axis(JOY_AXIS_RIGHT_X, "magnitude_2d"))
	btn_rstick_angle.pressed.connect(func():     _set_axis(JOY_AXIS_RIGHT_X, "angle"))

	# ── Left stick ────────────────────────────────────────────────────────────
	btn_lstick_l.pressed.connect(func():         _set_axis(JOY_AXIS_LEFT_X, "negative"))
	btn_lstick_r.pressed.connect(func():         _set_axis(JOY_AXIS_LEFT_X, "positive"))
	btn_lstick_up.pressed.connect(func():        _set_axis(JOY_AXIS_LEFT_Y, "negative"))
	btn_lstick_down.pressed.connect(func():      _set_axis(JOY_AXIS_LEFT_Y, "positive"))
	btn_lstick_lr.pressed.connect(func():        _set_axis(JOY_AXIS_LEFT_X, "magnitude"))
	btn_lstick_ud.pressed.connect(func():        _set_axis(JOY_AXIS_LEFT_Y, "magnitude"))
	btn_lstick_magnitude.pressed.connect(func(): _set_axis(JOY_AXIS_LEFT_X, "magnitude_2d"))
	btn_lstick_angle.pressed.connect(func():     _set_axis(JOY_AXIS_LEFT_X, "angle"))


func set_editing_channel(channel_id: String, channel: GL_Channel) -> void:
	_current_channel_id = channel_id
	_current_channel = channel
	visible = true
	hint.visible = false
	options.visible = true
	_refresh_ui()


func _refresh_ui() -> void:
	if _current_channel_id == "":
		return
	channel_label.text = _current_channel_id
	_refresh_type_button()


func _refresh_type_button() -> void:
	var type = timeline.get_channel_type(_current_channel_id)
	match type:
		GL_ChannelData.TYPE_BOOL:
			convert_type_button.visible = true
			convert_type_button.text = "Erase + Convert to Float (0.0 -> 1.0)"
		GL_ChannelData.TYPE_FLOAT:
			convert_type_button.visible = true
			convert_type_button.text = "Erase + Convert to Bool (Off / On)"
		_:
			convert_type_button.visible = false


func _on_clear_data() -> void:
	if _current_channel_id == "":
		return
	timeline.clear_channel(_current_channel_id)


func _on_convert_type() -> void:
	if _current_channel_id == "":
		return
	var type = timeline.get_channel_type(_current_channel_id)
	var target = GL_ChannelData.TYPE_FLOAT if type == GL_ChannelData.TYPE_BOOL else GL_ChannelData.TYPE_BOOL
	timeline.convert_channel_type(_current_channel_id, target)
	_refresh_type_button()


func _on_clear_bind() -> void:
	if _current_channel_id == "":
		return
	timeline.clear_channel_bind(_current_channel_id)


func _set_key(keycode: Key) -> void:
	if _current_channel_id == "":
		return
	timeline.channelBinds[_current_channel_id] = keycode
	timeline.channelControllerBinds.erase(_current_channel_id)
	if _current_channel:
		_current_channel.updateBindLabel()


func _set_joy_button(button: JoyButton) -> void:
	if _current_channel_id == "":
		return
	timeline.set_controller_bind(_current_channel_id, {
		"type": "button",
		"input": button,
		"component": "value"
	})


func _set_axis(axis: JoyAxis, component: String) -> void:
	if _current_channel_id == "":
		return
	timeline.set_controller_bind(_current_channel_id, {
		"type": "axis",
		"input": axis,
		"component": component
	})
