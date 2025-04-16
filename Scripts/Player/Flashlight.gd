extends SpotLight3D

var size:float = 45
var targetSize:float = 45
const maxSize = 60
const minSize = 5
const minLight = 3
const maxLight = 80

func _process(delta):
	if Input.is_action_just_pressed("Flashlight"):	
			visible = !visible
	size = lerp(size,targetSize,delta*2)
	spot_angle = size
	light_energy = clamp(maxSize - size,minLight,maxLight)
	pass

func _input(event):
	if Input.is_action_pressed("Flashlight Size Modifier"):	
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					targetSize = clamp(targetSize+5,minSize,maxSize)
				MOUSE_BUTTON_WHEEL_DOWN: 
					targetSize = clamp(targetSize-5,minSize,maxSize)
