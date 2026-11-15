extends CharacterBody3D

const MetalDetectorVisual = preload("res://scripts/player/metal_detector_visual.gd")

# Echoes Beyond Earth - Photorealistic Third-Person Astronaut Minion Simulator
# Controls a recognizable Minion astronaut wearing an authentic NASA EVA spacesuit:
# 1. Third-Person Camera with smooth orbit, terrain collision, and zoom (1.8m - 6.5m)
# 2. Authentic Minion locomotion & spacesuit waddle under exact 1.62 m/s² lunar gravity
# 3. Apollo low-gravity loping and high-airtime jumping
# 4. Footprints with corrugated overboot tread, vacuum ballistic dust, and vacuum acoustics
# 5. Full compatibility with equipment excavation, cleaning, and scientific sample inspection

# Physics Exports
@export var walk_speed: float = 1.6
@export var lope_speed: float = 3.2
@export var jump_velocity: float = 2.4 # Real lunar hop (~1.77m apex under 1.62 m/s² gravity)
@export var gravity: float = 1.62 # Exact real NASA Moon gravitation (1.62 m/s², ~0.166g)
@export var mouse_sensitivity: float = 0.0028
@export var min_pitch: float = deg_to_rad(-62.0)
@export var max_pitch: float = deg_to_rad(65.0)

# Nodes
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var torso: Node3D = $Visuals/Torso
@onready var head: Node3D = $Visuals/Torso/Head
@onready var left_arm: Node3D = $Visuals/Torso/LeftArm
@onready var right_arm: Node3D = $Visuals/Torso/RightArm
@onready var left_leg: Node3D = $Visuals/Torso/LeftLeg
@onready var right_leg: Node3D = $Visuals/Torso/RightLeg
@onready var scanner_device: Node3D = $Visuals/Torso/RightArm/ScannerDevice
@onready var scanner_screen: MeshInstance3D = $Visuals/Torso/RightArm/ScannerDevice/Screen
var status_led: MeshInstance3D = null
var detector_visual: MetalDetectorVisual = null
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var left_eyelid: MeshInstance3D = get_node_or_null("Visuals/Torso/Head/LeftGoggleRing/LeftEyelid")
@onready var right_eyelid: MeshInstance3D = get_node_or_null("Visuals/Torso/Head/RightGoggleRing/RightEyelid")
@onready var mouth: MeshInstance3D = get_node_or_null("Visuals/Torso/Head/Mouth")

# Facial Expression System (Neutral, Happy, Calm)
enum FacialExpression {
	NEUTRAL,
	HAPPY,
	CALM
}
var current_expression: FacialExpression = FacialExpression.NEUTRAL
var _expression_timer: float = 20.0 # Automatic transition every 15-30s
var _target_smile: float = 0.0
var _current_smile: float = 0.0
var _target_calm: float = 0.0 # 0.0 = open, 0.4 = calm 40% closed eyelids
var _current_calm: float = 0.0

# Eye Blinking System
var _blink_timer: float = 3.2
var _is_blinking: bool = false
var _blink_elapsed: float = 0.0
const BLINK_CLOSE_TIME: float = 0.08
const BLINK_HOLD_TIME: float = 0.03
const BLINK_OPEN_TIME: float = 0.10
const BLINK_TOTAL_TIME: float = BLINK_CLOSE_TIME + BLINK_HOLD_TIME + BLINK_OPEN_TIME
var _left_eyelid_mat: ShaderMaterial = null
var _right_eyelid_mat: ShaderMaterial = null

# Locomotion, Animation & Camera States
var is_first_person: bool = false # Third-person exploration default
var is_loping_mode: bool = true # Apollo low-gravity kangaroo lope default
var is_mouse_captured: bool = false
var walk_cycle: float = 0.0
var idle_time: float = 0.0
var jump_anim_weight: float = 0.0
var landing_squash: float = 0.0
var current_anim_state: String = "idle"
var step_cycle_tracker: float = 0.0
var last_foot_step: bool = false # false = left, true = right
var scanner_raise_weight: float = 0.0
var exertion_level: float = 0.0
var prev_vertical_velocity: float = 0.0

# Jump and Floor Robustness (Prevents getting stuck on uneven lunar terrain)
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_jumping: bool = false
var air_time: float = 0.0
var is_moving_horizontal: bool = false

# Stable interaction state (prevents rubberbanding/displacement during digging, cleaning & inspection)
var is_interacting: bool = false
var interaction_anchor: Vector3 = Vector3.ZERO
var interaction_target: Vector3 = Vector3.ZERO

# Subsystems
var audio_system: Node = null
var dust_system: Node = null
var footprint_system: Node = null

# Planetary Surface & Gravity Alignment (spherical planets such as Mars; flat levels keep Vector3.UP)
var current_up_vector: Vector3 = Vector3.UP
var total_distance_travelled_km: float = 0.0
var _prev_planet_pos: Vector3 = Vector3.ZERO

func align_to_normal(normal: Vector3) -> void:
	current_up_vector = normal.normalized()
	up_direction = current_up_vector
	var cur_up = global_transform.basis.y
	if cur_up.cross(current_up_vector).length() > 0.001:
		var align_axis = cur_up.cross(current_up_vector).normalized()
		var align_angle = cur_up.angle_to(current_up_vector)
		global_rotate(align_axis, align_angle)

func get_distance_travelled_km() -> float:
	return total_distance_travelled_km

# Agreed public interface for Scanner & External systems
func get_scan_origin() -> Vector3:
	if is_inside_tree():
		return global_position
	return position

func begin_interaction(anchor_pos: Vector3, look_at_target: Vector3) -> void:
	is_interacting = true
	interaction_anchor = anchor_pos
	interaction_target = look_at_target
	velocity.x = 0.0
	velocity.z = 0.0

func end_interaction() -> void:
	is_interacting = false
	velocity.x = 0.0
	velocity.z = 0.0

func is_in_interaction() -> bool:
	return is_interacting

func _ready() -> void:
	InputSetup.ensure()
	mouse_sensitivity = SettingsStore.mouse_sensitivity_value()
	capture_mouse()
	_setup_third_person_camera()
	_setup_eyelids()
	_setup_metal_detector()
	call_deferred("_connect_subsystems")

func _setup_metal_detector() -> void:
	if not scanner_device:
		return
	scanner_device.position = Vector3(0.02, -0.28, 0.06)
	scanner_device.rotation = Vector3.ZERO
	for child in scanner_device.get_children():
		child.queue_free()
	
	detector_visual = MetalDetectorVisual.new()
	detector_visual.name = "DetectorVisual"
	scanner_device.add_child(detector_visual)
	detector_visual.build()
	
	scanner_screen = detector_visual.screen_mesh
	status_led = detector_visual.status_led

func _setup_eyelids() -> void:
	_apply_eyelid_coverage(0.0)

func _process(delta: float) -> void:
	_update_facial_expressions(delta)
	_update_eye_blinking(delta)

func _update_facial_expressions(delta: float) -> void:
	_expression_timer -= delta
	if _expression_timer <= 0.0:
		_expression_timer = randf_range(16.0, 28.0)
		var candidates = []
		for expr in [FacialExpression.NEUTRAL, FacialExpression.HAPPY, FacialExpression.CALM]:
			if expr != current_expression:
				candidates.append(expr)
		if not candidates.is_empty():
			set_expression(candidates[randi() % candidates.size()])
	
	_current_smile = lerp(_current_smile, _target_smile, 4.0 * delta)
	_current_calm = lerp(_current_calm, _target_calm, 4.0 * delta)
	
	if mouth and is_instance_valid(mouth):
		mouth.set("blend_shapes/smile", _current_smile)

func set_expression(expr: FacialExpression) -> void:
	current_expression = expr
	match expr:
		FacialExpression.NEUTRAL:
			_target_smile = 0.0
			_target_calm = 0.0
		FacialExpression.HAPPY:
			_target_smile = 1.0
			_target_calm = 0.0
		FacialExpression.CALM:
			_target_smile = 0.60
			_target_calm = 0.40

func _update_eye_blinking(delta: float) -> void:
	if not left_eyelid or not right_eyelid:
		return
	
	if not _is_blinking:
		_blink_timer -= delta
		if _blink_timer <= 0.0:
			_trigger_blink()
		else:
			_apply_eyelid_coverage(_current_calm)
		return
	
	_blink_elapsed += delta
	if _blink_elapsed <= BLINK_CLOSE_TIME:
		# Closing phase (0 to BLINK_CLOSE_TIME): eyelids drop down to cover eyeball
		var t = _blink_elapsed / BLINK_CLOSE_TIME
		var curve = sin(t * PI * 0.5)
		var coverage = lerp(_current_calm, 1.0, curve)
		_apply_eyelid_coverage(coverage)
	elif _blink_elapsed <= BLINK_CLOSE_TIME + BLINK_HOLD_TIME:
		# Eyes fully closed
		_apply_eyelid_coverage(1.0)
	elif _blink_elapsed <= BLINK_TOTAL_TIME:
		# Reopening phase
		var t = (_blink_elapsed - BLINK_CLOSE_TIME - BLINK_HOLD_TIME) / BLINK_OPEN_TIME
		var curve = sin(t * PI * 0.5)
		var coverage = lerp(1.0, _current_calm, curve)
		_apply_eyelid_coverage(coverage)
	else:
		# Blink complete
		_is_blinking = false
		_blink_elapsed = 0.0
		_apply_eyelid_coverage(_current_calm)
		if randf() < 0.15:
			# 15% chance of expressive double-blink
			_blink_timer = 0.08
		else:
			_blink_timer = randf_range(3.0, 5.5)

func _cache_eyelid_materials() -> void:
	if left_eyelid and not _left_eyelid_mat:
		_left_eyelid_mat = left_eyelid.get_surface_override_material(0) as ShaderMaterial
	if right_eyelid and not _right_eyelid_mat:
		_right_eyelid_mat = right_eyelid.get_surface_override_material(0) as ShaderMaterial

func _apply_eyelid_coverage(c: float) -> void:
	if not left_eyelid or not right_eyelid:
		return
	_cache_eyelid_materials()
	var is_vis: bool = (c > 0.02)
	left_eyelid.visible = is_vis
	right_eyelid.visible = is_vis
	if _left_eyelid_mat:
		_left_eyelid_mat.set_shader_parameter("coverage", c)
	if _right_eyelid_mat:
		_right_eyelid_mat.set_shader_parameter("coverage", c)

func _trigger_blink() -> void:
	if not left_eyelid or not right_eyelid:
		return
	_is_blinking = true
	_blink_elapsed = 0.0
	left_eyelid.visible = true
	right_eyelid.visible = true

func _setup_third_person_camera() -> void:
	camera_pivot.position = Vector3(0, 0.85, 0)
	spring_arm.spring_length = 3.2
	spring_arm.collision_mask = 1 # Prevent camera clipping into lunar terrain or boulders

func _connect_subsystems() -> void:
	# Vacuum audio
	audio_system = get_tree().get_first_node_in_group("vacuum_audio")
	if not audio_system:
		var audio_script = load("res://scripts/player/vacuum_audio_system.gd")
		if audio_script:
			audio_system = Node.new()
			audio_system.set_script(audio_script)
			audio_system.add_to_group("vacuum_audio")
			add_child(audio_system)
	
	# Ballistic dust
	dust_system = get_tree().get_first_node_in_group("ballistic_dust")
	if not dust_system:
		var dust_script = load("res://scripts/environment/ballistic_dust_system.gd")
		if dust_script:
			dust_system = Node3D.new()
			dust_system.set_script(dust_script)
			dust_system.add_to_group("ballistic_dust")
			get_parent().add_child(dust_system)
	
	# Footprints
	footprint_system = get_tree().get_first_node_in_group("footprints")
	if not footprint_system:
		var fp_script = load("res://scripts/environment/footprint_system.gd")
		if fp_script:
			footprint_system = Node3D.new()
			footprint_system.set_script(fp_script)
			footprint_system.add_to_group("footprints")
			get_parent().add_child(footprint_system)
	
	# Floor adhesion on uneven lunar regolith: prevents unwanted floating over slopes and craters
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(65.0)
	floor_stop_on_slope = true
	
	if dust_system and dust_system.has_method("set_gravity"):
		dust_system.set_gravity(gravity)

func update_gravity(new_gravity: float) -> void:
	gravity = new_gravity
	if gravity > 2.5: # Mars gravity ~3.71 m/s²
		jump_velocity = 3.0 # Calibrated ~1.21m apex under 3.71 m/s² Martian gravity
		walk_speed = 1.8
		lope_speed = 3.6
	if dust_system and dust_system.has_method("set_gravity"):
		dust_system.set_gravity(gravity)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer_timer = 0.22
	
	# Mouse Orbit & Zoom Controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_interacting and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				capture_mouse()
		# Smooth camera zoom in/out with mouse wheel
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.35, 1.8, 6.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.35, 1.8, 6.5)
	
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_pitch, max_pitch)
	
	# Toggle Gait mode (Walk vs Loping) with [C]
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_C:
		is_loping_mode = not is_loping_mode
		if audio_system and audio_system.has_method("play_comm_click"):
			audio_system.play_comm_click()
	
	# View mode toggle [V]
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_V:
		is_first_person = not is_first_person
		if is_first_person:
			spring_arm.spring_length = 0.0
			camera_pivot.position = Vector3(0, 1.05, 0)
		else:
			spring_arm.spring_length = 3.2
			camera_pivot.position = Vector3(0, 0.85, 0)
		if audio_system and audio_system.has_method("play_comm_click"):
			audio_system.play_comm_click()
	
	if event.is_action_pressed("ui_cancel"):
		release_mouse()

func capture_mouse() -> void:
	if not is_interacting:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_mouse_captured = false

func _physics_process(delta: float) -> void:
	# Determine local planetary up vector (spherical planets) - flat levels keep Vector3.UP
	var up_vector = Vector3.UP
	var planet_node = get_tree().get_first_node_in_group("spherical_planet")
	var on_sphere: bool = planet_node != null
	if planet_node:
		if planet_node.has_method("get_surface_normal"):
			up_vector = planet_node.get_surface_normal(global_position)
		elif "planet_center" in planet_node:
			var diff = global_position - planet_node.planet_center
			if diff.length_squared() > 1.0:
				up_vector = diff.normalized()
		
		current_up_vector = up_vector
		up_direction = up_vector
		
		# Align astronaut orientation to the planetary normal
		var cur_up = global_transform.basis.y
		if cur_up.cross(up_vector).length() > 0.001:
			var align_axis = cur_up.cross(up_vector).normalized()
			var align_angle = cur_up.angle_to(up_vector)
			global_rotate(align_axis, align_angle)
		
		# Track distance travelled around the planet (scaled to real Mars km)
		if _prev_planet_pos != Vector3.ZERO:
			var step_dist = (global_position - _prev_planet_pos).length()
			if step_dist > 0.001 and step_dist < 15.0:
				total_distance_travelled_km += (step_dist / 1000.0) * (3389.5 / 1200.0)
		_prev_planet_pos = global_position
	else:
		current_up_vector = Vector3.UP
	
	# Update jump buffer timer
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.22
	
	# Ground tracking & coyote grace window
	var on_ground = is_on_floor()
	if on_ground:
		coyote_timer = 0.18 # 180ms coyote grace window
		air_time = 0.0
		is_jumping = false
		floor_snap_length = 0.45
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		air_time += delta
		if velocity.dot(up_vector) <= 0.0:
			floor_snap_length = 0.45 # Restore snap so landing immediately adheres
	
	# Apply exact real Moon gravitation (1.62 m/s²) with consistent downward pull
	var was_in_air = not on_ground
	if was_in_air:
		var v_n_air = velocity.dot(up_vector) - gravity * delta
		v_n_air = maxf(v_n_air, -24.0)
		velocity += up_vector * (v_n_air - velocity.dot(up_vector))
		exertion_level = move_toward(exertion_level, 0.4, 0.2 * delta)
		landing_squash = move_toward(landing_squash, 0.0, 1.2 * delta)
	else:
		landing_squash = move_toward(landing_squash, 0.0, 6.0 * delta)
		var v_n_ground = velocity.dot(up_vector)
		if v_n_ground < 0.0 and not is_jumping:
			velocity += up_vector * (-0.6 - v_n_ground) # Maintain solid ground adhesion over craters and slopes
	
	# Landing detection: landing impact sound, footprint imprint and subtle contact dust
	if was_in_air and on_ground and not is_jumping:
		floor_snap_length = 0.45
		_handle_landing(prev_vertical_velocity)
	prev_vertical_velocity = velocity.dot(up_vector)
	
	# If locked in interaction (digging, cleaning, sample inspection), hold position stably
	if is_interacting:
		if interaction_anchor != Vector3.ZERO:
			if on_sphere:
				var to_anchor = interaction_anchor - global_position
				var tangent_to_anchor = to_anchor - up_vector * to_anchor.dot(up_vector)
				global_position += tangent_to_anchor.limit_length(3.5 * delta)
			else:
				var curr_h = Vector2(global_position.x, global_position.z)
				var target_h = Vector2(interaction_anchor.x, interaction_anchor.z)
				var next_h = curr_h.move_toward(target_h, 3.5 * delta)
				global_position.x = next_h.x
				global_position.z = next_h.y
		
		if on_sphere:
			velocity = up_vector * velocity.dot(up_vector)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		
		if interaction_target != Vector3.ZERO:
			var to_target = interaction_target - global_position
			if on_sphere:
				to_target -= up_vector * to_target.dot(up_vector)
			else:
				to_target.y = 0.0
			if to_target.length_squared() > 0.01:
				var local_target = global_transform.basis.inverse() * to_target.normalized()
				var target_angle = atan2(local_target.x, local_target.z)
				visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.0 * delta)
		
		_animate_astronaut(delta, false, false)
		move_and_slide()
		return
	
	# Check gait modifier (Shift key activates loping)
	var active_loping = is_loping_mode or Input.is_key_pressed(KEY_SHIFT)
	var current_max_speed = lope_speed if active_loping else walk_speed
	
	# Ground support detection (including steep crater slopes)
	var has_ground_support = on_ground or (coyote_timer > 0.0)
	if not has_ground_support and air_time < 0.25:
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			if col.get_normal().dot(up_vector) > 0.15:
				has_ground_support = true
				break
	
	# Handle Low-Gravity Jump with buffer & coyote support
	if jump_buffer_timer > 0.0 and has_ground_support and not is_interacting:
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		jump()
	
	# Camera-relative movement calculation
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	var cam_basis = camera_pivot.global_transform.basis
	var forward = -cam_basis.z
	forward = (forward - forward.dot(up_vector) * up_vector).normalized()
	if forward.is_zero_approx():
		forward = -global_transform.basis.z
	var right = cam_basis.x
	right = (right - right.dot(up_vector) * up_vector).normalized()
	if right.is_zero_approx():
		right = global_transform.basis.x
	
	var move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	var has_input = move_direction.length() > 0.01
	
	var accel_rate = 3.2 if on_ground else 0.8
	var decel_rate = 4.4 if on_ground else 0.4
	
	if has_input:
		if on_sphere:
			var v_n_move = velocity.dot(up_vector)
			var v_tan = velocity - up_vector * v_n_move
			v_tan = v_tan.move_toward(move_direction * current_max_speed, accel_rate * delta * current_max_speed)
			velocity = v_tan + up_vector * v_n_move
		else:
			velocity.x = move_toward(velocity.x, move_direction.x * current_max_speed, accel_rate * delta * current_max_speed)
			velocity.z = move_toward(velocity.z, move_direction.z * current_max_speed, accel_rate * delta * current_max_speed)
		
		# Rotate astronaut smoothly towards movement direction
		var local_move = global_transform.basis.inverse() * move_direction
		var target_angle = atan2(local_move.x, local_move.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.5 * delta)
	else:
		if on_sphere:
			var v_n_stop = velocity.dot(up_vector)
			var v_tan_stop = velocity - up_vector * v_n_stop
			v_tan_stop = v_tan_stop.move_toward(Vector3.ZERO, decel_rate * delta * current_max_speed)
			velocity = v_tan_stop + up_vector * v_n_stop
		else:
			velocity.x = move_toward(velocity.x, 0.0, decel_rate * delta * current_max_speed)
			velocity.z = move_toward(velocity.z, 0.0, decel_rate * delta * current_max_speed)
		exertion_level = move_toward(exertion_level, 0.0, 0.15 * delta)
	
	var h_speed = (velocity - up_vector * velocity.dot(up_vector)).length()
	is_moving_horizontal = has_input or (h_speed > 0.35 and on_ground)
	
	if is_moving_horizontal:
		# Advance gait step cycle smoothly
		var stride_rate = 5.0 if active_loping else 3.8
		var speed_factor = clampf(h_speed / maxf(current_max_speed, 0.1), 0.5, 1.2)
		walk_cycle += delta * stride_rate * speed_factor
		walk_cycle = fmod(walk_cycle, TAU * 100.0)
		step_cycle_tracker += delta * stride_rate * speed_factor
		
		if on_ground:
			exertion_level = move_toward(exertion_level, 0.55 if active_loping else 0.20, 0.1 * delta)
		
		# Detect footstep touchdown
		if step_cycle_tracker >= PI:
			step_cycle_tracker -= PI
			last_foot_step = not last_foot_step
			var step_dir = move_direction if has_input else (velocity - up_vector * velocity.dot(up_vector)).normalized()
			_trigger_footstep(step_dir, active_loping)
	else:
		step_cycle_tracker = 0.0
	
	_animate_astronaut(delta, is_moving_horizontal, active_loping)
	move_and_slide()
	_handle_spherical_world_wrap()

# Connects the moon from one end to another (like a sphere where the character can walk infinitely)
func _handle_spherical_world_wrap() -> void:
	if is_interacting:
		return
		
	var terrain = get_tree().get_first_node_in_group("terrain")
	if terrain and terrain.is_in_group("spherical_planet"):
		return # Spherical planets are continuous - no toroidal wrapping
	var world_size: float = 180.0
	if terrain and "terrain_size" in terrain:
		world_size = terrain.terrain_size
	
	var half_size: float = world_size * 0.5
	var did_wrap: bool = false
	var new_pos: Vector3 = global_position
	
	if new_pos.x > half_size:
		new_pos.x -= world_size
		did_wrap = true
	elif new_pos.x < -half_size:
		new_pos.x += world_size
		did_wrap = true
		
	if new_pos.z > half_size:
		new_pos.z -= world_size
		did_wrap = true
	elif new_pos.z < -half_size:
		new_pos.z += world_size
		did_wrap = true
		
	if did_wrap:
		if terrain and terrain.has_method("get_terrain_height"):
			var surface_y = terrain.get_terrain_height(new_pos.x, new_pos.z)
			var h_diff = new_pos.y - surface_y
			new_pos.y = surface_y + maxf(0.02, h_diff)
		global_position = new_pos

func jump() -> void:
	if not is_interacting:
		var v_n_jump = velocity.dot(current_up_vector)
		velocity += current_up_vector * (jump_velocity - v_n_jump)
		floor_snap_length = 0.0 # Clean lift-off for low-gravity jump
		is_jumping = true
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		air_time = 0.08
		jump_anim_weight = 1.0
		exertion_level = clampf(exertion_level + 0.35, 0.0, 1.0)
		if dust_system and dust_system.has_method("emit_impact_dust"):
			dust_system.emit_impact_dust(global_position, 0.4)
		if audio_system and audio_system.has_method("play_footstep"):
			audio_system.play_footstep(true)

func _handle_landing(impact_vel: float) -> void:
	landing_squash = clampf(abs(impact_vel) * 0.045, 0.04, 0.16)
	if audio_system and audio_system.has_method("play_landing_thud"):
		audio_system.play_landing_thud(impact_vel)
	
	var impact_strength = clampf(abs(impact_vel) / 3.4, 0.3, 1.2)
	if dust_system and dust_system.has_method("emit_impact_dust"):
		dust_system.emit_impact_dust(global_position, impact_strength)
	
	if footprint_system and footprint_system.has_method("place_footprint"):
		var norm = get_floor_normal() if is_on_floor() else current_up_vector
		footprint_system.place_footprint(global_position, norm, visuals.rotation.y, false, impact_strength * 1.0)
		footprint_system.place_footprint(global_position, norm, visuals.rotation.y, true, impact_strength * 1.0)

func _trigger_footstep(move_dir: Vector3, is_loping: bool) -> void:
	if not is_on_floor():
		return
	
	if audio_system and audio_system.has_method("play_footstep"):
		audio_system.play_footstep(is_loping)
	
	# Subtle, small disturbance of lunar dust around the boot sole
	if dust_system and dust_system.has_method("emit_footstep_dust"):
		dust_system.emit_footstep_dust(global_position, move_dir, is_loping)
	
	if footprint_system and footprint_system.has_method("place_footprint"):
		var norm = get_floor_normal()
		footprint_system.place_footprint(global_position, norm, visuals.rotation.y, last_foot_step, 0.9 if is_loping else 0.7)

func _animate_astronaut(delta: float, is_moving: bool, is_loping: bool) -> void:
	# Read signal strength from attached scanner
	var signal_strength: float = 0.0
	var scanner = get_node_or_null("Scanner")
	if not scanner:
		scanner = get_tree().get_first_node_in_group("scanner")
	if scanner and scanner.has_method("get_signal_strength"):
		signal_strength = scanner.get_signal_strength()
	
	var target_raise = 1.0 if signal_strength > 0.08 else 0.0
	scanner_raise_weight = lerp(scanner_raise_weight, target_raise, 4.0 * delta)
	
	# Excavation / interaction pose when digging, cleaning, or inspecting samples
	if is_interacting:
		current_anim_state = "interacting"
		if scanner_device:
			scanner_device.visible = false
		torso.position.y = lerp(torso.position.y, 0.62, 8.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, 0.12, 8.0 * delta)
		visuals.rotation.z = lerp(visuals.rotation.z, 0.0, 8.0 * delta)
		if left_arm and right_arm:
			left_arm.rotation.x = lerp(left_arm.rotation.x, -0.95, 8.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.18, 8.0 * delta)
			left_arm.rotation.z = lerp(left_arm.rotation.z, -0.15, 8.0 * delta)
			right_arm.rotation.x = lerp(right_arm.rotation.x, -0.95, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.18, 8.0 * delta)
			right_arm.rotation.z = lerp(right_arm.rotation.z, 0.15, 8.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 10.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 10.0 * delta)
			left_leg.position.y = lerp(left_leg.position.y, -0.28, 10.0 * delta)
			right_leg.position.y = lerp(right_leg.position.y, -0.28, 10.0 * delta)
		_update_scanner_screen(signal_strength)
		return
	
	if scanner_device:
		scanner_device.visible = true
	
	# Metal detector sweep dynamics: 0.7 Hz base pendulum, ±25° yaw, slows/narrows with signal
	var sweep_time = Time.get_ticks_msec() * 0.001
	var sweep_freq = lerp(4.4, 1.8, signal_strength)
	var sweep_amp = lerp(deg_to_rad(25.0), deg_to_rad(8.0), signal_strength)
	var sweep_yaw = sin(sweep_time * sweep_freq) * sweep_amp
	var sweep_roll = cos(sweep_time * sweep_freq) * 0.04
	var base_detector_arm_x = lerp(-0.52, -0.38, signal_strength)
	
	# Animation Branch: Airborne vs Walking vs Idle
	# Truly airborne: actively jumping, or falling freely off terrain dips for more than coyote grace
	var on_ground = is_on_floor()
	if on_ground:
		is_jumping = false
	var is_airborne = not on_ground and (is_jumping or air_time > 0.14 or abs(velocity.dot(current_up_vector)) > 1.25)
	
	if is_airborne:
		# 1. JUMPING & FLOATING IN LUNAR VACUUM (1.62 m/s²)
		jump_anim_weight = move_toward(jump_anim_weight, 1.0, 8.0 * delta)
		var is_rising = velocity.dot(current_up_vector) > 0.05
		current_anim_state = "jump" if is_rising else "fall"
		
		# Torso airtime posture: slight tilt back when soaring up, level/forward when descending
		var target_torso_y = 0.66
		var target_rot_x = -0.14 if is_rising else 0.06
		torso.position.y = lerp(torso.position.y, target_torso_y, 6.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, target_rot_x, 6.0 * delta)
		visuals.rotation.z = lerp(visuals.rotation.z, 0.0, 6.0 * delta)
		
		# Legs: trailing gracefully during low-g jump, extending to meet ground during descent
		var leg_target_x = -0.36 if is_rising else 0.16
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, leg_target_x, 8.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, leg_target_x * 0.9, 8.0 * delta)
			left_leg.position.y = lerp(left_leg.position.y, -0.27, 8.0 * delta)
			right_leg.position.y = lerp(right_leg.position.y, -0.27, 8.0 * delta)
			left_leg.rotation.z = lerp(left_leg.rotation.z, -0.06, 6.0 * delta)
			right_leg.rotation.z = lerp(right_leg.rotation.z, 0.06, 6.0 * delta)
		
		# Arms: flare out wide for low-gravity stabilization
		if left_arm:
			var arm_x = -0.68 if is_rising else -0.32
			var arm_z = -0.42 if is_rising else -0.35
			left_arm.rotation.x = lerp(left_arm.rotation.x, arm_x, 7.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.1, 7.0 * delta)
			left_arm.rotation.z = lerp(left_arm.rotation.z, arm_z, 7.0 * delta)
		
		if right_arm:
			right_arm.rotation.x = lerp(right_arm.rotation.x, -0.58, 6.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.16 + sweep_yaw * 0.4, 6.0 * delta)
			right_arm.rotation.z = lerp(right_arm.rotation.z, 0.16, 6.0 * delta)
		
		# Head tilts toward apex
		if head:
			var head_target_x = -0.16 if is_rising else 0.04
			head.rotation.x = lerp(head.rotation.x, head_target_x, 6.0 * delta)
			head.rotation.y = lerp(head.rotation.y, 0.0, 6.0 * delta)
			head.rotation.z = lerp(head.rotation.z, 0.0, 6.0 * delta)
			
	elif is_moving:
		# 2. WALKING & LOPING ON LUNAR REGOLITH
		jump_anim_weight = move_toward(jump_anim_weight, 0.0, 10.0 * delta)
		current_anim_state = "walk"
		
		var stride_mult = 0.55 if is_loping else 0.36
		var stride_angle = sin(walk_cycle) * stride_mult
		
		# Vertical step bounce & landing squash absorption
		var bob_height = 0.065 if is_loping else 0.040
		var target_y = 0.65 + abs(sin(walk_cycle)) * bob_height - landing_squash
		torso.position.y = lerp(torso.position.y, target_y, 14.0 * delta)
		
		# Minion astronaut waddle roll & forward lean
		var waddle_roll = sin(walk_cycle) * (0.085 if is_loping else 0.055)
		var forward_lean = 0.11 if is_loping else 0.06
		visuals.rotation.z = lerp(visuals.rotation.z, waddle_roll, 10.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, forward_lean, 8.0 * delta)
		
		# Leg strides with foot ground clearance lift
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, -stride_angle * 1.15, 14.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, stride_angle * 1.15, 14.0 * delta)
			
			var left_lift = max(0.0, -sin(walk_cycle)) * (0.04 if is_loping else 0.025)
			var right_lift = max(0.0, sin(walk_cycle)) * (0.04 if is_loping else 0.025)
			left_leg.position.y = lerp(left_leg.position.y, -0.28 + left_lift, 14.0 * delta)
			right_leg.position.y = lerp(right_leg.position.y, -0.28 + right_lift, 14.0 * delta)
			
			left_leg.rotation.z = lerp(left_leg.rotation.z, 0.0, 8.0 * delta)
			right_leg.rotation.z = lerp(right_leg.rotation.z, 0.0, 8.0 * delta)
		
		# Arm counter-swings
		if left_arm:
			left_arm.rotation.x = lerp(left_arm.rotation.x, stride_angle * 0.95, 12.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.0, 8.0 * delta)
			left_arm.rotation.z = lerp(left_arm.rotation.z, -0.22 - abs(sin(walk_cycle)) * 0.06, 10.0 * delta)
		
		if right_arm:
			var walk_bob = sin(walk_cycle * 2.0) * 0.03
			right_arm.rotation.x = lerp(right_arm.rotation.x, base_detector_arm_x + walk_bob, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.16 + sweep_yaw, 8.0 * delta)
			right_arm.rotation.z = lerp(right_arm.rotation.z, 0.16 + sweep_roll, 8.0 * delta)
		
		# Head bobs subtly with walk
		if head:
			head.rotation.x = lerp(head.rotation.x, -0.04, 6.0 * delta)
			head.rotation.y = lerp(head.rotation.y, sin(walk_cycle) * 0.04, 8.0 * delta)
			head.rotation.z = lerp(head.rotation.z, -waddle_roll * 0.5, 8.0 * delta)
			
	else:
		# 3. ASTRONAUT LOW-GRAVITY IDLE
		jump_anim_weight = move_toward(jump_anim_weight, 0.0, 8.0 * delta)
		current_anim_state = "idle"
		idle_time += delta * 2.2
		
		# Gentle floating breathing bob & landing squash absorption
		var idle_bob = sin(idle_time) * 0.016 - landing_squash
		torso.position.y = lerp(torso.position.y, 0.65 + idle_bob, 8.0 * delta)
		
		# Subtle breathing sway & balance
		var idle_sway_z = sin(idle_time * 0.5) * 0.016
		var idle_pitch_x = cos(idle_time * 0.7) * 0.012
		visuals.rotation.z = lerp(visuals.rotation.z, idle_sway_z, 6.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, idle_pitch_x, 6.0 * delta)
		
		# Legs: planted and stable
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 8.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 8.0 * delta)
			left_leg.position.y = lerp(left_leg.position.y, -0.28, 8.0 * delta)
			right_leg.position.y = lerp(right_leg.position.y, -0.28, 8.0 * delta)
			left_leg.rotation.z = lerp(left_leg.rotation.z, 0.0, 6.0 * delta)
			right_leg.rotation.z = lerp(right_leg.rotation.z, 0.0, 6.0 * delta)
		
		# Arms: buoyant pressurized spacesuit float
		if left_arm:
			var idle_arm_x = sin(idle_time) * 0.035
			var idle_arm_z = -0.16 + cos(idle_time * 0.5) * 0.02
			left_arm.rotation.x = lerp(left_arm.rotation.x, idle_arm_x, 6.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.0, 6.0 * delta)
			left_arm.rotation.z = lerp(left_arm.rotation.z, idle_arm_z, 6.0 * delta)
			
		if right_arm:
			right_arm.rotation.x = lerp(right_arm.rotation.x, base_detector_arm_x, 6.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.16 + sweep_yaw, 7.0 * delta)
			right_arm.rotation.z = lerp(right_arm.rotation.z, 0.16 + sweep_roll, 7.0 * delta)
		
		# Head: subtle curious scan of lunar horizon
		if head:
			var head_yaw = sin(idle_time * 0.35) * 0.05
			var head_pitch = cos(idle_time * 0.6) * 0.015
			head.rotation.x = lerp(head.rotation.x, head_pitch, 5.0 * delta)
			head.rotation.y = lerp(head.rotation.y, head_yaw, 5.0 * delta)
			head.rotation.z = lerp(head.rotation.z, 0.0, 5.0 * delta)
	
	_update_scanner_screen(signal_strength)

func _update_scanner_screen(signal_strength: float) -> void:
	if not scanner_screen:
		return
	
	var pulse_freq = 1.5 + signal_strength * 10.0
	var pulse = (sin(Time.get_ticks_msec() * 0.001 * pulse_freq * TAU) + 1.0) * 0.5
	
	# Color gradient follows proximity: Green -> Amber -> Red
	var display_color: Color
	if signal_strength < 0.4:
		var t = signal_strength / 0.4
		display_color = Color(0.1, 0.9, 0.4).lerp(Color(0.2, 0.95, 0.7), t)
	elif signal_strength < 0.75:
		var t = (signal_strength - 0.4) / 0.35
		display_color = Color(0.2, 0.95, 0.7).lerp(Color(1.0, 0.65, 0.1), t)
	else:
		var t = (signal_strength - 0.75) / 0.25
		display_color = Color(1.0, 0.65, 0.1).lerp(Color(1.0, 0.18, 0.15), t)
	
	var energy = 1.0 + pulse * (1.2 + 3.0 * signal_strength)
	
	var scr_mat = scanner_screen.get_active_material(0)
	if scr_mat is StandardMaterial3D:
		scr_mat.emission = display_color
		scr_mat.emission_energy_multiplier = energy
	
	if status_led:
		var led_mat = status_led.get_active_material(0)
		if led_mat is StandardMaterial3D:
			led_mat.emission = display_color
			led_mat.emission_energy_multiplier = energy * 1.5
