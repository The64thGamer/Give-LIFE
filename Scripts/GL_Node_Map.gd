extends Control

var background: TextureRect
var holder: Control
var is_panning: bool = false
var last_mouse_pos: Vector2
var is_hovered: bool = false

func _ready():
	visible = false
	background = get_node("Background")
	holder = get_node("Holder")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

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
