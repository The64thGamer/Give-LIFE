extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002

const MIN_ZOOM_FOV = 5.0
const MAX_ZOOM_FOV = 100.0
const ZOOM_SPEED = 5.0

const TILT_SPEED = 0.05
const MAX_TILT = 0.6
const MIN_TILT = -0.6
const MIN_SPEED_MULTIPLIER = 0.5

const COLLISION_CHECK_MIN = 0.4
const COLLISION_CHECK_MAX = 4

@onready var camera = $Camera3D
@onready var foot_probe: Node3D = $FootProbe

var rotation_y := 0.0
var rotation_x := 0.0
var rotation_z := 0.0
var target_tilt := 0.0
var target_fov := 70.0
var speed_mult_target = 1.0
var speed_mult = 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
	
	if !Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = 0
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_process_scroll(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_process_scroll(-1)

func _process_scroll(direction: int):
	if Input.is_action_pressed("Cam Zoom Modifier"):
		target_fov = clamp(target_fov - direction * 5.0, MIN_ZOOM_FOV, MAX_ZOOM_FOV)

	if Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = clamp(target_tilt + direction * TILT_SPEED, MIN_TILT, MAX_TILT)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Camera updates
	rotation_z = lerp(rotation_z, target_tilt, delta * ZOOM_SPEED)
	camera.fov = lerp(camera.fov, target_fov, delta * ZOOM_SPEED)
	camera.rotation = Vector3(rotation_x, rotation_y, rotation_z)

	# Movement input (relative to camera)
	var input_dir := Vector2(
		Input.get_action_strength("Move Right") - Input.get_action_strength("Move Left"),
		Input.get_action_strength("Move Forward") - Input.get_action_strength("Move Backward")
	).normalized()

	var forward = -camera.global_basis.z
	var right = camera.global_basis.x
	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	speed_mult_target = get_collision_speed_multiplier()
	speed_mult = lerp(speed_mult,speed_mult_target,delta*0.5)

	if direction:
		velocity.x = direction.x * SPEED * speed_mult
		velocity.z = direction.z * SPEED * speed_mult
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func get_collision_speed_multiplier() -> float:
	var shortest_dist := COLLISION_CHECK_MAX
	for ray in foot_probe.get_children():
		if ray is RayCast3D and ray.is_colliding():
			var dist = ray.get_collision_point().distance_to(ray.global_transform.origin)
			if dist < shortest_dist:
				shortest_dist = dist
	

	return clamp((shortest_dist - COLLISION_CHECK_MIN) / (COLLISION_CHECK_MAX - COLLISION_CHECK_MIN), MIN_SPEED_MULTIPLIER, 1.0)
