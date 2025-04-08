extends GL_Node
var rng : RandomNumberGenerator
var timing : float

func _ready():
	_set_title("Random")
	_create_row("Output",null,0.0,false,null,0)
	_create_row("Time",0.01,null,true,0.01,5)
	rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	pass 

func _process(delta):
	super._process(delta)
	if rows["Time"]["picker"] == true && rows["Time"]["backConnected"] == false:
		rows["Time"]["input"] = rows["Time"]["pickValue"]
	timing -= delta
	if timing <= 0:
		timing = rows["Time"]["input"]
		rows["Output"]["output"] = rng.randf()
	_send_input("Output")
