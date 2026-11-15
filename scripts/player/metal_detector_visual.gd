extends Node3D
class_name MetalDetectorVisual

# Echoes Beyond Earth - Handheld Scientific Metal Detector
# Authentic metal detector model built procedurally:
# Upper shaft, handgrip, arm cradle, control box with display Screen and StatusLED,
# lower shaft, angled search coil with outer ring and hub.

@export var shaft_length: float = 0.68
@export var coil_radius: float = 0.11
@export var coil_tilt: float = 0.785 # 45 degrees to keep coil flat against terrain

var screen_mesh: MeshInstance3D = null
var status_led: MeshInstance3D = null
var coil_node: Node3D = null

func build() -> void:
	# Materials
	var mat_dark = StandardMaterial3D.new()
	mat_dark.albedo_color = Color(0.12, 0.13, 0.15, 1.0)
	mat_dark.roughness = 0.4
	mat_dark.metallic = 0.8
	
	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.98, 0.82, 0.15, 1.0)
	mat_yellow.roughness = 0.5
	mat_yellow.metallic = 0.1
	
	var mat_screen = StandardMaterial3D.new()
	mat_screen.albedo_color = Color(0.02, 0.08, 0.10, 1.0)
	mat_screen.emission_enabled = true
	mat_screen.emission = Color(0.0, 0.9, 1.0, 1.0) # Electric Cyan default
	mat_screen.emission_energy_multiplier = 1.8
	mat_screen.roughness = 0.2
	
	var mat_led = StandardMaterial3D.new()
	mat_led.albedo_color = Color(0.2, 0.9, 0.3, 1.0)
	mat_led.emission_enabled = true
	mat_led.emission = Color(0.2, 0.9, 0.3, 1.0)
	mat_led.emission_energy_multiplier = 2.0
	
	var mat_grip = StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.05, 0.05, 0.06, 1.0)
	mat_grip.roughness = 0.9
	
	# 1. Handgrip (held in glove)
	var grip = MeshInstance3D.new()
	grip.name = "Grip"
	var grip_mesh = CylinderMesh.new()
	grip_mesh.top_radius = 0.020
	grip_mesh.bottom_radius = 0.020
	grip_mesh.height = 0.10
	grip.mesh = grip_mesh
	grip.material_override = mat_grip
	grip.rotation_degrees = Vector3(15, 0, 0)
	add_child(grip)
	
	# 2. Arm Cradle (armrest behind grip)
	var cradle_stem = MeshInstance3D.new()
	cradle_stem.name = "CradleStem"
	var stem_mesh = BoxMesh.new()
	stem_mesh.size = Vector3(0.022, 0.022, 0.16)
	cradle_stem.mesh = stem_mesh
	cradle_stem.material_override = mat_dark
	cradle_stem.position = Vector3(0, 0.04, -0.09)
	add_child(cradle_stem)
	
	var arm_rest = MeshInstance3D.new()
	arm_rest.name = "ArmRest"
	var rest_mesh = BoxMesh.new()
	rest_mesh.size = Vector3(0.07, 0.05, 0.04)
	arm_rest.mesh = rest_mesh
	arm_rest.material_override = mat_yellow
	arm_rest.position = Vector3(0, 0.065, -0.16)
	add_child(arm_rest)
	
	# 3. Control Box with Screen and StatusLED
	var control_box = MeshInstance3D.new()
	control_box.name = "ControlBox"
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.075, 0.065, 0.095)
	control_box.mesh = box_mesh
	control_box.material_override = mat_dark
	control_box.position = Vector3(0, 0.035, 0.045)
	add_child(control_box)
	
	# Screen (Must be named "Screen" for compatibility with existing player code)
	var scr = MeshInstance3D.new()
	scr.name = "Screen"
	var scr_mesh = BoxMesh.new()
	scr_mesh.size = Vector3(0.055, 0.005, 0.065)
	scr.mesh = scr_mesh
	scr.material_override = mat_screen
	scr.position = Vector3(0, 0.036, 0.045)
	scr.rotation_degrees = Vector3(25, 0, 0) # Angled toward astronaut eyes
	add_child(scr)
	screen_mesh = scr
	
	# StatusLED
	var led = MeshInstance3D.new()
	led.name = "StatusLED"
	var led_mesh = SphereMesh.new()
	led_mesh.radius = 0.008
	led_mesh.height = 0.016
	led.mesh = led_mesh
	led.material_override = mat_led
	led.position = Vector3(0.026, 0.045, 0.08)
	add_child(led)
	status_led = led
	
	# 4. Upper & Lower Shaft
	var upper_shaft = MeshInstance3D.new()
	upper_shaft.name = "UpperShaft"
	var us_mesh = CylinderMesh.new()
	us_mesh.top_radius = 0.012
	us_mesh.bottom_radius = 0.012
	us_mesh.height = shaft_length * 0.45
	upper_shaft.mesh = us_mesh
	upper_shaft.material_override = mat_dark
	upper_shaft.position = Vector3(0, -shaft_length * 0.18, shaft_length * 0.20)
	upper_shaft.rotation_degrees = Vector3(-42, 0, 0)
	add_child(upper_shaft)
	
	var lower_shaft = MeshInstance3D.new()
	lower_shaft.name = "LowerShaft"
	var ls_mesh = CylinderMesh.new()
	ls_mesh.top_radius = 0.009
	ls_mesh.bottom_radius = 0.009
	ls_mesh.height = shaft_length * 0.60
	lower_shaft.mesh = ls_mesh
	lower_shaft.material_override = mat_yellow
	lower_shaft.position = Vector3(0, -shaft_length * 0.42, shaft_length * 0.46)
	lower_shaft.rotation_degrees = Vector3(-42, 0, 0)
	add_child(lower_shaft)
	
	# 5. Search Coil at shaft tip
	var coil_pivot = Node3D.new()
	coil_pivot.name = "CoilPivot"
	coil_pivot.position = Vector3(0, -shaft_length * 0.64, shaft_length * 0.68)
	coil_pivot.rotation_degrees = Vector3(coil_tilt * (180.0 / PI) - 42.0, 0, 0)
	add_child(coil_pivot)
	coil_node = coil_pivot
	
	# Coil bracket / bolt
	var bolt = MeshInstance3D.new()
	bolt.name = "CoilBolt"
	var bolt_mesh = CylinderMesh.new()
	bolt_mesh.top_radius = 0.012
	bolt_mesh.bottom_radius = 0.012
	bolt_mesh.height = 0.035
	bolt.mesh = bolt_mesh
	bolt.material_override = mat_dark
	bolt.rotation_degrees = Vector3(0, 0, 90)
	coil_pivot.add_child(bolt)
	
	# Flat inner search disc
	var disc = MeshInstance3D.new()
	disc.name = "CoilDisc"
	var disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = coil_radius
	disc_mesh.bottom_radius = coil_radius
	disc_mesh.height = 0.012
	disc.mesh = disc_mesh
	disc.material_override = mat_dark
	coil_pivot.add_child(disc)
	
	# Outer coil ring
	var ring = MeshInstance3D.new()
	ring.name = "CoilRing"
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = coil_radius * 0.82
	ring_mesh.outer_radius = coil_radius * 1.05
	ring.mesh = ring_mesh
	ring.material_override = mat_yellow
	ring.rotation_degrees = Vector3(90, 0, 0)
	coil_pivot.add_child(ring)
