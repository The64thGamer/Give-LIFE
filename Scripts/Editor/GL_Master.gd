extends Node
class_name GL_Master
@onready var root = $".."
@onready var saveLoad : GL_SaveLoad = $SaveLoad
@onready var playback : GL_Playback = $Playback
@onready var fullEditor : Control = $"../Full Editor"
@onready var mediaLoader : GL_Media = $"../Full Editor/Editor/Modifiers/Media/VBoxContainer/MediaContainer"
@onready var fileLoader : Control = $"../File Loader"
@onready var timeline : GL_Timeline = $"../Full Editor/Data Timeline"
@onready var titleVar : LineEdit = $"../Full Editor/Editor/Modifiers/Settings/MarginContainer/HBoxContainer/VBoxContainer2/LineEdit"
@onready var authorVar : LineEdit =$"../Full Editor/Editor/Modifiers/Settings/MarginContainer/HBoxContainer/VBoxContainer2/LineEdit2"
@onready var createdVar : Label = $"../Full Editor/Editor/Modifiers/Settings/MarginContainer/HBoxContainer/VBoxContainer2/Label2"

var currentlyLoadedPath : String = ""
var currentlyLoadedFile : Dictionary = {}

var scene_groups: Dictionary = {}

var displayed_group: String = ""

const defaultShowName = "My Unnamed Show"

func _ready() -> void:
	fileLoader.visible = true
	fullEditor.visible = false

func load_show(path: String) -> bool:
	if path != "":
		currentlyLoadedFile = saveLoad.load_savefile(path)
		if currentlyLoadedFile != {}:
			currentlyLoadedPath = path
			_load_settings_general()
			return true
		return false
	return false

func save_and_quit():
	save()
	var parentRoot = root.get_parent()
	var newEditor = preload("res://New New/GL_Editor.tscn").instantiate()
	parentRoot.add_child(newEditor)
	newEditor.name = "GlEditor"
	root.queue_free()
	
func save() -> void:
	print("Saving File")
	if currentlyLoadedPath == "":
		print("Couldn't Save, Missing Path")
		return
	currentlyLoadedFile["lastUpdated"] = Time.get_datetime_string_from_system(true)
	saveLoad.save_to_folder(currentlyLoadedFile,currentlyLoadedPath)
	print("Saved to " + currentlyLoadedPath)

func _create_new_show():
	load_show(saveLoad.generate_savefile(defaultShowName))

func _export_show():
	saveLoad.export_save_as_zip(currentlyLoadedPath)

func _delete_show():
	print("Deleting Show")
	saveLoad.delete_savefile(currentlyLoadedPath)
	var parentRoot = root.get_parent()
	var newEditor = preload("res://New New/GL_Editor.tscn").instantiate()
	parentRoot.add_child(newEditor)
	newEditor.name = "GlEditor"
	root.queue_free()

func _import_show() -> void:
	var file_dialog := FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.zip ; Showtape Archives"]
	file_dialog.title = "Import Save ZIP"
	
	file_dialog.file_selected.connect(func(path: String):
		currentlyLoadedFile = saveLoad.import_and_load_zip(path)
		if currentlyLoadedFile != {}:
			currentlyLoadedPath = path
			_load_settings_general()
		file_dialog.queue_free()
	)
	
	file_dialog.canceled.connect(func(): file_dialog.queue_free())
	add_child(file_dialog)
	file_dialog.popup_centered_ratio(0.6)

func set_displayed_group(group_name: String) -> void:
	if group_name == displayed_group:
		return
	displayed_group = group_name
	timeline.on_group_changed()

func ensure_channel_exists(channel_id: String) -> void:
	if currentlyLoadedFile.is_empty():
		return
	if currentlyLoadedFile["channels"].has(channel_id):
		return
	var pipe = channel_id.find("|")
	var group = channel_id.left(pipe) if pipe != -1 else ""
	var type = "bool"
	if scene_groups.has(group) and scene_groups[group].has(channel_id):
		type = scene_groups[group][channel_id].get("type", "bool")
	currentlyLoadedFile["channels"][channel_id] = { "type": type, "data": [] }
	print("Auto-created channel: " + channel_id)
	playback.invalidate_all_cache()

func setAuthor(changed: String):
	if currentlyLoadedPath == "":
		return
	currentlyLoadedFile["author"] = changed
	
func setTitle(changed: String):
	if currentlyLoadedPath == "":
		return
	currentlyLoadedFile["title"] = changed

func _load_settings_general() -> void:
	get_tree().get_first_node_in_group("AnimatableImporter").refresh()
	timeline.reload_timeline()
	mediaLoader.reload_media()
	playback.reload_audio()
	fileLoader.visible = false
	fullEditor.visible = true
	titleVar.text = currentlyLoadedFile.get("title")
	authorVar.text = currentlyLoadedFile.get("author")
	createdVar.text = currentlyLoadedFile.get("timeCreated")
