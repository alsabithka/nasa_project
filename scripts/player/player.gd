extends CharacterBody3D

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
@export var jump_velocity: float = 3.4 # Under 1.62 m/s², gives ~4.2s airtime
@export var gravity: float = 1.62 # Exact lunar gravitational constant
@export var mouse_sensitivity: float = 0.0028
@export var min_pitch: float = deg_to_rad(-62.0)
@export var max_pitch: float = deg_to_rad(65.0)

# Nodes
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var torso: Node3D = $Visuals/Torso
@onready var left_arm: Node3D = $Visuals/Torso/LeftArm
@onready var right_arm: Node3D = $Visuals/Torso/RightArm
@onready var left_leg: Node3D = $Visuals/Torso/LeftLeg
@onready var right_leg: Node3D = $Visuals/Torso/RightLeg
@onready var scanner_device: Node3D = $Visuals/Torso/RightArm/ScannerDevice
@onready var scanner_screen: MeshInstance3D = $Visuals/Torso/RightArm/ScannerDevice/Screen

# Locomotion & Camera States
var is_first_person: bool = false # Third-person exploration default
var is_loping_mode: bool = true # Apollo low-gravity kangaroo lope default
var is_mouse_captured: bool = false
var walk_cycle: float = 0.0
var step_cycle_tracker: float = 0.0
var last_foot_step: bool = false # false = left, true = right
var scanner_raise_weight: float = 0.0
var exertion_level: float = 0.0
var prev_vertical_velocity: float = 0.0

# Stable interaction state (prevents rubberbanding/displacement during digging, cleaning & inspection)
var is_interacting: bool = false
var interaction_anchor: Vector3 = Vector3.ZERO
var interaction_target: Vector3 = Vector3.ZERO

# Subsystems
var audio_system: Node = null
var dust_system: Node = null
var footprint_system: Node = null

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
	# Apply exact lunar gravity (1.62 m/s²)
	var was_in_air = not is_on_floor()
	if was_in_air:
		velocity.y -= gravity * delta
		exertion_level = move_toward(exertion_level, 0.4, 0.2 * delta)
	
	# Landing detection: landing impact sound and subtle contact dust
	if was_in_air and is_on_floor():
		_handle_landing(prev_vertical_velocity)
	prev_vertical_velocity = velocity.y
	
	# If locked in interaction (digging, cleaning, sample inspection), hold position stably
	if is_interacting:
		if interaction_anchor != Vector3.ZERO:
			var curr_h = Vector2(global_position.x, global_position.z)
			var target_h = Vector2(interaction_anchor.x, interaction_anchor.z)
			var next_h = curr_h.move_toward(target_h, 3.5 * delta)
			global_position.x = next_h.x
			global_position.z = next_h.y
		
		velocity.x = 0.0
		velocity.z = 0.0
		
		if interaction_target != Vector3.ZERO:
			var to_target = interaction_target - global_position
			to_target.y = 0.0
			if to_target.length_squared() > 0.01:
				var target_angle = atan2(to_target.x, to_target.z)
				visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.0 * delta)
		
		_animate_astronaut(delta, false, false)
		move_and_slide()
		return
	
	# Check gait modifier (Shift key activates loping)
	var active_loping = is_loping_mode or Input.is_key_pressed(KEY_SHIFT)
	var current_max_speed = lope_speed if active_loping else walk_speed
	
	# Handle Low-Gravity Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
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
	forward.y = 0.0
	forward = forward.normalized()
	var right = cam_basis.x
	right.y = 0.0
	right = right.normalized()
	
	var move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	var is_moving = move_direction.length() > 0.01
	
	var accel_rate = 3.2 if is_on_floor() else 0.8
	var decel_rate = 4.4 if is_on_floor() else 0.4
	
	if is_moving:
		velocity.x = move_toward(velocity.x, move_direction.x * current_max_speed, accel_rate * delta * current_max_speed)
		velocity.z = move_toward(velocity.z, move_direction.z * current_max_speed, accel_rate * delta * current_max_speed)
		
		# Rotate astronaut smoothly towards movement direction
		var target_angle = atan2(move_direction.x, move_direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.5 * delta)
		
		# Advance gait step cycle
		var stride_rate = 5.0 if active_loping else 3.8
		walk_cycle += delta * stride_rate
		step_cycle_tracker += delta * stride_rate
		
		if is_on_floor():
			exertion_level = move_toward(exertion_level, 0.55 if active_loping else 0.20, 0.1 * delta)
		
		# Detect footstep touchdown
		if step_cycle_tracker >= PI:
			step_cycle_tracker -= PI
			last_foot_step = not last_foot_step
			_trigger_footstep(move_direction, active_loping)
	else:
		velocity.x = move_toward(velocity.x, 0.0, decel_rate * delta * current_max_speed)
		velocity.z = move_toward(velocity.z, 0.0, decel_rate * delta * current_max_speed)
		exertion_level = move_toward(exertion_level, 0.0, 0.15 * delta)
	
	_animate_astronaut(delta, is_moving, active_loping)
	move_and_slide()

func jump() -> void:
	if is_on_floor() and not is_interacting:
		velocity.y = jump_velocity
		exertion_level = clampf(exertion_level + 0.35, 0.0, 1.0)
		if dust_system and dust_system.has_method("emit_impact_dust"):
			dust_system.emit_impact_dust(global_position, 0.4)
		if audio_system and audio_system.has_method("play_footstep"):
			audio_system.play_footstep(true)

func _handle_landing(impact_vel: float) -> void:
	if audio_system and audio_system.has_method("play_landing_thud"):
		audio_system.play_landing_thud(impact_vel)
	
	var impact_strength = clampf(abs(impact_vel) / 3.4, 0.3, 1.2)
	if dust_system and dust_system.has_method("emit_impact_dust"):
		dust_system.emit_impact_dust(global_position, impact_strength)
	
	if footprint_system and footprint_system.has_method("place_footprint"):
		var norm = get_floor_normal() if is_on_floor() else Vector3.UP
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
	
	# Natural astronaut stride angle
	var stride_angle = sin(walk_cycle) * (0.42 if is_loping else 0.26) if is_moving else 0.0
	
	# Keep astronaut torso stable and upright in EVA spacesuit (no cartoon waddling or squashing)
	torso.position.y = 0.65
	visuals.rotation.z = 0.0
	
	# Excavation / interaction pose when digging, cleaning, or inspecting samples
	if is_interacting:
		if left_arm and right_arm:
			left_arm.rotation.x = lerp(left_arm.rotation.x, -0.95, 8.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.18, 8.0 * delta)
			right_arm.rotation.x = lerp(right_arm.rotation.x, -0.95, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.18, 8.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 10.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 10.0 * delta)
		return
	
	# Realistic spacesuit leg strides
	if left_leg and right_leg:
		left_leg.rotation.x = lerp(left_leg.rotation.x, -stride_angle, 12.0 * delta)
		right_leg.rotation.x = lerp(right_leg.rotation.x, stride_angle, 12.0 * delta)
	
	# Natural arm counter-swing
	if left_arm:
		left_arm.rotation.x = lerp(left_arm.rotation.x, stride_angle * 0.6, 10.0 * delta)
	
	# Right arm: holds handheld scanner or counter-swings
	if right_arm:
		if scanner_raise_weight > 0.05:
			var scan_angle = -0.90 - (signal_strength * 0.25)
			var sweep = sin(Time.get_ticks_msec() * 0.003) * 0.08 * (1.0 - signal_strength)
			right_arm.rotation.x = lerp(right_arm.rotation.x, scan_angle, 6.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.20 + sweep, 6.0 * delta)
		else:
			right_arm.rotation.x = lerp(right_arm.rotation.x, -stride_angle * 0.35, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, 0.0, 8.0 * delta)
	
	# Scanner screen emission pulse
	if scanner_screen and signal_strength > 0.05:
		var pulse = (sin(Time.get_ticks_msec() * (0.005 + signal_strength * 0.02)) + 1.0) * 0.5
		var mat = scanner_screen.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = 1.2 + pulse * 2.0 * signal_strength
