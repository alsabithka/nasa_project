extends Node3D

# Echoes Beyond Earth - Professional Lunar Geological Metal Detector
# Human/Minion scale proportions:
# - Overall length: 88 cm
# - Search coil: 26 cm circular coil with dual concentric loop & cross struts
# - Rigid carbon-composite shaft with ergonomic EVA glove grip and forearm cuff
# - Multifunction telemetry control unit with LED signal meter
# - Coiled heavy-duty signal cable wound around the shaft
# - Electromagnetic VLF prospecting response (inversely proportional to distance)

signal metal_anomaly_detected(distance: float, signal_strength: float)

@export var coil_hover_offset: float = 0.12 # Hover distance above ground
@export var detection_range: float = 40.0 # Effective prospecting range

var _audio_player: AudioStreamPlayer
var _audio_timer: float = 0.0
var _current_signal: float = 0.0
var _is_active: bool = true
var _sweep_phase: float = 0.0

# 3D Node references
var shaft: MeshInstance3D
var search_coil: Node3D
var control_unit: Node3D
var display_screen: MeshInstance3D
var screen_material: StandardMaterial3D

func _ready() -> void:
	name = "LunarMetalDetector"
	_build_detector_model()
	_setup_audio()
	add_to_group("metal_detector")

func _build_detector_model() -> void:
	# Materials
	var mat_shaft = StandardMaterial3D.new()
	mat_shaft.albedo_color = Color(0.18, 0.20, 0.22) # Anodized titanium / carbon fiber
	mat_shaft.metallic = 0.8
	mat_shaft.roughness = 0.35

	var mat_coil = StandardMaterial3D.new()
	mat_coil.albedo_color = Color(0.88, 0.89, 0.92) # Matte white thermal-insulating ABS
	mat_coil.roughness = 0.6
	mat_coil.metallic = 0.1

	var mat_grip = StandardMaterial3D.new()
	mat_grip.albedo_color = Color(0.12, 0.13, 0.15) # High-friction EVA spacesuit grip
	mat_grip.roughness = 0.95

	var mat_yellow = StandardMaterial3D.new()
	mat_yellow.albedo_color = Color(0.95, 0.75, 0.1) # NASA flight hardware accent
	mat_yellow.roughness = 0.4

	screen_material = StandardMaterial3D.new()
	screen_material.albedo_color = Color(0.05, 0.12, 0.08)
	screen_material.emission_enabled = true
	screen_material.emission = Color(0.1, 0.85, 0.3)
	screen_material.emission_energy_multiplier = 1.0

	# 1. Main Rigid Shaft (88 cm long, angled forward-downward from astronaut hand)
	shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var shaft_mesh = CylinderMesh.new()
	shaft_mesh.top_radius = 0.016
	shaft_mesh.bottom_radius = 0.014
	shaft_mesh.height = 0.88
	shaft_mesh.material = mat_shaft
	shaft.mesh = shaft_mesh
	# Center shaft along local Z pointing forward-downward
	shaft.rotation.x = deg_to_rad(-48.0)
	shaft.position = Vector3(0.0, -0.28, 0.32)
	add_child(shaft)

	# 2. Forearm cuff and ergonomic handle
	var cuff = MeshInstance3D.new()
	var cuff_mesh = TorusMesh.new()
	cuff_mesh.inner_radius = 0.055
	cuff_mesh.outer_radius = 0.075
	cuff_mesh.material = mat_grip
	cuff.mesh = cuff_mesh
	cuff.position = Vector3(0.0, 0.36, 0.0)
	cuff.rotation.x = deg_to_rad(90.0)
	shaft.add_child(cuff)

	var handle = MeshInstance3D.new()
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.022
	handle_mesh.bottom_radius = 0.022
	handle_mesh.height = 0.14
	handle_mesh.material = mat_grip
	handle.mesh = handle_mesh
	handle.position = Vector3(0.0, 0.22, 0.06)
	handle.rotation.x = deg_to_rad(35.0)
	shaft.add_child(handle)

	# 3. Control & Display Housing
	control_unit = Node3D.new()
	control_unit.name = "ControlUnit"
	control_unit.position = Vector3(0.0, 0.18, 0.04)
	shaft.add_child(control_unit)

	var box = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.10, 0.13, 0.06)
	box_mesh.material = mat_shaft
	box.mesh = box_mesh
	control_unit.add_child(box)

	# Screen display
	display_screen = MeshInstance3D.new()
	display_screen.name = "DisplayScreen"
	var screen_mesh = BoxMesh.new()
	screen_mesh.size = Vector3(0.08, 0.09, 0.01)
	screen_mesh.material = screen_material
	display_screen.mesh = screen_mesh
	display_screen.position = Vector3(0.0, 0.01, 0.032)
	control_unit.add_child(display_screen)

	# 4. Search Coil (26 cm diameter circular search loop at bottom tip)
	search_coil = Node3D.new()
	search_coil.name = "SearchCoil"
	# Position at bottom of shaft
	search_coil.position = Vector3(0.0, -0.44, 0.0)
	# Level the coil parallel to the ground surface
	search_coil.rotation.x = deg_to_rad(48.0)
	shaft.add_child(search_coil)

	# Outer search ring (26 cm outer diameter)
	var outer_ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.11
	ring_mesh.outer_radius = 0.13
	ring_mesh.material = mat_coil
	outer_ring.mesh = ring_mesh
	search_coil.add_child(outer_ring)

	# Inner concentric loop
	var inner_ring = MeshInstance3D.new()
	var inner_mesh = TorusMesh.new()
	inner_mesh.inner_radius = 0.045
	inner_mesh.outer_radius = 0.06
	inner_mesh.material = mat_coil
	inner_ring.mesh = inner_mesh
	search_coil.add_child(inner_ring)

	# Cross struts connecting coil to shaft hub
	for strut_i in range(2):
		var strut = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(0.24, 0.012, 0.018)
		s_mesh.material = mat_coil
		strut.mesh = s_mesh
		strut.rotation.y = strut_i * (PI / 2.0)
		search_coil.add_child(strut)

	# 5. Coiled Cable winding along the shaft
	for c_i in range(8):
		var wrap = MeshInstance3D.new()
		var wrap_mesh = TorusMesh.new()
		wrap_mesh.inner_radius = 0.018
		wrap_mesh.outer_radius = 0.024
		wrap_mesh.rings = 10
		wrap_mesh.material = mat_grip
		wrap.mesh = wrap_mesh
		wrap.position.y = remap(c_i, 0, 7, -0.38, 0.12)
		wrap.rotation.x = deg_to_rad(15.0)
		shaft.add_child(wrap)

func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	_audio_player.bus = &"Master"
	_audio_player.volume_db = -14.0

	# Synthesize headset electromagnetic detector tone (740 Hz to 1250 Hz)
	var sample_rate = 22050
	var duration = 0.065
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var wave = sin(t * 880.0 * TAU) * exp(-t * 30.0)
		data[i] = clampi(int((wave + 1.0) * 0.5 * 255.0), 0, 255)

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.data = data
	_audio_player.stream = wav

func _process(delta: float) -> void:
	if not _is_active:
		return

	# Handle audio beep cadence according to electromagnetic signal
	if _current_signal > 0.08:
		_audio_timer += delta
		var beep_rate = lerp(1.2, 0.10, _current_signal)
		if _audio_timer >= beep_rate:
			_audio_timer = 0.0
			if _audio_player and not _audio_player.playing:
				_audio_player.pitch_scale = lerp(0.85, 1.45, _current_signal)
				_audio_player.play()

# Updates signal strength and screen display
func set_signal(strength: float, distance: float) -> void:
	_current_signal = clampf(strength, 0.0, 1.0)
	metal_anomaly_detected.emit(distance, _current_signal)

	if screen_material:
		# Display color shifts from muted green (idle) to bright amber/gold (anomaly)
		var col = Color(0.1, 0.8, 0.3).lerp(Color(1.0, 0.85, 0.1), _current_signal)
		screen_material.emission = col
		screen_material.emission_energy_multiplier = 0.8 + _current_signal * 3.0

# Sweeping animation for third-person prospecting
func apply_sweep_motion(delta: float, is_moving: bool) -> void:
	if not shaft:
		return
	var sweep_speed = 3.2 if is_moving else 2.4
	_sweep_phase += delta * sweep_speed
	var sweep_angle = sin(_sweep_phase) * deg_to_rad(24.0)
	shaft.rotation.y = lerp_angle(shaft.rotation.y, sweep_angle, 8.0 * delta)

func get_coil_global_position() -> Vector3:
	if search_coil:
		return search_coil.global_position
	return global_position
