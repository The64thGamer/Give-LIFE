extends GL_Node
var rng : RandomNumberGenerator

func _ready():
	_set_title("Random")
	_create_row("Output",null,0.0,false,null,0)
	rng = RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec()
	pass 

func _process(delta):
	super._process(delta)
	rows["Output"]["output"] = rng.randf()
	_send_input("Output")
