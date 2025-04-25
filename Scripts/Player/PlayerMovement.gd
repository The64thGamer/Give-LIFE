extends CharacterBody3D

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002
const MIN_ZOOM_FOV: float = 5.0
const MAX_ZOOM_FOV: float = 100.0
const ZOOM_SPEED: float = 5.0
const ZOOM_STEP_SPEED: float = 5.0
const TILT_SPEED: float = 0.05
const MAX_TILT: float = 0.6
const MIN_TILT: float = -0.6
const MIN_SPEED_MULTIPLIER: float = 0.5
const COLLISION_CHECK_MIN: float = 0.4
const COLLISION_CHECK_MAX: float = 4.0

const HOLD_THRESHOLD := 0.2
const MIN_SMOOTH_LERP := 0.01
const MAX_SMOOTH_LERP := 2.5
const SMOOTH_LERP_STEP := 0.05

@onready var camera = $Camera3D
@onready var foot_probe: Node3D = $FootProbe

var rotation_y: float = 0.0
var rotation_x: float = 0.0
var rotation_z: float = 0.0
var target_tilt: float = 0.0 
var target_fov: float = 70.0
var speed_mult_target: float = 1.0
var speed_mult: float = 1.0

var smooth_cam: bool = false
var smooth_cam_lerp: float = 1.0

var smooth_held_time: float = 0.0
var is_adjusting_smooth: bool = false
var was_smooth_pressed: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * MOUSE_SENSITIVITY
		rotation_x = clamp(rotation_x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_process_scroll(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_process_scroll(-1)

func _process_scroll(direction: int):
	if Input.is_action_pressed("Cam Zoom Modifier"):
		target_fov = clamp(target_fov - (direction * ZOOM_STEP_SPEED), MIN_ZOOM_FOV, MAX_ZOOM_FOV)

	if Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = clamp(target_tilt + (direction * TILT_SPEED), MIN_TILT, MAX_TILT)

	if is_adjusting_smooth:
		smooth_cam_lerp = clamp(smooth_cam_lerp + (direction * SMOOTH_LERP_STEP), MIN_SMOOTH_LERP, MAX_SMOOTH_LERP)

func _process(delta: float) -> void:
	if Input.is_action_pressed("Smooth Cam"):
		smooth_held_time += delta
		if smooth_held_time >= HOLD_THRESHOLD:
			is_adjusting_smooth = true
			if not smooth_cam:
				smooth_cam = true
	else:
		if was_smooth_pressed:
			if smooth_held_time < HOLD_THRESHOLD:
				smooth_cam = !smooth_cam
				if not smooth_cam:
					# Reset rotations to current camera orientation
					rotation_x = camera.rotation.x
					rotation_y = camera.rotation.y
		smooth_held_time = 0.0
		is_adjusting_smooth = false

	was_smooth_pressed = Input.is_action_pressed("Smooth Cam")

	if !Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = 0

	rotation_z = lerp(rotation_z, target_tilt, delta * ZOOM_SPEED)
	camera.fov = lerp(camera.fov, target_fov, delta * ZOOM_SPEED)

	if smooth_cam:
		camera.rotation = Vector3(
			lerp(camera.rotation.x, rotation_x, delta * smooth_cam_lerp),
			lerp(camera.rotation.y, rotation_y, delta * smooth_cam_lerp),
			rotation_z
		)
	else:
		camera.rotation = Vector3(rotation_x, rotation_y, rotation_z)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2(
		Input.get_action_strength("Move Right") - Input.get_action_strength("Move Left"),
		Input.get_action_strength("Move Forward") - Input.get_action_strength("Move Backward")
	).normalized()

	var forward = -camera.global_basis.z
	var right = camera.global_basis.x
	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	speed_mult_target = get_collision_speed_multiplier()
	speed_mult = lerp(speed_mult, speed_mult_target, delta * 0.5)

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
