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

func create_channel(type: String) -> bool:
	if currentlyLoadedFile == {}:
		print("Can't Create Channel, No File")
		return false
	var rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	var id = type + "_" + str(rng.randi())
	var index = currentlyLoadedFile["channels"].size()
	currentlyLoadedFile["channels"][id] = {"type": type, "data": "","index": index}
	print("Created Channel: (" + str(id) + ") "+ str(currentlyLoadedFile["channels"][id]))
	save()
	return true
	
func save_and_quit():
	save()
	var parentRoot = root.get_parent()
	var newEditor = preload("res://New New/GL_Editor.tscn").instantiate()
	parentRoot.add_child(newEditor)
	newEditor.name = "GlEditor"
	root.queue_free()
	
func save() -> void:
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

func setAuthor(changed: String):
	if currentlyLoadedPath == "":
		return
	currentlyLoadedFile["author"] = changed
	
func setTitle(changed: String):
	if currentlyLoadedPath == "":
		return
	currentlyLoadedFile["title"] = changed

func _load_settings_general() -> void:
	timeline.reload_timeline()
	mediaLoader.reload_media()
	playback.reload_audio()
	fileLoader.visible = false
	fullEditor.visible = true
	titleVar.text = currentlyLoadedFile.get("title")
	authorVar.text = currentlyLoadedFile.get("author")
	createdVar.text = currentlyLoadedFile.get("timeCreated")
