extends CharacterBody3D

# Echoes Beyond Earth - Photorealistic Third-Person Astronaut Minion Simulator
# Controls a recognizable Minion astronaut wearing an authentic NASA EVA spacesuit:
# 1. Third-Person Camera with smooth orbit, terrain collision, and zoom (1.8m - 6.5m)
# 2. Authentic Minion locomotion & spacesuit waddle under exact 1.62 m/s² lunar or 3.71 m/s² Martian gravity
# 3. Apollo low-gravity loping, jump buffering, coyote time, and high-airtime jumping
# 4. Footprints with corrugated overboot tread, vacuum ballistic dust, and vacuum acoustics
# 5. Full compatibility with equipment excavation, cleaning, scientific sample inspection, and spherical planetary navigation

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
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

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
var _was_on_floor: bool = true

# Stable interaction state (prevents rubberbanding/displacement during digging, cleaning & inspection)
var is_interacting: bool = false
var interaction_anchor: Vector3 = Vector3.ZERO
var interaction_target: Vector3 = Vector3.ZERO

# Subsystems
var audio_system: Node = null
var dust_system: Node = null
var footprint_system: Node = null
var metal_detector: Node3D = null
var excavation_tools: Node3D = null
var current_tool_id: int = 0 # 0=Detector, 1=Scoop, 2=Brush, 3=Bag

# Planetary Surface & Gravity Alignment
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
	capture_mouse()
	_setup_third_person_camera()
	call_deferred("_connect_subsystems")

func _setup_third_person_camera() -> void:
	camera_pivot.position = Vector3(0, 0.85, 0)
	spring_arm.spring_length = 3.2
	spring_arm.collision_mask = 1 # Prevent camera clipping into terrain or boulders

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
	
	# Floor adhesion on uneven regolith: prevents unwanted floating over slopes and craters
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(65.0)
	floor_stop_on_slope = true
	
	if dust_system and dust_system.has_method("set_gravity"):
		dust_system.set_gravity(gravity)
	
	# Initialize Professional Lunar Metal Detector (88 cm shaft, 26 cm coil, VLF prospecting)
	var md_script = load("res://scripts/tools/lunar_metal_detector.gd")
	if md_script and right_arm:
		metal_detector = Node3D.new()
		metal_detector.set_script(md_script)
		right_arm.add_child(metal_detector)
		if scanner_device:
			scanner_device.visible = false
	
	# Initialize NASA Scientific Excavation Tools (Scoop, Brush, Sample Bag)
	var tools_script = load("res://scripts/tools/lunar_excavation_tools.gd")
	if tools_script and right_arm:
		excavation_tools = Node3D.new()
		excavation_tools.set_script(tools_script)
		right_arm.add_child(excavation_tools)
	
	set_active_tool(0)

func set_active_tool(tool_id: int) -> void:
	current_tool_id = tool_id
	if metal_detector:
		metal_detector.visible = (tool_id == 0)
	if excavation_tools:
		match tool_id:
			1:
				excavation_tools.set_tool(1) # SCOOP
			2:
				excavation_tools.set_tool(2) # BRUSH
			3:
				excavation_tools.set_tool(3) # SAMPLE_BAG
			_:
				excavation_tools.set_tool(0) # NONE

func update_metal_detector_signal(strength: float, distance: float) -> void:
	if metal_detector and metal_detector.has_method("set_signal"):
		metal_detector.set_signal(strength, distance)

func emit_dig_dust(target_pos: Vector3) -> void:
	if dust_system and dust_system.has_method("emit_impact_dust"):
		dust_system.emit_impact_dust(target_pos, 0.45)

func update_gravity(new_gravity: float) -> void:
	gravity = new_gravity
	if gravity > 2.5: # Mars gravity ~3.71 m/s²
		jump_velocity = 3.0 # Calibrated ~1.21m apex under 3.71 m/s² Martian gravity
		walk_speed = 1.8
		lope_speed = 3.6
	else: # Moon gravity ~1.62 m/s²
		jump_velocity = 2.4 # Calibrated ~1.77m apex under 1.62 m/s² lunar gravity
		walk_speed = 1.6
		lope_speed = 3.2
	if dust_system and dust_system.has_method("set_gravity"):
		dust_system.set_gravity(gravity)

func _unhandled_input(event: InputEvent) -> void:
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
	# 1. Determine local planetary up vector and gravity direction
	var up_vector = Vector3.UP
	var planet_node = get_tree().get_first_node_in_group("spherical_planet")
	if planet_node:
		if planet_node.has_method("get_surface_normal"):
			up_vector = planet_node.get_surface_normal(global_position)
		elif "planet_center" in planet_node:
			var diff = global_position - planet_node.planet_center
			if diff.length_squared() > 1.0:
				up_vector = diff.normalized()

	current_up_vector = up_vector
	up_direction = up_vector

	# Align astronaut orientation smoothly to planetary normal
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

	# 2. Decompose velocity into normal (vertical) and tangential (horizontal) components
	var v_norm = velocity.dot(up_vector)
	var v_tangent = velocity - up_vector * v_norm

	# Update jump buffer timer
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.22

	# Ground tracking & coyote window
	var on_ground = is_on_floor()
	if on_ground:
		coyote_timer = 0.18
		if v_norm <= 0.05:
			is_jumping = false
			air_time = 0.0
			floor_snap_length = 0.45
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
		air_time += delta
		if v_norm <= 0.0:
			is_jumping = false
			floor_snap_length = 0.45 # Restore snap so landing immediately adheres

	# Landing detection
	var just_landed = (not _was_on_floor) and on_ground
	if just_landed and not is_jumping:
		floor_snap_length = 0.45
		_handle_landing(prev_vertical_velocity)
	_was_on_floor = on_ground

	# Apply gravity & vertical velocity
	if not on_ground:
		v_norm -= gravity * delta
		v_norm = maxf(v_norm, -24.0)
		exertion_level = move_toward(exertion_level, 0.4, 0.2 * delta)
		landing_squash = move_toward(landing_squash, 0.0, 1.2 * delta)
	else:
		landing_squash = move_toward(landing_squash, 0.0, 6.0 * delta)
		if v_norm <= 0.05 and not is_jumping:
			v_norm = -0.6 # Maintain solid ground adhesion over craters and slopes

	prev_vertical_velocity = v_norm

	# If locked in interaction (digging, cleaning, sample inspection), hold position stably
	if is_interacting:
		if interaction_anchor != Vector3.ZERO:
			var to_anchor = interaction_anchor - global_position
			var tangent_to_anchor = to_anchor - up_vector * to_anchor.dot(up_vector)
			global_position += tangent_to_anchor.limit_length(3.5 * delta)

		velocity = up_vector * v_norm

		if interaction_target != Vector3.ZERO:
			var to_target = interaction_target - global_position
			var tangent_target = to_target - up_vector * to_target.dot(up_vector)
			if tangent_target.length_squared() > 0.01:
				var local_target = global_transform.basis.inverse() * tangent_target.normalized()
				var target_angle = atan2(local_target.x, local_target.z)
				visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.0 * delta)

		_animate_astronaut(delta, false, false)
		move_and_slide()
		return

	# Check gait modifier (Shift key activates loping)
	var active_loping = is_loping_mode or Input.is_key_pressed(KEY_SHIFT)
	var current_max_speed = lope_speed if active_loping else walk_speed

	# Handle Low-Gravity Jump with Jump Buffering & Coyote Time
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		jump()
		v_norm = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		is_jumping = true

	# Camera-relative movement calculation in local tangent plane
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
	var cam_forward = -cam_basis.z
	var forward = (cam_forward - cam_forward.dot(up_vector) * up_vector).normalized()
	if forward.is_zero_approx():
		forward = -global_transform.basis.z
	var right = (cam_basis.x - cam_basis.x.dot(up_vector) * up_vector).normalized()
	if right.is_zero_approx():
		right = global_transform.basis.x

	var move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	var is_moving = move_direction.length() > 0.01
	is_moving_horizontal = is_moving

	var accel_rate = 3.2 if is_on_floor() else 0.8
	var decel_rate = 4.4 if is_on_floor() else 0.4

	if is_moving:
		v_tangent = v_tangent.move_toward(move_direction * current_max_speed, accel_rate * current_max_speed * delta)
		
		var local_move = global_transform.basis.inverse() * move_direction
		var target_yaw = atan2(local_move.x, local_move.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, 10.0 * delta)

		var cadence = 7.5 if active_loping else 5.2
		walk_cycle += cadence * delta
		step_cycle_tracker += (cadence * delta) / PI

		if step_cycle_tracker >= 1.0:
			step_cycle_tracker -= 1.0
			last_foot_step = not last_foot_step
			_trigger_footstep(move_direction, active_loping)
	else:
		v_tangent = v_tangent.move_toward(Vector3.ZERO, decel_rate * current_max_speed * delta)
		walk_cycle = 0.0
		step_cycle_tracker = 0.0

	velocity = v_tangent + up_vector * v_norm
	move_and_slide()

	# Connects the moon from one end to another (like a sphere where the character can walk infinitely)
	_handle_spherical_world_wrap()

	# Landing squash recovery
	landing_squash = move_toward(landing_squash, 0.0, 0.6 * delta)

	# Update locomotion and spacesuit posture animation
	_animate_astronaut(delta, is_moving, active_loping)

# Connects the moon from one end to another (toroidal wrapping for planar infinite moon)
func _handle_spherical_world_wrap() -> void:
	if is_interacting:
		return
		
	var terrain = get_tree().get_first_node_in_group("terrain")
	if not terrain or terrain.is_in_group("spherical_planet"):
		return
		
	var world_size: float = 180.0
	if "terrain_size" in terrain:
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
		if terrain.has_method("get_terrain_height"):
			new_pos.y = terrain.get_terrain_height(new_pos.x, new_pos.z) + 0.15
		global_position = new_pos

func jump() -> void:
	if not is_interacting:
		var v_n = velocity.dot(current_up_vector)
		velocity += current_up_vector * (jump_velocity - v_n)
		floor_snap_length = 0.0 # Clean lift-off for low-gravity jump
		is_jumping = true
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		air_time = 0.08
		jump_anim_weight = 1.0
		current_anim_state = "jump"
		exertion_level = clampf(exertion_level + 0.35, 0.0, 1.0)
		if dust_system and dust_system.has_method("emit_impact_dust"):
			dust_system.emit_impact_dust(global_position, 0.4)
		if audio_system and audio_system.has_method("play_suit_effort"):
			audio_system.play_suit_effort(0.4)
		if audio_system and audio_system.has_method("play_footstep"):
			audio_system.play_footstep(true)
		if anim_player and anim_player.has_animation("jump"):
			anim_player.play("jump")

func _handle_landing(impact_velocity: float) -> void:
	landing_squash = clampf(abs(impact_velocity) * 0.045, 0.04, 0.16)
	if audio_system and audio_system.has_method("play_landing_thud"):
		audio_system.play_landing_thud(impact_velocity)
	elif audio_system and audio_system.has_method("play_footstep"):
		audio_system.play_footstep(true)
	
	var impact_strength = clampf(abs(impact_velocity) / 3.4, 0.3, 1.2)
	# Small regolith dust plume kicked up upon landing
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

	# Subtle, small disturbance of regolith dust around the boot sole
	if dust_system and dust_system.has_method("emit_footstep_dust"):
		dust_system.emit_footstep_dust(global_position, move_dir, is_loping)

	if footprint_system and footprint_system.has_method("place_footprint"):
		var norm = get_floor_normal() if is_on_floor() else current_up_vector
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
		current_anim_state = "interact"
		torso.position.y = lerp(torso.position.y, 0.44, 6.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, deg_to_rad(38.0), 8.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, deg_to_rad(-38.0), 8.0 * delta)
		
		# Tool animations during excavation
		var t_sec = Time.get_ticks_msec() * 0.001
		if current_tool_id == 1: # SCOOP
			var scoop_cycle = sin(t_sec * 3.5)
			if right_arm:
				right_arm.rotation.x = lerp(right_arm.rotation.x, -0.65 + scoop_cycle * 0.28, 8.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.15, 8.0 * delta)
			if left_arm:
				left_arm.rotation.x = lerp(left_arm.rotation.x, -0.60 + scoop_cycle * 0.20, 8.0 * delta)
				left_arm.rotation.y = lerp(left_arm.rotation.y, 0.15, 8.0 * delta)
		elif current_tool_id == 2: # BRUSH
			var brush_cycle = sin(t_sec * 5.0) * 0.18
			if right_arm:
				right_arm.rotation.x = lerp(right_arm.rotation.x, -0.80, 8.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.10 + brush_cycle, 10.0 * delta)
			if left_arm:
				left_arm.rotation.x = lerp(left_arm.rotation.x, -0.75, 8.0 * delta)
				left_arm.rotation.y = lerp(left_arm.rotation.y, 0.20, 8.0 * delta)
		else:
			if left_arm and right_arm:
				left_arm.rotation.x = lerp(left_arm.rotation.x, -0.90, 8.0 * delta)
				left_arm.rotation.y = lerp(left_arm.rotation.y, 0.18, 8.0 * delta)
				right_arm.rotation.x = lerp(right_arm.rotation.x, -0.90, 8.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.18, 8.0 * delta)
		return

	# Animation Branch: Airborne vs Walking vs Idle
	var on_ground = is_on_floor() and not is_jumping
	if is_on_floor() and velocity.dot(current_up_vector) <= 0.05:
		is_jumping = false
	var v_up = velocity.dot(current_up_vector)
	var is_airborne = is_jumping or (not on_ground and (air_time > 0.14 or abs(v_up) > 1.25))

	if is_airborne:
		# 1. LOW-GRAVITY JUMP LIFT-OFF & GLIDE POSTURE
		jump_anim_weight = move_toward(jump_anim_weight, 1.0, 8.0 * delta)
		var is_rising = v_up > 0.05
		current_anim_state = "jump" if is_rising else "fall"
		
		# Torso airtime posture: slight tilt back when soaring up, level/forward when descending
		var target_torso_y = 0.66
		var target_rot_x = -0.14 if is_rising else 0.06
		torso.position.y = lerp(torso.position.y, target_torso_y, 6.0 * delta)
		visuals.rotation.x = lerp(visuals.rotation.x, target_rot_x, 6.0 * delta)
		visuals.rotation.z = lerp(visuals.rotation.z, 0.0, 6.0 * delta)
		
		# Both legs trail backwards in buoyant low-gravity float
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
			if metal_detector and metal_detector.visible:
				right_arm.rotation.x = lerp(right_arm.rotation.x, deg_to_rad(-24.0), 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, deg_to_rad(12.0), 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.12, 6.0 * delta)
			elif scanner_raise_weight > 0.05:
				var scan_angle = -0.90 - (signal_strength * 0.25)
				right_arm.rotation.x = lerp(right_arm.rotation.x, scan_angle, 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.15, 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.15, 6.0 * delta)
			else:
				var arm_x = -0.68 if is_rising else -0.32
				var arm_z = 0.42 if is_rising else 0.35
				right_arm.rotation.x = lerp(right_arm.rotation.x, arm_x, 7.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.1, 7.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, arm_z, 7.0 * delta)
		
		if head:
			head.rotation.x = lerp(head.rotation.x, 0.08, 6.0 * delta)
			head.rotation.y = lerp(head.rotation.y, 0.0, 6.0 * delta)
			head.rotation.z = lerp(head.rotation.z, 0.0, 6.0 * delta)

	elif is_moving or (walk_cycle > 0.01 and not is_airborne):
		# 2. RUNTIME WALKING / LOW-GRAVITY LOPING (Smooth waddle and strides)
		jump_anim_weight = move_toward(jump_anim_weight, 0.0, 8.0 * delta)
		current_anim_state = "walk"
		
		# Waddle roll (side-to-side torso roll characteristic of Minion spacesuit walk)
		var waddle_roll = sin(walk_cycle) * (0.055 if is_loping else 0.035)
		visuals.rotation.z = lerp(visuals.rotation.z, waddle_roll, 10.0 * delta)
		
		# Forward momentum lean
		var forward_lean = 0.08 if is_loping else 0.04
		visuals.rotation.x = lerp(visuals.rotation.x, forward_lean, 8.0 * delta)
		
		# Torso vertical bounce during strides
		var vertical_bounce = abs(sin(walk_cycle)) * (0.035 if is_loping else 0.018)
		torso.position.y = lerp(torso.position.y, 0.65 + vertical_bounce - landing_squash, 12.0 * delta)
		
		# Stride angle
		var stride_angle = sin(walk_cycle) * (0.42 if is_loping else 0.28)
		
		# Leg strides & step elevation
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
			if metal_detector and metal_detector.visible:
				metal_detector.apply_sweep_motion(delta, true)
				right_arm.rotation.x = lerp(right_arm.rotation.x, deg_to_rad(-24.0), 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, deg_to_rad(12.0), 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.10, 6.0 * delta)
			elif scanner_raise_weight > 0.05:
				var scan_angle = -0.90 - (signal_strength * 0.25)
				var sweep = sin(Time.get_ticks_msec() * 0.003) * 0.08 * (1.0 - signal_strength)
				right_arm.rotation.x = lerp(right_arm.rotation.x, scan_angle, 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.20 + sweep, 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.10, 6.0 * delta)
			else:
				right_arm.rotation.x = lerp(right_arm.rotation.x, -stride_angle * 0.85, 12.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, 0.0, 8.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.22 + abs(sin(walk_cycle)) * 0.06, 10.0 * delta)
		
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
			if metal_detector and metal_detector.visible:
				metal_detector.apply_sweep_motion(delta, false)
				right_arm.rotation.x = lerp(right_arm.rotation.x, deg_to_rad(-24.0), 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, deg_to_rad(12.0), 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.10, 6.0 * delta)
			elif scanner_raise_weight > 0.05:
				var scan_angle = -0.90 - (signal_strength * 0.25)
				var sweep = sin(Time.get_ticks_msec() * 0.003) * 0.08 * (1.0 - signal_strength)
				right_arm.rotation.x = lerp(right_arm.rotation.x, scan_angle, 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, -0.20 + sweep, 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, 0.10, 6.0 * delta)
			else:
				var idle_arm_x = sin(idle_time + 0.4) * 0.035
				var idle_arm_z = 0.16 - cos(idle_time * 0.5) * 0.02
				right_arm.rotation.x = lerp(right_arm.rotation.x, idle_arm_x, 6.0 * delta)
				right_arm.rotation.y = lerp(right_arm.rotation.y, 0.0, 6.0 * delta)
				right_arm.rotation.z = lerp(right_arm.rotation.z, idle_arm_z, 6.0 * delta)
		
		# Head: subtle curious scan of lunar horizon
		if head:
			var head_yaw = sin(idle_time * 0.35) * 0.05
			var head_pitch = cos(idle_time * 0.6) * 0.015
			head.rotation.x = lerp(head.rotation.x, head_pitch, 5.0 * delta)
			head.rotation.y = lerp(head.rotation.y, head_yaw, 5.0 * delta)
			head.rotation.z = lerp(head.rotation.z, 0.0, 5.0 * delta)
	
	_update_scanner_screen(signal_strength)

func _update_scanner_screen(signal_strength: float) -> void:
	if scanner_screen and signal_strength > 0.05:
		var pulse = (sin(Time.get_ticks_msec() * (0.005 + signal_strength * 0.02)) + 1.0) * 0.5
		var mat = scanner_screen.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = 1.2 + pulse * 2.0 * signal_strength
