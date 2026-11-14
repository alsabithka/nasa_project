extends CharacterBody3D

# Roblox-style 3D Third-Person Character Controller
# Compliant with Echoes Beyond Earth team interfaces.

@export var speed: float = 7.5
@export var jump_velocity: float = 6.5
@export var gravity: float = 4.0 # Default Moon gravity
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = deg_to_rad(-70.0)
@export var max_pitch: float = deg_to_rad(50.0)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var left_arm: Node3D = $Visuals/Torso/LeftArm
@onready var right_arm: Node3D = $Visuals/Torso/RightArm
@onready var left_leg: Node3D = $Visuals/Torso/LeftLeg
@onready var right_leg: Node3D = $Visuals/Torso/RightLeg

# Scanner arm animation
var _scanner_raise_target: float = 0.0  # 0=lowered, 1=raised
var _scanner_raise_current: float = 0.0
@onready var scanner_device_node: Node3D = $Visuals/Torso/RightArm/ScannerDevice

var is_mouse_captured: bool = false
var walk_cycle: float = 0.0

# Agreed public interface for Scanner
func get_scan_origin() -> Vector3:
	if is_inside_tree():
		return global_position
	return position

func _ready() -> void:
	capture_mouse()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			capture_mouse()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clamp(spring_arm.spring_length - 0.5, 2.0, 8.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clamp(spring_arm.spring_length + 0.5, 2.0, 8.0)
	
	elif event is InputEventMouseMotion and is_mouse_captured:
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		spring_arm.rotate_x(-event.relative.y * mouse_sensitivity)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, min_pitch, max_pitch)
	
	if event.is_action_pressed("ui_cancel"):
		release_mouse()

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_mouse_captured = false

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Get movement input (camera relative)
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
	
	# Compute direction from camera horizontal heading
	var cam_basis = camera_pivot.global_transform.basis
	var forward = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right = cam_basis.x
	right.y = 0.0
	right = right.normalized()
	
	var move_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	
	# Update scanner raise target from scanner child
	var scanner = get_node_or_null("Scanner")
	if scanner and scanner.has_method("get_signal_strength"):
		_scanner_raise_target = scanner.get_signal_strength()
	else:
		_scanner_raise_target = 0.0
	
	# Smooth scanner raise current value
	_scanner_raise_current = lerp(_scanner_raise_current, _scanner_raise_target, 3.0 * delta)
	
	if move_direction.length() > 0.01:
		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed
		
		# Smoothly rotate visuals towards movement direction (Roblox style)
		var target_angle = atan2(move_direction.x, move_direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 12.0 * delta)
		
		# Animate limbs procedurally
		walk_cycle += delta * 10.0
		var limb_angle = sin(walk_cycle) * 0.6
		if left_arm and right_arm:
			left_arm.rotation.x = limb_angle
			# Right arm: blend walk animation with scanner raise
			var scanner_target_x = -1.1 * _scanner_raise_current
			if _scanner_raise_current > 0.05:
				right_arm.rotation.x = lerp(right_arm.rotation.x, scanner_target_x, 5.0 * delta)
			else:
				right_arm.rotation.x = -limb_angle
		if left_leg and right_leg:
			left_leg.rotation.x = -limb_angle
			right_leg.rotation.x = limb_angle
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
		
		# Reset limb positions or hold scanner raise
		if left_arm and right_arm:
			left_arm.rotation.x = lerp(left_arm.rotation.x, 0.0, 10.0 * delta)
			var scanner_target_x = -1.1 * _scanner_raise_current
			right_arm.rotation.x = lerp(right_arm.rotation.x, scanner_target_x, 5.0 * delta)
		if left_leg and right_leg:
			left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 10.0 * delta)
			right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 10.0 * delta)
	
	# Scanner device scanning animation
	if scanner_device_node:
		scanner_device_node.rotation.y = lerp(
			scanner_device_node.rotation.y,
			sin(Time.get_ticks_msec() * 0.001) * 0.3 * _scanner_raise_current,
			3.0 * delta
		)
	
	move_and_slide()
