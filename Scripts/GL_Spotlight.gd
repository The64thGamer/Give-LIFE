extends GL_Animatable
var light:SpotLight3D
@export var canChangeColor:bool = false
@export var canChangeSize:bool = false
@export var energyMultiplier:float = 500

func _ready():
	light = self.get_parent()

func _sent_signals(signal_ID:String,the_signal):
	match(signal_ID):
		"intensity":
			light.light_energy = max(the_signal,0) * energyMultiplier
		"color":
			if canChangeColor:
				light.light_color = the_signal
		"size":
			if canChangeSize:
				light.spot_angle = the_signal * 90
	pass 
