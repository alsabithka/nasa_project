extends CharacterBody3D

# Realistic EVA Spacesuit Astronaut with Handheld Scientific Survey Scanner
# Compliant with Echoes Beyond Earth team interfaces.

@export var speed: float = 7.0
@export var jump_velocity: float = 6.2
@export var gravity: float = 3.8 # Default Moon gravity (1.62 m/s^2 feel in game units)
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-70.0)
@export var max_pitch: float = deg_to_rad(55.0)

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

var is_mouse_captured: bool = false
var walk_cycle: float = 0.0
var scanner_raise_weight: float = 0.0

# Stable interaction state (prevents rubberbanding/displacement during digging & cleaning)
var is_interacting: bool = false
var interaction_anchor: Vector3 = Vector3.ZERO
var interaction_target: Vector3 = Vector3.ZERO

# Agreed public interface for Scanner
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_interacting and Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
				capture_mouse()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.5, 2.0, 8.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.5, 2.0, 8.0)
	
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_pitch, max_pitch)
	
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
	# Apply low lunar gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# If locked in interaction (digging or cleaning), settle at anchor and hold position stably
	if is_interacting:
		if interaction_anchor != Vector3.ZERO:
			var curr_h = Vector2(global_position.x, global_position.z)
			var target_h = Vector2(interaction_anchor.x, interaction_anchor.z)
			var next_h = curr_h.move_toward(target_h, 4.0 * delta)
			global_position.x = next_h.x
			global_position.z = next_h.y
		
		velocity.x = 0.0
		velocity.z = 0.0
		
		# Smoothly orient astronaut to face the equipment/dig site
		if interaction_target != Vector3.ZERO:
			var to_target = interaction_target - global_position
			to_target.y = 0.0
			if to_target.length_squared() > 0.01:
				var target_angle = atan2(to_target.x, to_target.z)
				visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 8.0 * delta)
		
		_animate_astronaut(delta, false)
		move_and_slide()
		return
	
	# Handle Jump (only when active)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Camera relative movement
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
	
	if is_moving:
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed
		
		var target_angle = atan2(move_direction.x, move_direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 10.0 * delta)
		walk_cycle += delta * 7.5 # Realistic deliberate moonwalking stride
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 6.0 * delta)
	
	_animate_astronaut(delta, is_moving)
	move_and_slide()

func _animate_astronaut(delta: float, is_moving: bool) -> void:
	# Read signal strength from attached scanner
	var signal_strength: float = 0.0
	var scanner = get_node_or_null("Scanner")
	if not scanner:
		scanner = get_tree().get_first_node_in_group("scanner")
	if scanner and scanner.has_method("get_signal_strength"):
		signal_strength = scanner.get_signal_strength()
	
	# Blend arm toward survey scanning raise
	var target_raise = 1.0 if signal_strength > 0.08 else 0.0
	scanner_raise_weight = lerp(scanner_raise_weight, target_raise, 4.0 * delta)
	
	# Natural walking stride
	var stride_angle = sin(walk_cycle) * 0.45 if is_moving else 0.0
	
	# Excavation / interaction pose when digging or cleaning
	if is_interacting:
		if left_arm and right_arm:
			# Stoop/reach forward with both arms
			left_arm.rotation.x = lerp(left_arm.rotation.x, -1.05, 8.0 * delta)
			left_arm.rotation.y = lerp(left_arm.rotation.y, 0.22, 8.0 * delta)
			right_arm.rotation.x = lerp(right_arm.rotation.x, -1.05, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.22, 8.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 10.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 10.0 * delta)
		return
	
	# Legs
	if left_leg and right_leg:
		left_leg.rotation.x = lerp(left_leg.rotation.x, -stride_angle, 12.0 * delta)
		right_leg.rotation.x = lerp(right_leg.rotation.x, stride_angle, 12.0 * delta)
	
	# Left arm swings with walk
	if left_arm:
		left_arm.rotation.x = lerp(left_arm.rotation.x, stride_angle * 0.7, 10.0 * delta)
	
	# Right arm: holds and points handheld scanner
	if right_arm:
		if scanner_raise_weight > 0.05:
			# Raised survey scanning posture (pointed forward/downward toward signal)
			var scan_angle = -0.95 - (signal_strength * 0.3)
			# Subtle scanning sweep motion
			var sweep = sin(Time.get_ticks_msec() * 0.003) * 0.12 * (1.0 - signal_strength)
			right_arm.rotation.x = lerp(right_arm.rotation.x, scan_angle, 6.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, -0.25 + sweep, 6.0 * delta)
		else:
			# Relaxed resting arm with scanner at side
			right_arm.rotation.x = lerp(right_arm.rotation.x, -stride_angle * 0.4, 8.0 * delta)
			right_arm.rotation.y = lerp(right_arm.rotation.y, 0.0, 8.0 * delta)
	
	# Update handheld scanner device screen emission pulse
	if scanner_screen and signal_strength > 0.05:
		var pulse = (sin(Time.get_ticks_msec() * (0.005 + signal_strength * 0.02)) + 1.0) * 0.5
		var mat = scanner_screen.get_active_material(0)
		if mat is StandardMaterial3D:
			mat.emission_energy_multiplier = 1.2 + pulse * 2.0 * signal_strength
