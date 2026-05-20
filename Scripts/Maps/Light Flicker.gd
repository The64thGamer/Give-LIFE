extends Light3D 

@export var lerp_speed: float = 10.0       
@export var change_rate: float = 0.1         
@export var polarization: float = 2.0        
@export var min_energy: float = 0.2         

var _target_energy: float
var _base_energy: float
var _timer: float = 0.0

func _ready() -> void:
	_base_energy = light_energy
	_target_energy = light_energy

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = change_rate
		_pick_target()
	light_energy = lerp(light_energy, _target_energy, lerp_speed * delta)

func _pick_target() -> void:
	var t := randf()
	t = pow(t, 1.0 / max(polarization, 0.01))
	if randf() < 0.5:
		t = 1.0 - t
	_target_energy = lerp(min_energy, _base_energy, t)
