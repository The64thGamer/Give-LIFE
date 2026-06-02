extends Node3D

enum BonePreset {
	HAIR_NO_GRAVITY, #0
	HAIR, #1
	SLOW_HAIR_NO_GRAVITY, #2
	SLOW_HAIR, #3
	ANIMATRONIC_MOVEMENT_LIGHT, #4
	ANIMATRONIC_MOVEMENT_MEDIUM, #5
	ANIMATRONIC_MOVEMENT_HEAVY, #6
	FLOPPY, #7
	LIGHT_FLOPPY, #8
}

var bone_config := {}

#Override filename
@export var boneConfigFileName: String

var currentPhysicsToggle = true
var skeleton: Skeleton3D = null

func _ready():
	# Try loading override if filename provided
	if boneConfigFileName.strip_edges() != "":
		_load_bone_config(boneConfigFileName)

	add_to_group("SettingsReceivers")
	skeleton = find_skeleton(self)
	if skeleton == null:
		push_error("No Skeleton3D found in children!")
		return

	for bone_name in bone_config.keys():
		var preset = bone_config[bone_name]
		apply_physics_bone_to(bone_name, preset)

# Loads bone config from Mods folder
func _load_bone_config(file_name: String) -> void:
	var mods_dir = DirAccess.open("res://Mods")
	if not mods_dir:
		push_error("Mods folder not found.")
		return
	
	mods_dir.list_dir_begin()
	var mod_name = mods_dir.get_next()
	while mod_name != "":
		if mods_dir.current_is_dir() and mod_name != "." and mod_name != "..":
			var config_path = "res://Mods/%s/Mod Directory/Physics Bones/%s.json" % [mod_name, file_name]
			if FileAccess.file_exists(config_path):
				var file = FileAccess.open(config_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					file.close()
					var result = JSON.parse_string(json_text)
					if typeof(result) == TYPE_DICTIONARY:
						# Overwrite defaults completely
						bone_config = {}
						for key in result.keys():
							var preset_value = int(result[key])
							bone_config[key] = preset_value
				return
		mod_name = mods_dir.get_next()

func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node

	for child in node.get_children():
		if child is Node:
			var result = find_skeleton(child)
			if result != null:
				return result
	return null

func apply_physics_bone_to(bone_name: String, preset: BonePreset) -> void:
	var bone_index = skeleton.find_bone(bone_name)
	if bone_index == -1:
		printerr(name + " bone not found: %s" % bone_name)
		printerr(name + "'s list of bones: %s" % str(skeleton.get_bone_count()))
		var bone_list = []
		for i in skeleton.get_bone_count():
			bone_list.append(skeleton.get_bone_name(i))
		printerr("Available bones: %s" % str(bone_list))
		return

	var bone_physics = DMWBWiggleRotationModifier3D.new()
	bone_physics.bone_name = bone_name
	set_preset_parameters(bone_physics, preset)

	skeleton.add_child(bone_physics)
	bone_physics.owner = get_parent()

func set_preset_parameters(pb: DMWBWiggleRotationModifier3D, preset: BonePreset) -> void:
	pb.properties = DMWBWiggleRotationProperties3D.new()
	pb.properties.linear_scale = 1.0 
	match preset:
		BonePreset.HAIR:
			pb.properties.angular_damp = 8.0
			pb.properties.spring_freq = 3.0
			pb.properties.gravity = Vector3(0,-9.81,0)
		BonePreset.SLOW_HAIR:
			pb.properties.angular_damp = 3
			pb.properties.spring_freq = 2.0
			pb.properties.gravity = Vector3(0,-9.81,0)
		BonePreset.HAIR_NO_GRAVITY:
			pb.properties.angular_damp = 8.0
			pb.properties.spring_freq = 3.0
		BonePreset.SLOW_HAIR_NO_GRAVITY:
			pb.properties.angular_damp = 1.5
			pb.properties.spring_freq = 2.0			
		BonePreset.ANIMATRONIC_MOVEMENT_LIGHT:
			pb.properties.angular_damp = 1.0
			pb.properties.swing_span = 0.01
			pb.properties.spring_freq = 1
		BonePreset.ANIMATRONIC_MOVEMENT_MEDIUM:
			pb.properties.swing_span = 0.25
			pb.properties.spring_freq = 2
		BonePreset.ANIMATRONIC_MOVEMENT_HEAVY:
			pb.properties.swing_span = 0.5
			pb.properties.spring_freq = 3
		BonePreset.FLOPPY:
			pb.properties.angular_damp = 2.5
			pb.properties.spring_freq = 1.2
		BonePreset.LIGHT_FLOPPY:
			pb.properties.angular_damp = 14.0
			pb.properties.spring_freq = 2.5

func on_settings_applied(settings: Dictionary):
	if currentPhysicsToggle != settings["physics_bones"]:
		set_physics_bones_enabled(settings["physics_bones"])

func set_physics_bones_enabled(enable: bool):
	currentPhysicsToggle = enable
	for child in skeleton.get_children(true):
		if child is DMWBWiggleRotationModifier3D or child is DMWBWigglePositionModifier3D:
			child.active = enable
