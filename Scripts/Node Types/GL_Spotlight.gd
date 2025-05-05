extends GL_Animatable
var light:SpotLight3D
@export var canChangeColor:bool = false
@export var canChangeSize:bool = false
@export var energyMultiplier:float = 300
@export var lerp_speed: float = 5.0
var visible_energy: float = 0.0
var target_energy: float = 0.0

func _ready():
	light = self.get_parent()
	visible_energy = light.light_energy
	target_energy = visible_energy

func _process(delta: float) -> void:
	light.light_energy = lerp(light.light_energy, target_energy, delta * lerp_speed)

func _sent_signals(signal_ID:String,the_signal):
	match(signal_ID):
		"intensity":
			if typeof(the_signal) == TYPE_BOOL:
				the_signal = the_signal * 1.0
			target_energy = max(the_signal, 0.0) * energyMultiplier
		"color":
			if canChangeColor:
				light.light_color = the_signal
		"size":
			if canChangeSize:
				if typeof(the_signal) == TYPE_BOOL:
					the_signal = the_signal * 1.0
				light.spot_angle = clamp(the_signal * 45.0,0.1,90)
	pass 
