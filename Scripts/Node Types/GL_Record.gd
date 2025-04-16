extends GL_Node
class_name GL_Record
var timer:float
const sampleRate = 0.05
var recording:Dictionary
var oldTime:float = 0.000030042452 #sorta random number
var time:float = 0
var rng:RandomNumberGenerator
var oldRecording:bool
var defaultValues:Dictionary

func _ready():
	super._ready()
	_set_title("Record")
	special_condition = "Record Node"
	_create_row("Recording",false,null,true,false,0)
	_create_row("Current Time",0.0,0.0,false,0,0)
	_update_visuals()
	rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	pass 

func _process(delta):
	super._process(delta)
	apply_pick_values()
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	time = float(rows["Current Time"]["output"])
	_traverse()
	var recordBool = rows["Recording"]["input"]
	if recordBool == true:
		if recordBool != oldRecording || time == 0:
			for key in rows:
				defaultValues[key] = rows[key]["output"]
		if timer <= 0:
			timer = sampleRate
			_record()
		timer -= delta
	oldTime = time
	oldRecording = recordBool
	for key in rows:
		_send_input(key)

func _traverse():
	if time == oldTime:
		return
	for key in recording:
		if key == "Recording" || key == "Current Time":
			continue
		if recording[key]["start"] == null || recording[key]["end"] == null:
			continue
		if recording[key]["current"] == null:
			recording[key]["current"] = recording[key]["start"]
		if time == 0:
			recording[key]["lastUsed"] = recording[key]["start"]
			recording[key]["current"] = recording[key]["start"] 
		if time < oldTime: #rewind
			continue #fix pls
		else: #forward
			var current = recording[key]["current"]
			var newCurrent = recursive_traverse_forward(key,current)
			if current != newCurrent:
				recording[key]["lastUsed"] = current
				recording[key]["current"] = newCurrent 
			if recording[key]["lastUsed"] != null && recording[key]["current"] != recording[key]["end"]:
				if(typeof(rows[key]["output"]) == TYPE_BOOL || rows[key]["output"] is GL_AudioType):
					rows[key]["output"] = recording[key]["list"][recording[key]["current"]]["value"]
				elif(typeof(rows[key]["output"]) == TYPE_FLOAT):
					rows[key]["output"] = lerp(float(recording[key]["list"][recording[key]["lastUsed"]]["value"]),float(recording[key]["list"][recording[key]["current"]]["value"]),remap_time(time,recording[key]["list"][recording[key]["lastUsed"]]["time"],recording[key]["list"][recording[key]["current"]]["time"]))
				elif(typeof(rows[key]["output"]) == TYPE_COLOR):
					rows[key]["output"] = lerp(recording[key]["list"][recording[key]["lastUsed"]]["value"],recording[key]["list"][recording[key]["current"]]["value"],remap_time(time,recording[key]["list"][recording[key]["lastUsed"]]["time"],recording[key]["list"][recording[key]["current"]]["time"]))

func remap_time(value: float, start: float, end: float) -> float:
	if start == end:
		return 0.0 
	return (value - start) / (end - start)

func recursive_traverse_forward(key:String,current:String) -> String:
	var dict = recording[key]["list"][current]
	if dict["time"] > time:
		if dict["back"] != null:
			return recursive_traverse_forward(key,dict["back"])
	if dict["time"] <= time:
		if dict["forward"] != null && recording[key]["list"][dict["forward"]]["time"] <= time:
			return recursive_traverse_forward(key,dict["forward"])
	return current	
	
func _record():
	for key in recording:
		if key == "Recording" || key == "Current Time":
			continue
		var currentSave = recording[key]["current"]
		if currentSave == null:
			var id = "ID_" + str(rng.randi())
			recording[key]["list"][id] = {
				"value":rows[key]["input"],
				"time":time,
				"back":null,
				"forward":null
				}
			recording[key]["current"] = id
			recording[key]["start"] = id
			recording[key]["end"] = id
			rows[key]["output"] = recording[key]["list"][id]["value"]
			continue
		if defaultValues[key] == rows[key]["input"]:
			continue
		elif defaultValues[key] != null:
			defaultValues[key] = null #is this gonna bite me back if I allow null values to pass
		if currentSave != null:
			if time < oldTime: #rewind
				continue #fix pls
			else: #forward
				if recording[key]["list"][currentSave]["time"] == time: #paused recording
					recording[key]["list"][currentSave]["value"] = rows[key]["input"]
					rows[key]["output"] = rows[key]["input"]
				elif recording[key]["list"][currentSave]["time"] < time:
					var id = "ID_" + str(rng.randi())
					if recording[key]["list"][currentSave]["forward"] == null:
						recording[key]["list"][id] = {
						"value":rows[key]["input"],
						"time":time,
						"back":currentSave,
						"forward":null
						}
						recording[key]["list"][currentSave]["forward"] = id
						recording[key]["current"] = id
						recording[key]["end"] = id
					else:
						var forward = recording[key]["list"][currentSave]["forward"]
						recording[key]["list"][id] = {
						"value":rows[key]["input"],
						"time":time,
						"back":currentSave,
						"forward":forward
						}
						recording[key]["list"][forward]["back"] = id
						recording[key]["list"][currentSave]["forward"] = id
						recording[key]["current"] = id
					rows[key]["output"] = recording[key]["list"][id]["value"]
				#else: Somethings messed up and you need to re-traverse
				
				continue
	pass


func _create_row(name:String,input,output,picker:bool,pickDefault,pickFloatMaximum:float):
	super._create_row(name,input,output,picker,pickDefault,pickFloatMaximum)
	if name == "Recording" || name == "Current Time":
			return
	for key in rows:
		if !recording.has(key):
			recording[key] = {"start":null,"end":null,"current":null,"list":{},"lastUsed":null}
