extends GL_Animatable
class_name GL_Animatronic

var anim_tree: AnimationTree
var anim_player: AnimationPlayer
var blend_tree: AnimationNodeBlendTree
var animParameters: Dictionary
@export var animParametersFileName: String

var initialPos: Vector3
var initialRot: Vector3
var initialScale: Vector3
var animCache: Dictionary
var displayCache: Dictionary
var lastTickTime : float
var lastdelta : float
var forceAnimUpdate = false

func _ready():
	super()
	initialPos = position
	initialRot = rotation
	initialScale = scale
	_build_animTree()
	
func _build_animTree() -> void:
	for child in get_children():
		if child is AnimationPlayer:
			anim_player = child
			break
		anim_player = child.get_node_or_null("AnimationPlayer")
		if anim_player:
			break
			
	if anim_player == null:
		return
	
	anim_tree = AnimationTree.new()
	add_child(anim_tree)
	anim_tree.anim_player = anim_player.get_path()

	anim_tree.tree_root = AnimationNodeBlendTree.new()
	anim_tree.active = true
	blend_tree = anim_tree.tree_root as AnimationNodeBlendTree
	
	anim_player.speed_scale = 0
	
	var animations = anim_player.get_animation_list()
	if animations.size() == 0:
		return
		
	if animParametersFileName.strip_edges() != "":
		_load_anim_parameters(animParametersFileName)
	
	if animParameters.size() == 0:
		for key in animations:
			_create_anim_dict(key)
	
	_build_caches()
	
	if animations.size() == 1:
		printerr("STILL NEED TO FIX THIS AHEM: " + name)
		return

	var prev_name = "Anim_" + animations[0]
	var old_time_name = "Time_" + animations[0]
	var old_seek_name = "Seek_" + animations[0]
	
	var prev_anim_node := AnimationNodeAnimation.new()
	prev_anim_node.animation = animations[0]
	blend_tree.add_node(prev_name, prev_anim_node)
	
	var old_time_node := AnimationNodeTimeScale.new()
	blend_tree.add_node(old_time_name, old_time_node)
		
	var _old_seek_node := AnimationNodeTimeSeek.new()
	blend_tree.add_node(old_seek_name, _old_seek_node)
		
	blend_tree.connect_node(old_time_name, 0, prev_name)
	blend_tree.connect_node(old_seek_name, 0, old_time_name)
	prev_name = old_seek_name

	for i in range(1, animations.size()):
		var anim_name = "Anim_" + animations[i]
		var add_name = "Add_" + animations[i]
		var time_name = "Time_" + animations[i]
		var seek_name = "Seek_" + animations[i]

		var new_anim_node := AnimationNodeAnimation.new()
		new_anim_node.animation = animations[i]
		blend_tree.add_node(anim_name, new_anim_node)
		
		var time_node := AnimationNodeTimeScale.new()
		blend_tree.add_node(time_name, time_node)
		
		var seek_node := AnimationNodeTimeSeek.new()
		blend_tree.add_node(seek_name, seek_node)

		var add_node := AnimationNodeAdd2.new()
		blend_tree.add_node(add_name, add_node)
		
		blend_tree.connect_node(time_name, 0, anim_name)
		blend_tree.connect_node(seek_name, 0, time_name)
		blend_tree.connect_node(add_name, 0, prev_name)
		blend_tree.connect_node(add_name, 1, seek_name)
		prev_name = add_name

	blend_tree.connect_node("output", 0, prev_name)

	for i in range(0, animations.size()):
		anim_tree.set("parameters/Add_" + str(animations[i]) + "/add_amount", 1.0)
		anim_tree.set("parameters/Seek_" + str(animations[i]) + "/seek_request", 0)
		anim_tree.set("parameters/Time_" + str(animations[i]) + "/scale", 0)

func _build_caches() -> void:
	animCache.clear()
	displayCache.clear()
	for key in animParameters:
		var raw_anim = animParameters[key].get("animation", key)
		animCache[raw_anim] = key
		var stripped = key.split("|", true, 1)[-1]
		displayCache[stripped] = key

func _create_anim_dict(anim_name: String):
	animParameters[anim_name] = {"type": "standard", "out_speed": 5.0, "in_speed": 5.0, "value": 0, "signal_value": 0}

func _load_anim_parameters(file_name: String) -> void:
	var mods_dir = DirAccess.open("res://Mods")
	if not mods_dir:
		push_error("Mods folder not found.")
		return
	
	mods_dir.list_dir_begin()
	var mod_name = mods_dir.get_next()
	while mod_name != "":
		if mods_dir.current_is_dir() and mod_name != "." and mod_name != "..":
			var anim_params_path = "res://Mods/%s/Mod Directory/Anim Parameters/%s.json" % [mod_name, file_name]
			if FileAccess.file_exists(anim_params_path):
				var file = FileAccess.open(anim_params_path, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					file.close()
					var result = JSON.parse_string(json_text)
					if typeof(result) == TYPE_DICTIONARY:
						for key in result.keys():
								if typeof(result[key]) == TYPE_DICTIONARY:
									var dict_data = result[key]
									if dict_data.get("type", "") == "inverted_standard":
										dict_data["value"] = 1
										dict_data["signal_value"] = 0
									elif dict_data.get("type", "") == "play":
										dict_data["value"] = 0
										dict_data["signal_value"] = 0
										dict_data["playing"] = false
										dict_data["play_speed"] = 0.0
									else:
										dict_data["value"] = 0
										dict_data["signal_value"] = 0
									dict_data["old_value"] = dict_data["value"]
									animParameters[key] = dict_data
				return
		mod_name = mods_dir.get_next()

func _physics_process(delta: float) -> void:
	forceAnimUpdate = true

func update_anim_positions() -> void:
	lastdelta = (Time.get_ticks_msec() - lastTickTime) / 1000.0
	lastTickTime = Time.get_ticks_msec()
	
	if lastdelta == 0:
		print("?")
	
	if not anim_tree or not anim_player:
			print("Tree didn't build.")
			_build_animTree()
			return
	for raw_anim in anim_player.get_animation_list():
		var key = animCache.get(raw_anim, raw_anim)
		if not animParameters.has(key):
			continue
		var params = animParameters[key]
		params["old_value"] = params["value"]
		match(params["type"]):
			"standard":
				var signal_val = float(params["signal_value"])
				if signal_val > 0.5:
					params["value"] = clamp(float(params["value"]) + (lastdelta * params["out_speed"] * signal_val), 0, 1)
				elif signal_val < 0.5:
					params["value"] = clamp(float(params["value"]) - (lastdelta * params["in_speed"] * (1.0 - signal_val)), 0, 1)
			"inverted_standard":
				var signal_val = float(params["signal_value"])
				if signal_val > 0.5:
					params["value"] = clamp(float(params["value"]) - (lastdelta * params["out_speed"] * signal_val), 0, 1)
				elif signal_val < 0.5:
					params["value"] = clamp(float(params["value"]) + (lastdelta * params["in_speed"] * (1.0 - signal_val)), 0, 1)
			"move_to":
				params["value"] = lerp(float(params["value"]), float(params["signal_value"]), lastdelta * params["out_speed"])
			"loop":
				var speed = float(params["signal_value"])
				if speed > 0.0:
					params["value"] = fmod(float(params["value"]) + (lastdelta * params["out_speed"] * speed), 1.0)
			"play":
				var signal_val = float(params["signal_value"])
				if signal_val > 0.0:
					params["play_speed"] = signal_val
					if not params.get("playing", false):
						params["playing"] = true
						params["value"] = 0.0
				if params.get("playing", false):
					var speed = float(params.get("play_speed", 1.0))
					params["value"] = float(params["value"]) + (lastdelta * params["out_speed"] * speed)
					if float(params["value"]) >= 1.0:
						params["value"] = 1.0
						params["playing"] = false
						params["play_speed"] = 0.0
		
func _process(delta):
	super(delta)
	if not anim_tree or not anim_player:
		print("Tree didn't build.")
		_build_animTree()
		return
		
	if forceAnimUpdate:
		forceAnimUpdate = false
		update_anim_positions()
		
	for raw_anim in anim_player.get_animation_list():
		var key = animCache.get(raw_anim, raw_anim)
		if not animParameters.has(key):
			continue
		var params = animParameters[key]
		var anim_path = "parameters/Seek_" + raw_anim + "/seek_request"
		var anim_length = anim_player.get_animation(raw_anim).length
		var old_value = float(params.get("old_value", 0))
		var raw_value = float(params.get("value", 0))
		var time_value: float
		if params["type"] == "loop":
			var delta_value = raw_value - old_value
			if delta_value < -0.5:
				delta_value += 1.0
			elif delta_value > 0.5:
				delta_value -= 0.5
			var t = min(float(Time.get_ticks_msec() - lastTickTime) / 1000.0 / lastdelta, 1.0)
			time_value = (old_value + delta_value * t) * anim_length
		else:
			time_value = clamp(lerp(old_value, raw_value, min(float(Time.get_ticks_msec() - lastTickTime) / 1000.0 / lastdelta, 1.0)), 0.0, 1.0) * anim_length
		anim_tree.set(anim_path, time_value)
		
func _sent_signals(anim_name: String, value):
	anim_name = anim_name.split("|", true, 1)[-1]
	var key = displayCache.get(anim_name, anim_name)
	if animParameters.has(key):
		var newValue = clamp(float(value), 0, 1)
		if newValue == animParameters[key]["signal_value"]:
			return
		animParameters[key]["signal_value"] = newValue
		forceAnimUpdate = true
		return

	# Non-animations
	match(anim_name):
		"Position X":
			position.x = initialPos.x + value
		"Position Y":
			position.y = initialPos.y + value
		"Position Z":
			position.z = initialPos.z + value
		"Rotation X":
			rotation.x = initialRot.x + (value * TAU)
		"Rotation Y":
			rotation.y = initialRot.y + (value * TAU)
		"Rotation Z":
			rotation.z = initialRot.z + (value * TAU)
		"Scale X":
			scale.x = initialScale.x + value
		"Scale Y":
			scale.y = initialScale.y + value
		"Scale Z":
			scale.z = initialScale.z + value
