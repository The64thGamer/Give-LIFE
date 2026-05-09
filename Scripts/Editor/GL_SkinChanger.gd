extends Control

const PAINTABLE_SHADERS = ["res://Shaders/GL_Paintable.gdshader", "res://Shaders/Paintable_Simple.gdshader"]
const FALLBACK_ICON = preload("res://UI/Question.png")
const ANIMATABLES_SUBPATH = "Animatables"
const PAINT_PARAMS = ["paint_color_r", "paint_color_g", "paint_color_b", "paint_color_a"]

@onready var skin_preview: TextureRect = $"VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/Character Portrait"
@onready var skin_author_label: Label = $VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/Author
@onready var character_option: OptionButton = $VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/CharacterBox
@onready var skin_option: OptionButton = $VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/SkinBox
@onready var material_option: OptionButton = $VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer2/MaterialBox
@onready var material_panel: PanelContainer = $VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer
@onready var color_pickers: Array = [
	$VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer2/ColorA,
	$VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer2/ColorB,
	$VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer2/ColorC,
	$VBoxContainer/HBoxContainer/MarginContainer/VBoxContainer2/PanelContainer/MarginContainer/VBoxContainer2/ColorD,
]

var skin_db: Dictionary = {}
var custom_colors: Dictionary = {}
var current_group: String = ""
var current_skin_name: String = ""
var current_material: String = ""
var editing_target: Node3D = null

func _ready() -> void:
	character_option.item_selected.connect(_on_character_selected)
	skin_option.item_selected.connect(_on_skin_selected)
	material_option.item_selected.connect(_on_material_selected)
	for i in color_pickers.size():
		color_pickers[i].color_changed.connect(_on_color_changed.bind(i))

func initialize() -> void:
	_scan_mods()
	_populate_character_option()

func _scan_mods() -> void:
	var mods_dir = DirAccess.open("res://Mods")
	if not mods_dir:
		return
	mods_dir.list_dir_begin()
	var mod_name = mods_dir.get_next()
	while mod_name != "":
		if mods_dir.current_is_dir() and not mod_name.begins_with("."):
			_scan_animatables("res://Mods/%s/Mod Directory/%s" % [mod_name, ANIMATABLES_SUBPATH])
		mod_name = mods_dir.get_next()
	mods_dir.list_dir_end()

func _scan_animatables(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir():
			var actual_file = file.trim_suffix(".remap") if file.ends_with(".remap") else file
			if actual_file.ends_with(".tscn"):
				var packed = load("%s/%s" % [path, actual_file])
				if packed:
					var instance = packed.instantiate()
					var group = instance.get_groups()[0] if instance.get_groups().size() > 0 else ""
					if group != "":
						if not skin_db.has(group):
							skin_db[group] = {}
						skin_db[group][file.get_basename()] = {
							"path": "%s/%s" % [path, actual_file],
							"icon": instance.get("animatableIcon") if instance.get_script() else null,
							"authors": instance.get("animatableAuthors") if instance.get_script() else "",
							"materials": _extract_paintable_materials(instance),
						}
					instance.queue_free()
		file = dir.get_next()
	dir.list_dir_end()

func _extract_paintable_materials(node: Node) -> Dictionary:
	var found: Dictionary = {}
	_recurse_materials(node, found)
	return found

func _recurse_materials(node: Node, found: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if _is_paintable(mat):
				var mat_name = _mat_name(mat, i)
				if mat_name not in found:
					found[mat_name] = _read_paint_params(mat)
	for child in node.get_children():
		_recurse_materials(child, found)

func _is_paintable(mat) -> bool:
	return mat is ShaderMaterial and mat.shader and mat.shader.resource_path in PAINTABLE_SHADERS

func _mat_name(mat: ShaderMaterial, surface_index: int) -> String:
	return mat.resource_path.get_file().get_basename() if mat.resource_path != "" else "Material_%s_%d" % [str(mat.get_rid()), surface_index]

func _read_paint_params(mat: ShaderMaterial) -> Dictionary:
	var defaults: Dictionary = {}
	for idx in PAINT_PARAMS.size():
		var val = mat.get_shader_parameter(PAINT_PARAMS[idx])
		if val is Color:
			defaults[idx] = val
	return defaults

func start_editing(target: Node3D) -> void:
	editing_target = target
	var found_group = ""
	for g in skin_db.keys():
		if target.is_in_group(g):
			found_group = g
			break
	if found_group == "" and skin_db.size() > 0:
		found_group = skin_db.keys()[0]

	var found_skin = ""
	if found_group != "" and skin_db.has(found_group):
		var target_icon = target.get("skinIcon") if "skinIcon" in target else null
		for s_name in skin_db[found_group].keys():
			if skin_db[found_group][s_name].icon == target_icon:
				found_skin = s_name
				break
		if found_skin == "" and skin_db[found_group].size() > 0:
			found_skin = skin_db[found_group].keys()[0]

	for i in character_option.item_count:
		if character_option.get_item_text(i) == found_group:
			character_option.select(i)
			_on_character_selected(i)
			break
	for i in skin_option.item_count:
		if skin_option.get_item_text(i) == found_skin:
			skin_option.select(i)
			_on_skin_selected(i)
			break

	_load_colors_from_target()
	_update_color_pickers_from_cache()

func _load_colors_from_target() -> void:
	if not is_instance_valid(editing_target) or not _current_skin_data():
		return
	custom_colors.clear()
	_recurse_load_colors(editing_target)

func _recurse_load_colors(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if _is_paintable(mat):
				var key = "%s|%s" % [current_skin_name, _mat_name(mat, i)]
				if not custom_colors.has(key):
					custom_colors[key] = {}
				for idx in PAINT_PARAMS.size():
					var val = mat.get_shader_parameter(PAINT_PARAMS[idx])
					if val is Color:
						custom_colors[key][idx] = val
	for child in node.get_children():
		_recurse_load_colors(child)

func _broadcast_signal(signal_id: String, value) -> void:
	if is_instance_valid(editing_target):
		if editing_target.has_method("_sent_signals"):
			editing_target._sent_signals(signal_id, value)
		var parts = signal_id.split("|")
		if parts.size() == 3:
			_apply_color_to_materials(editing_target, parts[1], int(parts[2]), value)

func _apply_color_to_materials(node: Node, mat_name: String, param_index: int, color: Color) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat = node.get_active_material(i)
			if _is_paintable(mat) and _mat_name(mat, i) == mat_name and param_index < PAINT_PARAMS.size():
				mat.set_shader_parameter(PAINT_PARAMS[param_index], color)
	for child in node.get_children():
		_apply_color_to_materials(child, mat_name, param_index, color)

func confirm_changes() -> void:
	_reapply_custom_colors()
	var pause_menus = get_tree().get_nodes_in_group("Pause Menu")
	if not pause_menus.is_empty():
		pause_menus[0].close_skin_editor()

func _populate_character_option() -> void:
	character_option.clear()
	for group in skin_db.keys():
		character_option.add_item(group)
	if character_option.item_count > 0:
		_on_character_selected(0)

func _on_character_selected(index: int) -> void:
	current_group = character_option.get_item_text(index)
	custom_colors.clear()
	_populate_skin_option()

func _populate_skin_option() -> void:
	skin_option.clear()
	if not skin_db.has(current_group):
		return
	for skin_name in skin_db[current_group].keys():
		skin_option.add_item(skin_name)
	if skin_option.item_count > 0:
		_on_skin_selected(0)

func _on_skin_selected(index: int) -> void:
	current_skin_name = skin_option.get_item_text(index)
	_refresh_preview()
	_refresh_material_list()
	_swap_scene()

func _refresh_preview() -> void:
	var data = _current_skin_data()
	if not data:
		return
	skin_preview.texture = data.get("icon", null) if data.get("icon") else FALLBACK_ICON
	skin_author_label.text = "Skin by %s" % data.get("authors", "???")

func _refresh_material_list() -> void:
	material_option.clear()
	var data = _current_skin_data()
	if not data or data.get("materials", {}).is_empty():
		material_panel.visible = false
		current_material = ""
		_update_color_pickers_from_cache()
		return
	for mat_name in data["materials"].keys():
		material_option.add_item(mat_name)
	material_panel.visible = true
	_on_material_selected(0)

func _on_material_selected(index: int) -> void:
	current_material = material_option.get_item_text(index)
	_update_color_pickers_from_cache()

func _update_color_pickers_from_cache() -> void:
	if current_material == "":
		return
	var key = "%s|%s" % [current_skin_name, current_material]
	var cached = custom_colors.get(key, {})
	var data = _current_skin_data()
	var defaults = data["materials"].get(current_material, {}) if data and data.get("materials") else {}
	for i in color_pickers.size():
		if cached.has(i):
			color_pickers[i].color = cached[i]
		elif defaults.has(i):
			color_pickers[i].color = defaults[i]

func _on_color_changed(color: Color, param_index: int) -> void:
	if current_material == "":
		return
	var key = "%s|%s" % [current_skin_name, current_material]
	if not custom_colors.has(key):
		custom_colors[key] = {}
	custom_colors[key][param_index] = color
	_broadcast_signal("%s|%s|%d" % [current_group, current_material, param_index], color)

func _swap_scene() -> void:
	if not is_instance_valid(editing_target):
		return
	var data = _current_skin_data()
	if not data:
		return
	var packed = load(data["path"])
	if not packed:
		return
	var parent = editing_target.get_parent()
	if not is_instance_valid(parent):
		return
	var tform = editing_target.global_transform
	editing_target.queue_free()
	var instance = packed.instantiate()
	parent.add_child(instance)
	if instance is Node3D:
		instance.global_transform = tform
	editing_target = instance
	_reapply_custom_colors()

func _reapply_custom_colors() -> void:
	for key in custom_colors.keys():
		var parts = key.split("|")
		if parts.size() != 2 or parts[0] != current_skin_name:
			continue
		for param_index in custom_colors[key].keys():
			_broadcast_signal("%s|%s|%d" % [current_group, parts[1], param_index], custom_colors[key][param_index])

func _current_skin_data() -> Dictionary:
	return skin_db.get(current_group, {}).get(current_skin_name, {})
