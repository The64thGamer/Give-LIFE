extends GL_Animatable
var light: OmniLight3D

@export var number: int = 0  # index of this light
@export var total: int = 1   # total number of lights in the string

@export var energyMultiplier: float = 200
@export var baseEnergy: float = 0.0  # min energy when "off"
@export var lerp_speed: float = 5.0  # How fast intensity adjusts
var visible_energy: float = 0.0

var current_chase: float = 0.0
var current_grouping: float = 1.0
var current_intensity: float = 1.0

func _ready():
	light = self.get_parent()
	visible_energy = light.light_energy


func _sent_signals(signal_ID: String, the_signal):
	match signal_ID:
		"intensity":
			if typeof(the_signal) == TYPE_BOOL:
				the_signal = the_signal * 1.0
			current_intensity = clamp(the_signal, 0.0, 1.0)
			_update_light()
		
		"chase":
			current_chase = fmod(the_signal,1)
			_update_light()

		"grouping":
			current_grouping = clamp(the_signal, 0.0, 1.0)
			_update_light()
			
func _update_light():
	if total <= 0:
		return

	var shifted_index = (number + int(round(current_chase * total))) % total

	var on_ratio: float = current_grouping
	var is_on: bool

	if on_ratio < 0.5:
		var spacing = int(floor(1.0 / max(on_ratio, 0.001)))
		is_on = shifted_index % spacing == 0
	else:
		var inverse_ratio = 1.0 - on_ratio
		var spacing = int(floor(1.0 / max(inverse_ratio, 0.001)))
		is_on = shifted_index % spacing != 0

	var target_energy = (baseEnergy + current_intensity * energyMultiplier) if is_on else baseEnergy
	visible_energy = target_energy  # or interpolate here immediately if you prefer
