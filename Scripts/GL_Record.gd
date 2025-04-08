extends GL_Node
var timer:float
const sampleRate = 0.1
var recording:Dictionary
var oldTime:float = 0.000030042452 #sorta random number

func _ready():
	super._ready()
	_set_title("Record")
	special_condition = "Record Node"
	_create_row("Recording",false,null,true,false,0)
	_create_row("Current Time",0.0,0.0,false,0,0)
	_update_visuals()
	pass 

func _process(delta):
	super._process(delta)
	for key in rows:
		rows[key]["output"] = rows[key]["input"]
	apply_pick_values()
	for key in rows:
		_send_input(key)
	
	if recording:
		if timer <= 0:
			timer = sampleRate
			_traverse()
			_record()
		timer -= delta
	oldTime = float(rows["Current Time"]["output"])

func _traverse():
	if float(rows["Current Time"]["output"]) == oldTime:
		return
	for key in recording:
		if recording[key]["start"] == null || recording[key]["end"] == null:
			continue
		if recording[key]["current"] == null:
			recording[key]["current"] = recording[key]["start"]
		var current = recording[key]["list"][recording[key]["current"]]
func _record():
	pass

func _create_row(name:String,input,output,picker:bool,pickDefault,pickFloatMaximum:float):
	super._create_row(name,input,output,picker,pickDefault,pickFloatMaximum)
	for key in rows:
		if !recording.has(key):
			recording[key] = {"start":null,"end":null,"current":null,"list":{}}
