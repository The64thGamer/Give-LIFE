extends CharacterBody3D
class_name Player

const SPEED: float = 5.0
const SPRINT_SPEED: float = 9.0
const CROUCH_SPEED: float = 2.0
const JUMP_VELOCITY: float = 4.5
const MOUSE_SENSITIVITY: float = 0.002
const CSTICK_SENSITIVITY: float = 0.2
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
const HOLD_THRESHOLD = 0.2
const MIN_SMOOTH_LERP = 0.01
const MAX_SMOOTH_LERP = 2.5
const SMOOTH_LERP_STEP = 0.05
const MIN_ACCEL_LERP = 0.01
const MAX_ACCEL_LERP = 2.5
const ACCEL_LERP_STEP = 0.05

const AIR_STRAFE_BOOST: float = 5
const AIR_ANGLE_TRACK_SPEED: float = 120.0
const AIR_ANGLE_TOLERANCE: float = 55.0
const AIR_DRAG_OUT_OF_WINDOW: float = 4
const AIR_KEY_BIAS: float = 1

const PLAYER_HEIGHT: float = 3.0
const CROUCH_HEIGHT: float = 1.2
const CAM_OFFSET: float = -0.1
const CROUCH_LERP: float = 10.0

@onready var camera = $Camera3D
@onready var foot_probe: Node3D = $FootProbe
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interact_ray: RayCast3D = $Camera3D/RayCast3D
@onready var nightLight: NightLight = $"Camera3D/Night Light"

@export var night_mode: bool = false
@export var frozen_mode: bool = false
@export var debug_mode: bool = false

var rotation_y: float = 0.0
var rotation_x: float = 0.0
var rotation_z: float = 0.0
var target_tilt: float = 0.0
var target_fov: float = 70.0
var speed_mult_target: float = 1.0
var speed_mult: float = 1.0

var smooth_cam: bool = false
var smooth_cam_lerp: float = 1.0
var smooth_move: bool = false
var accel_lerp: float = 1.0
var fly_mode: bool = false

var smooth_held_time: float = 0.0
var was_smooth_pressed: bool = false
var is_adjusting_smooth: bool = false

var move_held_time: float = 0.0
var was_move_pressed: bool = false
var is_adjusting_move: bool = false

var settings_autorun: bool = false

var is_crouched: bool = false

var air_move_angle: float = 0.0
var air_horiz_speed: float = 0.0
var is_airborne: bool = false
signal construction_toggled(is_active: bool)
var construction_mode: bool = false
var _spawn_grace_frames: int = 10

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

	if collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = PLAYER_HEIGHT
		collision_shape.position.y = _capsule_offset_y()

	var t = (collision_shape.shape.height - CROUCH_HEIGHT) / (PLAYER_HEIGHT - CROUCH_HEIGHT)
	var target_cam_y = lerp(CROUCH_HEIGHT + CAM_OFFSET, PLAYER_HEIGHT + CAM_OFFSET, t)
	camera.position.y = target_cam_y

	rotation_x = camera.rotation.x
	rotation_y = camera.rotation.y

func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation_y -= event.relative.x * MOUSE_SENSITIVITY
			rotation_x = clamp(rotation_x - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-80), deg_to_rad(80))
		if Input.is_action_just_pressed("Scroll Up (Mouse)"):
			_process_scroll(1)
		if Input.is_action_just_pressed("Scroll Down (Mouse)"):
			_process_scroll(-1)
		if event.is_action_pressed("Interact"):
			if interact_ray.is_colliding() && construction_mode:
				var collider = interact_ray.get_collider()
				if collider.has_method("interact"):
					collider.interact()
				
		if Input.is_action_just_pressed("Toggle Construction"):
			construction_mode = !construction_mode
			_notify_animatables(construction_mode)


func _notify_animatables(is_active: bool) -> void:
	construction_toggled.emit(is_active)
	var animatables = get_tree().get_nodes_in_group("Animatable")
	for node in animatables:
		if node.has_method("on_construction_toggled"):
			node.on_construction_toggled(is_active)

func freeze_player()-> void:
	frozen_mode = true
	
func unfreeze_player()-> void:
	frozen_mode = false

func _process(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	
	var look_x = Input.get_action_strength("Look Right") - Input.get_action_strength("Look Left")
	var look_y = Input.get_action_strength("Look Down") - Input.get_action_strength("Look Up")
	if abs(look_x) > 0.05 or abs(look_y) > 0.05:
		rotation_y -= look_x * CSTICK_SENSITIVITY * 20.0 * delta
		rotation_x = clamp(rotation_x - look_y * CSTICK_SENSITIVITY * 20.0 * delta, deg_to_rad(-80), deg_to_rad(80))

	if Input.is_action_pressed("Scroll Up"):
		_process_scroll(1)
	if Input.is_action_pressed("Scroll Down"):
		_process_scroll(-1)

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
					rotation_x = camera.rotation.x
					rotation_y = camera.rotation.y
		smooth_held_time = 0.0
		is_adjusting_smooth = false

	was_smooth_pressed = Input.is_action_pressed("Smooth Cam")

	if Input.is_action_pressed("Smooth Movement"):
		move_held_time += delta
		if move_held_time >= HOLD_THRESHOLD:
			is_adjusting_move = true
			if not smooth_move:
				smooth_move = true
	else:
		if was_move_pressed:
			if move_held_time < HOLD_THRESHOLD:
				smooth_move = !smooth_move
		move_held_time = 0.0
		is_adjusting_move = false

	was_move_pressed = Input.is_action_pressed("Smooth Movement")

	if Input.is_action_just_pressed("Fly") && !night_mode:
		fly_mode = !fly_mode

	if not Input.is_action_pressed("Cam Tilt Modifier"):
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

	var t = (collision_shape.shape.height - CROUCH_HEIGHT) / (PLAYER_HEIGHT - CROUCH_HEIGHT)
	var target_cam_y = lerp(CROUCH_HEIGHT + CAM_OFFSET, PLAYER_HEIGHT + CAM_OFFSET, t)
	var cam_pos = camera.position
	cam_pos.y = lerp(cam_pos.y, target_cam_y, delta * CROUCH_LERP)
	camera.position = cam_pos

func _capsule_offset_y() -> float:
	return collision_shape.shape.height / 2.0

func _wants_crouch() -> bool:
	if fly_mode:
		return false
	if night_mode:
		return not Input.is_action_pressed("Sprint")
	return Input.is_action_pressed("Crouch")


func _can_stand_up() -> bool:
	var world = get_viewport().find_world_3d()
	if world == null:
		return false
	var space_state = world.direct_space_state
	if space_state == null:
		return false

	var feet_y = global_transform.origin.y
	var ray_start = Vector3(global_transform.origin.x, feet_y + 0.1, global_transform.origin.z)
	var ray_end = Vector3(global_transform.origin.x, feet_y + PLAYER_HEIGHT, global_transform.origin.z)

	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	return result.is_empty()


func _process_scroll(direction: int):
	if Input.is_action_pressed("Cam Zoom Modifier"):
		target_fov = clamp(target_fov - (direction * ZOOM_STEP_SPEED), MIN_ZOOM_FOV, MAX_ZOOM_FOV)
	if Input.is_action_pressed("Cam Tilt Modifier"):
		target_tilt = clamp(target_tilt + (direction * TILT_SPEED), MIN_TILT, MAX_TILT)
	if is_adjusting_smooth:
		smooth_cam_lerp = clamp(smooth_cam_lerp + (direction * SMOOTH_LERP_STEP), MIN_SMOOTH_LERP, MAX_SMOOTH_LERP)
	if is_adjusting_move:
		accel_lerp = clamp(accel_lerp + (direction * ACCEL_LERP_STEP), MIN_ACCEL_LERP, MAX_ACCEL_LERP)


func _physics_process(delta: float) -> void:
	if _spawn_grace_frames > 0:
		_spawn_grace_frames -= 1
		velocity = Vector3.ZERO
		return
		
	if not is_on_floor() and not fly_mode:
		velocity.y += get_gravity().y * delta

	var input_dir = Vector2.ZERO
	var currentSpeed = SPEED
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not frozen_mode:
		input_dir = Vector2(
			Input.get_action_strength("Move Right") - Input.get_action_strength("Move Left"),
			Input.get_action_strength("Move Forward") - Input.get_action_strength("Move Backward")
		).normalized()
	
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not fly_mode and not frozen_mode:
		velocity.y = JUMP_VELOCITY
		var horiz = Vector3(velocity.x, 0.0, velocity.z)
		air_horiz_speed = horiz.length()
		
		if air_horiz_speed > 0.1:
			air_move_angle = atan2(-horiz.x, -horiz.z) 
		else:
			air_move_angle = camera.global_rotation.y
			air_horiz_speed = 0.0
		is_airborne = true

	if Input.is_action_pressed("Sprint") or settings_autorun:
		currentSpeed = SPRINT_SPEED

		var crouch_button_held = Input.is_action_pressed("Crouch")
		if is_crouched and not fly_mode:
			if crouch_button_held or not night_mode:
				currentSpeed = CROUCH_SPEED
	var forward = -camera.global_basis.z
	var right = camera.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction = (right * input_dir.x + forward * input_dir.y).normalized()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if fly_mode:
			var vertical_input = Input.get_action_strength("Move Up") - Input.get_action_strength("Move Down")
			var target_y = vertical_input * currentSpeed
			if smooth_move:
				velocity.y = lerp(velocity.y, target_y, delta * accel_lerp)
			else:
				velocity.y = target_y

	if is_on_floor() or fly_mode:
		speed_mult_target = get_collision_speed_multiplier()
		speed_mult = lerp(speed_mult, speed_mult_target, delta * 5.0) 
	else:
		speed_mult = lerp(speed_mult, 1.0, delta * 2.0)

	if is_on_floor() and is_airborne and velocity.y <= 0.0:
		is_airborne = false

	if (is_on_floor() and not is_airborne) or fly_mode:
		var target_vel = Vector3.ZERO
		if direction:
			target_vel.x = direction.x * currentSpeed * speed_mult
			target_vel.z = direction.z * currentSpeed * speed_mult
		if smooth_move:
			velocity.x = lerp(velocity.x, target_vel.x, delta * accel_lerp)
			velocity.z = lerp(velocity.z, target_vel.z, delta * accel_lerp)
		else:
			velocity.x = target_vel.x
			velocity.z = target_vel.z
		if not direction and not fly_mode:
			if smooth_move:
				velocity.x = lerp(velocity.x, 0.0, delta * accel_lerp)
				velocity.z = lerp(velocity.z, 0.0, delta * accel_lerp)
			else:
				velocity.x = move_toward(velocity.x, 0, currentSpeed)
				velocity.z = move_toward(velocity.z, 0, currentSpeed)
	else:
		if is_airborne:
			_apply_air_strafe(direction, delta)

	move_and_slide()

	var wants = _wants_crouch()

	if wants and not is_crouched:
		is_crouched = true
	elif not wants and is_crouched:
		if _can_stand_up():
			is_crouched = false

	var target_height = CROUCH_HEIGHT if is_crouched else PLAYER_HEIGHT

	if collision_shape.shape is CapsuleShape3D:
		var new_height = lerp(collision_shape.shape.height, target_height, delta * CROUCH_LERP)
		collision_shape.shape.height = new_height
		collision_shape.position.y = _capsule_offset_y()


func get_collision_speed_multiplier() -> float:
	var shortest_dist = COLLISION_CHECK_MAX
	for ray in foot_probe.get_children():
		if ray is RayCast3D and ray.is_colliding():
			var dist = ray.get_collision_point().distance_to(ray.global_transform.origin)
			if dist < shortest_dist:
				shortest_dist = dist
	return clamp((shortest_dist - COLLISION_CHECK_MIN) / (COLLISION_CHECK_MAX - COLLISION_CHECK_MIN), MIN_SPEED_MULTIPLIER, 1.0)

func _apply_air_strafe(wish_dir: Vector3, delta: float) -> void:
	var horiz_vel = Vector3(velocity.x, 0.0, velocity.z)
	air_horiz_speed = horiz_vel.length()

	if air_horiz_speed < 0.01:
		if _debug_instance: _debug_mesh.clear_surfaces()
		return

	var cam_yaw = camera.global_rotation.y
	var track_target = air_move_angle 

	if wish_dir.length() > 0.1:
		var cam_forward = -camera.global_basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var is_pressing_forward = wish_dir.dot(cam_forward) > 0.5
		
		if is_pressing_forward:
			track_target = cam_yaw
		else:
			var key_angle = atan2(-wish_dir.x, -wish_dir.z)
			var key_diff = _angle_diff(key_angle, cam_yaw)
			track_target = cam_yaw + key_diff * AIR_KEY_BIAS

	var steering_diff = abs(_angle_diff(track_target, air_move_angle))
	var tolerance_rad = deg_to_rad(AIR_ANGLE_TOLERANCE)

	if steering_diff > 0.001 and steering_diff <= tolerance_rad:
		# Closer to tolerance = higher reward
		var reward_factor = steering_diff / tolerance_rad 
		air_horiz_speed += AIR_STRAFE_BOOST * reward_factor * delta
	
	if steering_diff > tolerance_rad:
		var overflow = clamp((steering_diff - tolerance_rad) / deg_to_rad(90.0), 0.0, 1.0)
		air_horiz_speed = max(air_horiz_speed - air_horiz_speed * AIR_DRAG_OUT_OF_WINDOW * overflow * delta, 0.0)

	var angle_to_target = _angle_diff(track_target, air_move_angle)
	var max_step = deg_to_rad(AIR_ANGLE_TRACK_SPEED) * delta
	air_move_angle += clamp(angle_to_target, -max_step, max_step)

	if debug_mode:
		var debug_origin = camera.global_position + (-camera.global_basis.z * 1.5) + (Vector3.DOWN * 0.3)
		var lines_to_draw = []

		var target_dir = Vector3(-sin(track_target), 0, -cos(track_target))
		var blue_color = Color.CYAN if (steering_diff > 0.1 and steering_diff <= tolerance_rad) else Color.BLUE
		lines_to_draw.append({"start": debug_origin, "end": debug_origin + target_dir * 0.5, "color": blue_color})

		var move_dir = Vector3(-sin(air_move_angle), 0, -cos(air_move_angle))
		lines_to_draw.append({"start": debug_origin, "end": debug_origin + move_dir * 0.5, "color": Color.GREEN})

		var l_bound = Vector3(-sin(air_move_angle + tolerance_rad), 0, -cos(air_move_angle + tolerance_rad))
		var r_bound = Vector3(-sin(air_move_angle - tolerance_rad), 0, -cos(air_move_angle - tolerance_rad))
		lines_to_draw.append({"start": debug_origin, "end": debug_origin + l_bound * 0.4, "color": Color.RED})
		lines_to_draw.append({"start": debug_origin, "end": debug_origin + r_bound * 0.4, "color": Color.RED})

		_draw_debug_lines(lines_to_draw)

	velocity.x = -sin(air_move_angle) * air_horiz_speed
	velocity.z = -cos(air_move_angle) * air_horiz_speed

func _angle_diff(target: float, current: float) -> float:
	var diff = fmod(target - current, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff
var _debug_mesh: ImmediateMesh
var _debug_instance: MeshInstance3D

func _draw_debug_lines(lines: Array):
	# Create the node once if it doesn't exist
	if not _debug_instance:
		_debug_instance = MeshInstance3D.new()
		_debug_mesh = ImmediateMesh.new()
		var mat = StandardMaterial3D.new()
		
		_debug_instance.mesh = _debug_mesh
		_debug_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true # Allows per-line colors
		mat.no_depth_test = true
		_debug_instance.material_override = mat
		
		get_tree().root.add_child.call_deferred(_debug_instance)

	_debug_mesh.clear_surfaces()
	_debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for line in lines:
		_debug_mesh.surface_set_color(line.color)
		_debug_mesh.surface_add_vertex(line.start)
		_debug_mesh.surface_add_vertex(line.end)
		
	_debug_mesh.surface_end()

func on_settings_applied(settings: Dictionary) -> void:
	settings_autorun = settings["auto_run"]
