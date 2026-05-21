extends GL_Animatable
class_name GL_Spotlight

var spotLight: SpotLight3D
var omniLight: OmniLight3D

@export var canChangeColor: bool = false
@export var canChangeSize: bool = false
@export var energyMultiplier: float = 300
@export var lerp_speed: float = 5.0
@export var color_lerp_speed: float = 5.0 

var target_energy: float = 0.0
var target_color: Color = Color.WHITE

func _ready():
	super()
	var light = self.get_parent()
	if light is SpotLight3D:
		spotLight = light
	if light is OmniLight3D:
		omniLight = light
	
	if light:
		target_energy = light.light_energy
		target_color = light.light_color

func _process(delta: float) -> void:
	super(delta)
	if spotLight != null:
		spotLight.light_energy = lerp(spotLight.light_energy, target_energy, delta * lerp_speed)
		
		if canChangeColor:
			spotLight.light_color = spotLight.light_color.lerp(target_color, delta * color_lerp_speed)
			
	elif omniLight != null:
		omniLight.light_energy = lerp(omniLight.light_energy, target_energy, delta * lerp_speed)
		
		if canChangeColor:
			omniLight.light_color = omniLight.light_color.lerp(target_color, delta * color_lerp_speed)

func _sent_signals(signal_ID: String, the_signal):
	signal_ID = signal_ID.split("|", true, 1)[-1]
	
	match(signal_ID):
		"intensity":
			if typeof(the_signal) == TYPE_BOOL:
				the_signal = float(the_signal)
			target_energy = max(the_signal, 0.0) * energyMultiplier
			
		"color":
			if canChangeColor && typeof(the_signal) == TYPE_COLOR:
				target_color = the_signal # Just update the target
				
		"size":
			if canChangeSize:
				if typeof(the_signal) == TYPE_BOOL:
					the_signal = float(the_signal)
				if spotLight != null:
					spotLight.spot_angle = clamp(the_signal * 45.0, 0.1, 90.0)
