extends GL_Animatable
class_name GL_Lights

var lights: Array[Light3D] = []

@export var canChangeColor: bool = false
@export var canChangeSize: bool = false
@export var energyMultiplier: float = 300
@export var lerp_speed: float = 5.0
@export var color_lerp_speed: float = 5.0

var target_energy: float = 0.0
var target_color: Color = Color.WHITE

func _ready():
	super()
	for child in self.get_children():
			if child is Light3D:
				lights.append(child)
	if lights.size() > 0:
		target_energy = lights[0].light_energy
		target_color = lights[0].light_color

func _process(delta: float) -> void:
	super(delta)
	for light in lights:
		light.light_energy = lerp(light.light_energy, target_energy, delta * lerp_speed)
		if canChangeColor:
			light.light_color = light.light_color.lerp(target_color, delta * color_lerp_speed)

func _sent_signals(signal_ID: String, the_signal):
	signal_ID = signal_ID.split("|", true, 1)[-1]
	
	match(signal_ID):
		"intensity":
			if typeof(the_signal) == TYPE_BOOL:
				the_signal = float(the_signal)
			target_energy = max(the_signal, 0.0) * energyMultiplier
			
		"color":
			if canChangeColor && typeof(the_signal) == TYPE_COLOR:
				target_color = the_signal
				
		"size":
			if canChangeSize:
				if typeof(the_signal) == TYPE_BOOL:
					the_signal = float(the_signal)
				for light in lights:
					if light is SpotLight3D:
						light.spot_angle = clamp(the_signal * 45.0, 0.1, 90.0)
