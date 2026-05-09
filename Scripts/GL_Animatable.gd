extends Node3D
class_name GL_Animatable

@export var delete_parent_instead: bool = false
@export var animatable_group: String = ""

var _bbox_visual: MeshInstance3D = null
var _construction_area: Area3D = null

enum InteractState { NONE, MENU, MOVING, ROTATING, SCALING, SKIN_EDITING }
var _interact_state: InteractState = InteractState.NONE
var _construction_ui: Node = null

var _menu_items: Array[Node] = []
var _menu_selection: int = 0

const THEME_HIGHLIGHTED = preload("res://UI/Themes/Main.tres")
const THEME_NORMAL      = preload("res://UI/Themes/Sub.tres")

var _move_distance: float = 5.0
const MOVE_DIST_MIN: float = 2.0
const MOVE_DIST_MAX: float = 10.0
const MOVE_Y_OFFSET: float = -0.5
const SCALE_MIN: float = 0.1
const SCALE_MAX: float = 5.0
const SCALE_STEP: float = 0.1
const ROTATE_STEP_DEG: float = 15.0

func _sent_signals(_signal_ID: String, _the_signal): pass

func _ready():
	add_to_group("Animatable")
	if animatable_group != "":
		add_to_group(animatable_group)
	_build_bbox()

func on_construction_toggled(is_active: bool) -> void:
	if _bbox_visual: _bbox_visual.visible = is_active
	if _construction_area: _construction_area.visible = is_active
	if not is_active and _interact_state != InteractState.NONE:
		_close_interaction()

func interacted() -> void:
	match _interact_state:
		InteractState.NONE:    _open_menu()
		InteractState.MENU:    _confirm_menu_selection()
		InteractState.MOVING:  _return_to_menu()
		InteractState.ROTATING: _return_to_menu()
		InteractState.SCALING: _return_to_menu()

func _open_menu() -> void:
	var nodes := get_tree().get_nodes_in_group("Construction UI")
	if nodes.is_empty():
		push_warning("GL_Animatable: no node in group 'Construction UI'")
		return
	_construction_ui = nodes[0]
	_interact_state = InteractState.MENU
	_show_menu_ui()

func _show_menu_ui() -> void:
	if not _construction_ui: return
	_construction_ui.visible = true
	var menu_node = _construction_ui.find_child("Menu", true, false)
	if menu_node: menu_node.visible = true
	_menu_items.clear()
	for item_name in ["Edit", "Move", "Rotate", "Scale", "Duplicate", "Delete", "Exit"]:
		var item = _construction_ui.find_child(item_name, true, false)
		if item: _menu_items.append(item)
	_menu_selection = clamp(_menu_selection, 0, _menu_items.size() - 1)
	_refresh_menu_themes()

func _refresh_menu_themes() -> void:
	for i in _menu_items.size():
		var item = _menu_items[i]
		if item is PanelContainer or item is Panel:
			item.add_theme_stylebox_override("panel",
				THEME_HIGHLIGHTED if i == _menu_selection else THEME_NORMAL)

func _close_interaction() -> void:
	_interact_state = InteractState.NONE
	if not _construction_ui: return
	var menu_node = _construction_ui.find_child("Menu", true, false)
	if menu_node: menu_node.visible = false

func _return_to_menu() -> void:
	get_viewport().set_input_as_handled()
	_interact_state = InteractState.MENU
	_show_menu_ui()

func _confirm_menu_selection() -> void:
	if _menu_items.is_empty(): return
	get_viewport().set_input_as_handled()

	match _menu_items[_menu_selection].name:
		"Edit":      _open_skin_editor()
		"Move":
			_interact_state = InteractState.MOVING
			_construction_ui.visible = false
		"Rotate":    _interact_state = InteractState.ROTATING; _construction_ui.visible = false
		"Scale": _interact_state = InteractState.SCALING; _construction_ui.visible = false
		"Duplicate": _do_duplicate();
		"Delete":    _do_delete()
		"Exit":      _close_interaction()

func _open_skin_editor() -> void:
	var pause_nodes := get_tree().get_nodes_in_group("Pause Menu")
	if pause_nodes.is_empty():
		push_warning("GL_Animatable: no node in group 'Pause Menu'")
		return

	var pause_menu = pause_nodes[0]

	if _construction_ui:
		_construction_ui.visible = false

	_interact_state = InteractState.SKIN_EDITING

	if pause_menu.has_method("open_skin_editor_for_animatable"):
		pause_menu.open_skin_editor_for_animatable(self)
	else:
		push_warning("GL_Animatable: Pause Menu has no method 'open_skin_editor_for_animatable'")
		_interact_state = InteractState.MENU

func on_skin_editor_closed() -> void:
	_close_interaction()

func _do_duplicate() -> void:
	var dup = duplicate()
	get_parent().add_child(dup)
	var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	dup.global_position = global_position + Vector3(dir.x, 0.0, dir.y) * 2.0

	dup.set("_interact_state", InteractState.NONE)
	dup.set("_construction_ui", null)
	if "_menu_items" in dup: dup._menu_items.clear()
	dup.set("_menu_selection", 0)

	dup._bbox_visual = dup.find_child("_bbox_debug", true, false) as MeshInstance3D
	dup._construction_area = dup.find_child("_construction_area", true, false) as Area3D

	var construction_active := _bbox_visual != null and _bbox_visual.visible
	if dup._bbox_visual:
		dup._bbox_visual.visible = construction_active
	if dup._construction_area:
		dup._construction_area.visible = construction_active

	_close_interaction()

func _do_delete() -> void:
	_close_interaction()
	(get_parent() if delete_parent_instead else self).queue_free()

func _process_moving() -> void:
	var player := get_tree().get_nodes_in_group("Player Raycast").front() as Node3D
	if not player: return
	global_position = player.global_position + (-player.global_transform.basis.z) * _move_distance + Vector3(0, MOVE_Y_OFFSET, 0)

func _input(event: InputEvent) -> void:
	if _interact_state == InteractState.NONE:
		return

	if _interact_state == InteractState.SKIN_EDITING:
		return

	match _interact_state:
		InteractState.MENU:
			if event.is_action_pressed("Toggle Construction"):
				_close_interaction()
				return
			if event.is_action_pressed("Interact"):
				_confirm_menu_selection()
				return
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_menu_selection = clamp(_menu_selection - 1, 0, _menu_items.size() - 1)
					_refresh_menu_themes()
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_menu_selection = clamp(_menu_selection + 1, 0, _menu_items.size() - 1)
					_refresh_menu_themes()

		InteractState.MOVING:
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					_move_distance = clamp(_move_distance - 0.5, MOVE_DIST_MIN, MOVE_DIST_MAX)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					_move_distance = clamp(_move_distance + 0.5, MOVE_DIST_MIN, MOVE_DIST_MAX)
			if event.is_action_pressed("Interact"):
				_return_to_menu()
			elif event.is_action_pressed("Toggle Construction"):
				_return_to_menu()
				_close_interaction()

		InteractState.ROTATING:
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					rotation_degrees.y += ROTATE_STEP_DEG
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					rotation_degrees.y -= ROTATE_STEP_DEG
			if event.is_action_pressed("Interact"):
				_return_to_menu()
			elif event.is_action_pressed("Toggle Construction"):
				_return_to_menu()
				_close_interaction()

		InteractState.SCALING:
			if event is InputEventMouseButton and event.pressed:
				if event.button_index == MOUSE_BUTTON_WHEEL_UP:
					scale = (scale + Vector3.ONE * SCALE_STEP).clamp(Vector3.ONE * SCALE_MIN, Vector3.ONE * SCALE_MAX)
				elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
					scale = (scale - Vector3.ONE * SCALE_STEP).clamp(Vector3.ONE * SCALE_MIN, Vector3.ONE * SCALE_MAX)
			if event.is_action_pressed("Interact"):
				_return_to_menu()
			elif event.is_action_pressed("Toggle Construction"):
				_return_to_menu()
				_close_interaction()

func _process(_delta: float) -> void:
	if _interact_state == InteractState.MOVING:
		_process_moving()

func _build_bbox() -> void:
	var collision_shapes := _get_all_children(self).filter(func(n): return n is CollisionShape3D)
	var combined := AABB()
	var has_any := false
	for cs in collision_shapes:
		if not cs.shape: continue
		var local_xform: Transform3D = global_transform.inverse() * cs.global_transform
		var world_aabb: AABB = local_xform * cs.shape.get_debug_mesh().get_aabb()
		combined = world_aabb if not has_any else combined.merge(world_aabb)
		has_any = true
	if not has_any:
		combined = AABB(Vector3(-0.25, -0.25, -0.25), Vector3(0.5, 0.5, 0.5))
	_build_line_mesh(combined)
	_build_construction_area(combined)

func _build_line_mesh(combined: AABB) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var a := combined.position
	var b := combined.end
	var corners := [
		Vector3(a.x,a.y,a.z), Vector3(b.x,a.y,a.z),
		Vector3(b.x,a.y,b.z), Vector3(a.x,a.y,b.z),
		Vector3(a.x,b.y,a.z), Vector3(b.x,b.y,a.z),
		Vector3(b.x,b.y,b.z), Vector3(a.x,b.y,b.z),
	]
	var color := Color(0.0, 1.0, 0.2)
	for edge in [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]:
		st.set_color(color); st.add_vertex(corners[edge[0]])
		st.set_color(color); st.add_vertex(corners[edge[1]])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	var mesh := st.commit()
	mesh.surface_set_material(0, mat)
	_bbox_visual = MeshInstance3D.new()
	_bbox_visual.mesh = mesh
	_bbox_visual.name = "_bbox_debug"
	_bbox_visual.visible = false
	add_child(_bbox_visual)

func _build_construction_area(combined: AABB) -> void:
	_construction_area = Area3D.new()
	_construction_area.name = "_construction_area"
	_construction_area.collision_layer = 1
	_construction_area.collision_mask = 1
	_construction_area.input_ray_pickable = true
	_construction_area.position = combined.get_center()
	_construction_area.visible = false
	var constructor_script := load("res://Scripts/Animatables/GL_Constructor.gd")
	if constructor_script: _construction_area.set_script(constructor_script)
	var col_shape := CollisionShape3D.new()
	col_shape.shape = BoxShape3D.new()
	col_shape.shape.size = combined.size
	_construction_area.add_child(col_shape)
	add_child(_construction_area)

func _get_all_children(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in node.get_children():
		result.append(child)
		result.append_array(_get_all_children(child))
	return result
