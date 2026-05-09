extends Node

@onready var versionNumber: Label = get_node("MarginContainer/PanelContainer/Version Number")

@onready var usernameLineEdit: LineEdit = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/General/VBoxContainer/Username/LineEdit")
@onready var showPressedKeysButton: CheckButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/General/VBoxContainer/Show Pressed Keys/CheckButton")
@onready var bootOnStartOptions: OptionButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/General/VBoxContainer/Boot on Start/OptionButton")
@onready var windowModeOptions: OptionButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Window Mode/OptionButton")
@onready var msaaOptions: OptionButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Anti-Aliasing/OptionButton")
@onready var volumeSlider: Slider = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Audio/VBoxContainer/Master Volume/HSlider")
@onready var physicsbonesButton: CheckButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Physics Bones/CheckButton")
@onready var autorunButton: CheckButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/General/VBoxContainer/Autorun/CheckButton")
@onready var scaleMode: OptionButton = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Render Scale Mode/OptionButton")
@onready var renderscale: Slider = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Render Scale/HSlider")
@onready var renderScaleText: Label = get_node("MarginContainer/PanelContainer/Settings/Settings/TabContainer/Graphical/VBoxContainer/Render Scale/Label")
@export var fpsButton: CheckButton

@onready var simulatorButton: Button = get_node("MarginContainer/PanelContainer/Title Screen/Start Button")

@onready var titleScreenMenu: VBoxContainer = get_node("MarginContainer/PanelContainer/Title Screen")
@onready var settingsMenu: MarginContainer = get_node("MarginContainer/PanelContainer/Settings")
@onready var modMenu: MarginContainer = get_node("MarginContainer/PanelContainer/Mod Menu")
@onready var mapMenu: MarginContainer = get_node("MarginContainer/PanelContainer/Map Menu")
@onready var wikiMenu: MarginContainer = get_node("MarginContainer/PanelContainer/Wiki")
@onready var skinMenu: MarginContainer = get_node("MarginContainer/PanelContainer/Skins")

@onready var sideTitle: Label = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/Mod Title")
@onready var sideAuthor: Label = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/Mod Author")
@onready var sideDescription: Label = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/ScrollContainer/Mod Author2")
@onready var sideThumbnail: TextureRect = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/TextureRect")
@onready var sideExportBtn: Button = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/HBoxContainer/Export")
@onready var sideDeleteBtn: Button = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/MarginContainer/Mod Desc/MarginContainer/VBoxContainer/HBoxContainer/Delete")
@onready var sideBackBtn: Button = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/Back Button")

@onready var mapListContainer: VBoxContainer = get_node("MarginContainer/PanelContainer/Map Menu/Mods/PanelContainer/VBoxContainer/ScrollContainer/Map Holder")
@onready var modListContainer: VBoxContainer = get_node("MarginContainer/PanelContainer/Mod Menu/Mods/PanelContainer/HBoxContainer/VBoxContainer/ScrollContainer/Mod Holder")
@onready var importModDialog: FileDialog = get_node("ImportDialog")
@onready var exportModDialog: FileDialog = get_node("ExportDialog")

var mapEntryScene: PackedScene
var availableMaps := {}
var currentMapInstance: Node = null

var currentSettings := {
	"window_mode": 0,
	"boot_on_start": 0,
	"show_key_presses": false,
	"username": "Unknown Author",
	"master_volume": 1.0,
	"physics_bones": true,
	"msaa_3d": Viewport.MSAA_2X,
	"recent_map": "",
	"auto_run": false,
	"render_scale": 1.0,
	"scale_mode": 0,
	"show_fps": false,
}

var modEntryScene: PackedScene
var modData := {}
var exportFile: String
var mod_sources = {}

const settingsPath := "user://Settings/"
const settingsFilePath := settingsPath + "user_settings.cfg"

var editorInstance: Node = null
var keypressInstance: Node = null
var nodeMapScene: PackedScene
var keypresssScene: PackedScene

func _ready():
	modEntryScene = load("res://Scenes/UI/Mod Box.tscn")
	mapEntryScene = load("res://Scenes/UI/Map Box.tscn")
	nodeMapScene  = load("res://New New/GL_Editor.tscn")
	keypresssScene = load("res://Scenes/UI/Key Presses.tscn")

	DirAccess.make_dir_recursive_absolute("user://mods")
	_load_user_pcks()
	_load_mods()
	_populate_mod_list()
	load_maps()
	skinMenu.initialize()
	wikiMenu.initialize()

	editorInstance = nodeMapScene.instantiate()
	get_tree().root.add_child.call_deferred(editorInstance)
	(editorInstance as Control).visible = false
	keypressInstance = keypresssScene.instantiate()
	get_tree().root.add_child.call_deferred(keypressInstance)
	await editorInstance.ready
	await keypressInstance.ready

	versionNumber.text = "v" + ProjectSettings.get_setting("application/config/version")
	hide_sidebar()
	load_settings()

	if currentSettings["master_volume"] > 1.0:
		currentSettings["master_volume"] = 1.0
	apply_settings()

	match currentSettings["boot_on_start"]:
		1:
			var map_name = currentSettings.get("recent_map", "")
			if map_name != "" and availableMaps.has(map_name):
				load_map_scene(map_name)
			else:
				print("No recent map to load or map not found.")
		2:
			self.visible = false
			setEditorVisibility(true)
			
func toggleEditorVisibility():
	if editorInstance == null:
		editorInstance = get_tree().root.get_node("GlEditor")
		if editorInstance == null:
			editorInstance = get_tree().root.get_node("GlEditor2")
	editorInstance.visible = !editorInstance.visible

func setEditorVisibility(visible: bool):
	if editorInstance == null:
		editorInstance = get_tree().root.get_node("GlEditor")
		if editorInstance == null:
			editorInstance = get_tree().root.get_node("GlEditor2")
	editorInstance.visible = visible

func _unhandled_input(event):	
	if currentMapInstance == null:
		if event.is_action_pressed("Pause") or event.is_action_pressed("Editor"):
			if skinMenu.visible:
				close_skin_editor()
			else:
				swapEditorPause()
	else:
		if event.is_action_pressed("Pause"):
			if skinMenu.visible:
				close_skin_editor()
			else:
				toggle_pause_menu()
		elif event.is_action_pressed("Editor"):
			if skinMenu.visible:
				close_skin_editor()
			else:
				toggle_editor()

func open_skin_editor(target: Node3D) -> void:
	var changer = skinMenu if skinMenu.has_method("start_editing") else null
	if not changer:
		for child in skinMenu.get_children():
			if child.has_method("start_editing"):
				changer = child
				break
				
	if changer:
		changer.start_editing(target)
	else:
		push_warning("Could not find GL_SkinChanger script in skinMenu.")

	self.visible = true
	setEditorVisibility(false)
	update_mouse_mode()
	switchMenu("skins")

func close_skin_editor() -> void:
	switchMenu("title")
	self.visible = false
	update_mouse_mode()

func swapEditorPause() -> void:
	toggleEditorVisibility()
	self.visible = !editorInstance.visible

func switchMenu(menu:String):
	titleScreenMenu.visible = false
	settingsMenu.visible = false
	mapMenu.visible = false
	modMenu.visible = false
	wikiMenu.visible = false
	skinMenu.visible = false
	hide_sidebar()

	match(menu):
		"title":
			titleScreenMenu.visible =  true
		"settings":
			settingsMenu.visible =  true
		"wiki":
			wikiMenu.visible =  true
		"mods":
			modMenu.visible =  true
		"maps":
			mapMenu.visible =  true
		"skins":
			skinMenu.visible =  true
func _on_slider_changed(value:float, name:String):
	currentSettings[name] = value
	save_settings()
	apply_settings()

func _on_button_changed(value:bool, name:String):
	currentSettings[name] = value
	save_settings()
	apply_settings()

func _on_option_changed(value:int, name:String):
	currentSettings[name] = value
	save_settings()
	apply_settings()
	
func _on_line_edit_changed(value:String, name:String):
	currentSettings[name] = value
	save_settings()
	apply_settings()

func save_settings():
	DirAccess.make_dir_recursive_absolute(settingsPath)
	var config := ConfigFile.new()

	for key in currentSettings.keys():
		config.set_value("settings", key, currentSettings[key])

	var err = config.save(settingsFilePath)
	if err != OK:
		push_error("Failed to save settings: " + str(err))
	else:
		print("Settings saved to: ", settingsFilePath)

func load_settings():
	var config := ConfigFile.new()
	var err := config.load(settingsFilePath)

	if err != OK:
		print("No existing settings file found, using defaults.")
		return

	for key in currentSettings.keys():
		if config.has_section_key("settings", key):
			currentSettings[key] = config.get_value("settings", key)

	print("Settings loaded: ", currentSettings)

func apply_settings():
	# Window Mode
	if currentSettings["window_mode"] == 1:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	if usernameLineEdit.text != currentSettings["username"]:
		usernameLineEdit.text = currentSettings["username"]
	bootOnStartOptions.selected = currentSettings["boot_on_start"]
	windowModeOptions.selected = currentSettings["window_mode"]
	msaaOptions.selected = currentSettings["msaa_3d"]
	volumeSlider.set_value_no_signal(currentSettings["master_volume"])
	showPressedKeysButton.set_pressed_no_signal(currentSettings["show_key_presses"])
	fpsButton.set_pressed_no_signal(currentSettings["show_fps"])
	autorunButton.set_pressed_no_signal(currentSettings["auto_run"])
	physicsbonesButton.set_pressed_no_signal(currentSettings["physics_bones"])
	scaleMode.set_pressed_no_signal(currentSettings["scale_mode"])
	renderscale.set_value_no_signal(currentSettings["render_scale"])
	renderScaleText.text = "Render Scale (" + str(roundi(currentSettings["render_scale"]*100)) + "%)"
	
	var vp = get_tree().root.get_viewport()
	vp.msaa_3d = currentSettings["msaa_3d"]
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(currentSettings["master_volume"]))
	match currentSettings["scale_mode"]:
		0: vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		1: vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
		2: vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	vp.scaling_3d_scale = currentSettings.get("render_scale", 1.0)
	
	for camera in get_tree().get_nodes_in_group("cameras"):
		if camera.has_method("refresh"):
			camera.refresh()
	
	get_tree().call_group("SettingsReceivers", "on_settings_applied", currentSettings)

func _notify_cameras() -> void:
	for camera in get_tree().get_nodes_in_group("cameras"):
		if camera.has_method("refresh"):
			camera.refresh()

func update_simulator_button_text():
	if currentMapInstance:
		simulatorButton.text = "Unload Map"
	else:
		simulatorButton.text = "Map List"

func _on_simulator_button_pressed():
	if currentMapInstance:
		unload_current_map()
	else:
		switchMenu("maps")

func toggle_pause_menu():
	var will_show = not self.visible
	self.visible = will_show
	if will_show:
		setEditorVisibility(false)
	update_mouse_mode()

func toggle_editor():
	toggleEditorVisibility()
	self.visible = !editorInstance.visible
	update_mouse_mode()

func update_mouse_mode():
	if not self.visible and not editorInstance.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_quit_button_pressed():
	get_tree().quit()

func load_maps():
	availableMaps.clear()
	for child in mapListContainer.get_children():
		child.queue_free()

	print("Loading maps...")

	var mods_dir := DirAccess.open("res://Mods")
	if mods_dir == null:
		push_error("Mods directory not found!")
		return

	mods_dir.list_dir_begin()
	var mod_name = mods_dir.get_next()
	while mod_name != "":
		if mods_dir.current_is_dir() and mod_name != "." and mod_name != "..":
			print("Checking mod folder:", mod_name)
			var map_dir_path = "res://Mods/%s/Mod Directory/Maps" % mod_name
			print("Looking for maps in:", map_dir_path)

			if DirAccess.dir_exists_absolute(map_dir_path):
				var maps_dir := DirAccess.open(map_dir_path)
				if maps_dir:
					print("Opened maps directory:", map_dir_path)
					maps_dir.list_dir_begin()
					var map_folder = maps_dir.get_next()
					while map_folder != "":
						if maps_dir.current_is_dir() and map_folder != "." and map_folder != "..":
							print("Checking map folder:", map_folder)
							var full_map_path = "%s/%s" % [map_dir_path, map_folder]
							print("Map path:", full_map_path)

							var map_info_path = full_map_path + "/Map Info.cfg"
							var icon_path = full_map_path + "/Map Icon.png"

							var config := ConfigFile.new()
							var result := config.load(map_info_path)
							print("Tried loading Map Info:", map_info_path, "Result:", result)

							if result == OK:
								var map_name = config.get_value("map", "maptitle", map_folder)
								print("Loaded map info:", map_name)

								# Search for first .tscn or .tscn.remap file
								var scene_path := ""
								var inner_dir := DirAccess.open(full_map_path)
								if inner_dir:
									inner_dir.list_dir_begin()
									var f = inner_dir.get_next()
									while f != "":
										var filename = f
										# If file ends with .remap, strip it
										if filename.ends_with(".remap"):
											filename = filename.substr(0, filename.length() - 6)
										if filename.to_lower().ends_with(".tscn"):
											scene_path = "%s/%s" % [full_map_path, filename]
											print("Found scene file (handling remap):", scene_path)
											break
										f = inner_dir.get_next()

								if scene_path != "":
									availableMaps[map_name] = scene_path
									print("Added map:", map_name, "→", scene_path)

									var entry = mapEntryScene.instantiate()
									entry.get_node("PanelContainer/HBoxContainer/Name").text = map_name
									entry.get_node("PanelContainer/HBoxContainer/PanelContainer/Icon").texture = load(icon_path)

									var load_button = entry.get_node("PanelContainer/Button")
									load_button.pressed.connect(load_map_scene.bind(map_name))

									mapListContainer.add_child(entry)
								else:
									push_warning("No .tscn file found in: " + full_map_path)
							else:
								push_warning("Map Info failed to load: " + map_info_path)
						map_folder = maps_dir.get_next()
				else:
					print("Failed to open maps directory:", map_dir_path)
			else:
				print("Map directory does not exist:", map_dir_path)
		mod_name = mods_dir.get_next()

	print("Map loading complete.")


func load_map_scene(map_name: String):
	if availableMaps.has(map_name):
		var path = availableMaps[map_name]
		var scene = load(path)
		if scene:
			if currentMapInstance:
				currentMapInstance.queue_free()
			currentMapInstance = scene.instantiate()
			get_tree().root.add_child(currentMapInstance)

			self.visible = false
			editorInstance.visible = false
			update_mouse_mode()
			update_simulator_button_text()
			switchMenu("title")
			currentSettings["recent_map"] = map_name
			save_settings()
			apply_settings()
			get_tree().get_first_node_in_group("AnimatableImporter").refresh()
	else:
		push_error("Map not found or not available: " + map_name)

func unload_current_map():
	if currentMapInstance:
		currentMapInstance.tree_exited.connect(func():
			get_tree().get_first_node_in_group("AnimatableImporter").refresh()
		)
		currentMapInstance.queue_free()
		currentMapInstance = null
		self.visible = true
		update_mouse_mode()
		update_simulator_button_text()

func _load_user_pcks():
	# First pass — existing mods
	var before_mods = _scan_mod_folders()
	for m in before_mods:
		mod_sources[m] = ""  # built-in

	# Load pcks one by one, and check for new folders after each
	var user_dir = DirAccess.open("user://mods")
	user_dir.list_dir_begin()
	var fname = user_dir.get_next()
	while fname != "":
		if not user_dir.current_is_dir() and fname.to_lower().ends_with(".pck"):
			var src = "user://mods/" + fname
			var ok = ProjectSettings.load_resource_pack(src)
			if ok:
				print("Loaded PCK mod:", fname)
				var after_mods = _scan_mod_folders()
				for m in after_mods:
					if m not in mod_sources:
						mod_sources[m] = src  # came from this pck
			else:
				push_error("Failed to load PCK: " + src)
		fname = user_dir.get_next()
	user_dir.list_dir_end()

func _load_mods():
	modData.clear()
	var mods_dir = DirAccess.open("res://Mods")
	if not mods_dir:
		push_error("Mods directory not found!")
		return

	mods_dir.list_dir_begin()
	var mod_name = mods_dir.get_next()
	while mod_name != "":
		if mods_dir.current_is_dir() and mod_name not in [".",".."]:
			var base = "res://Mods/%s" % mod_name
			var info_cfg = base + "/Mod Info.cfg"
			if FileAccess.file_exists(info_cfg):
				print("Loaded " + mod_name)
				var cfg = ConfigFile.new()
				if cfg.load(info_cfg) == OK:
					modData[mod_name] = {
						"title": cfg.get_value("mods","modtitle",mod_name),
						"author": cfg.get_value("mods","modauthor","Unknown"),
						"description": cfg.get_value("mods","moddescription",""),
						"pck_src": mod_sources.get(mod_name, ""),
						"icon": base + "/Mod Icon.png",
						"thumbnail": base + "/Mod Thumbnail.png",
					}
			else:
				print(mod_name + " does not have a .cfg file, deleting automatically.")
				var pck = mod_sources.get(mod_name, "")
				if pck != "" and DirAccess.remove_absolute(pck) == OK:
					print("Deleted PCK for ", mod_name)
					get_tree().quit()
				else:
					push_error("Failed to delete PCK for " + mod_name)
		mod_name = mods_dir.get_next()
	mods_dir.list_dir_end()


func print_all_files_in_dir(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var item = dir.get_next()
		while item != "":
			var item_path = path.path_join(item)
			if dir.current_is_dir():
				print("[DIR] " + item_path)
				print_all_files_in_dir(item_path) # recurse into subfolder
			else:
				print("[FILE] " + item_path)
			item = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open directory: " + path)

func _populate_mod_list():
	for child in modListContainer.get_children():
		child.queue_free()
	for name in modData.keys():
		var data = modData[name]
		var entry = modEntryScene.instantiate()
		entry.get_node("PanelContainer/HBoxContainer/Title").text  = data.title
		entry.get_node("PanelContainer/HBoxContainer/PanelContainer/Icon").texture = load(data.icon)
		
		# assume the prefab has a Button named “SelectBtn”
		var select_btn = entry.get_node("Button") as Button
		select_btn.button_down.connect(func(n=name):
			_select_mod(n)
		)
		modListContainer.add_child(entry)

func _select_mod(mod_name: String):
	if not modData.has(mod_name):
		return
	var d = modData[mod_name]

	# Populate UI
	sideTitle.text       = d.title
	sideTitle.visible = true
	sideAuthor.text      = "By: " + d.author
	sideAuthor.visible = true
	sideDescription.text = d.description
	sideDescription.visible = true
	sideThumbnail.texture = load(d.thumbnail)
	sideThumbnail.visible = true
	
	var has_pck = d.pck_src != ""
	sideDeleteBtn.visible = has_pck
	sideExportBtn.visible = has_pck
	
	# Clear any previous signals on those buttons
	for conn in sideExportBtn.get_signal_connection_list("pressed"):
		sideExportBtn.disconnect("pressed", conn["callable"])
	for conn in sideDeleteBtn.get_signal_connection_list("pressed"):
		sideDeleteBtn.disconnect("pressed", conn["callable"])

	# Hook export
	sideExportBtn.pressed.connect(func():
		exportFile = mod_name
		exportModDialog.current_file = d.title + ".pck"
		exportModDialog.popup_centered()
	)
	# Hook delete
	sideDeleteBtn.pressed.connect(func():
		_delete_mod(mod_name)
		# repurpose back button
		sideBackBtn.text = "Quit to Reload"
		for conn in sideBackBtn.get_signal_connection_list("pressed"):
			sideBackBtn.disconnect("pressed", conn["callable"])
		sideBackBtn.pressed.connect(_on_quit_button_pressed)
	)

func _on_import_mod_selected(path: String):
	var fn = path.get_file()
	var dest = "user://mods/" + fn
	if copy_file(path, dest) != OK:
		push_error("Failed to import mod PCK.")
		return
	_load_user_pcks()
	_load_mods()
	_populate_mod_list()


func _on_export_mod_selected(path: String):
	var mod_name = exportFile
	var src = modData[mod_name].pck_src
	if src == "":
		push_error("No PCK source recorded for mod: " + mod_name)
		return
	if copy_file(src, path) != OK:
		push_error("Failed to export PCK.")
	else:
		print("Exported", mod_name, "to", path)

func import_mod():
	importModDialog.popup_centered()

func _delete_mod(mod_name):
	var pck = modData[mod_name].pck_src
	if pck != "" and DirAccess.remove_absolute(pck) == OK:
		print("Deleted PCK for ", mod_name)
	else:
		push_error("Failed to delete PCK for " + mod_name)
	_load_user_pcks()
	_load_mods()
	_populate_mod_list()

func copy_file(src: String, dest: String) -> int:
	var src_file := FileAccess.open(src, FileAccess.READ)
	if src_file == null:
		return ERR_CANT_OPEN
	var data := src_file.get_buffer(src_file.get_length())
	src_file.close()

	var dest_file := FileAccess.open(dest, FileAccess.WRITE)
	if dest_file == null:
		return ERR_CANT_CREATE
	dest_file.store_buffer(data)
	dest_file.close()

	return OK

func hide_sidebar():
	sideTitle.visible = false
	sideAuthor.visible = false
	sideDescription.visible = false
	sideThumbnail.visible = false
	sideExportBtn.visible = false
	sideDeleteBtn.visible = false

func _scan_mod_folders() -> Array:
	var mods = []
	var mods_dir = DirAccess.open("res://Mods")
	if mods_dir:
		mods_dir.list_dir_begin()
		var name = mods_dir.get_next()
		while name != "":
			if mods_dir.current_is_dir() and name not in [".", ".."]:
				mods.append(name)
			name = mods_dir.get_next()
	return mods
