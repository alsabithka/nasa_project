extends Node3D

# Echoes Beyond Earth - Photorealistic Mars Atmospheric System
# Scientifically grounded in NASA Viking, Pathfinder, Curiosity and Perseverance meteorological data:
# 1. THIN CO2 ATMOSPHERE & ACOUSTICS:
#    - Surface pressure: 6.1 hPa (~0.006 atm).
#    - Wind sound attenuation and gentle aerodynamic breeze around spacesuit visor.
# 2. SUSPENDED DUST & SALTATION:
#    - Fine ferric oxide (Fe2O3) dust suspended in the atmosphere.
#    - Eolian saltation (sand grains creeping along the ground in gusts).
# 3. CONVECTIVE DUST DEVILS:
#    - Slender rotating convective vortices traversing the Jezero plains.
#    - Vertical updraft and helical dust trajectories.

@export var base_wind_speed: float = 8.5 # m/s
@export var wind_direction: Vector2 = Vector2(0.85, 0.52).normalized()
@export var enable_dust_devils: bool = true

var _wind_audio: AudioStreamPlayer
var _suspended_dust: CPUParticles3D
var _saltation_dust: CPUParticles3D
var _dust_devils: Array[Node3D] = []
var _time: float = 0.0

func _ready() -> void:
	name = "MarsAtmosphereSystem"
	add_to_group("mars_atmosphere")
	_setup_wind_acoustics()
	_setup_suspended_dust()
	_setup_saltation_particles()
	if enable_dust_devils:
		_spawn_dust_devils()

func _setup_wind_acoustics() -> void:
	_wind_audio = AudioStreamPlayer.new()
	_wind_audio.name = "MartianWindAudio"
	_wind_audio.bus = &"Master"
	_wind_audio.volume_db = -18.0
	add_child(_wind_audio)

	# Procedural band-limited Martian wind noise (muffled high frequencies in 610 Pa CO2)
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples)

	var last_val = 0.0
	for i in range(num_samples):
		var white = randf() * 2.0 - 1.0
		# Low-pass filter simulating sound absorption in carbon dioxide
		last_val = lerp(last_val, white, 0.08)
		# Add subtle low gust resonance (35-70 Hz)
		var t = float(i) / float(sample_rate)
		var gust = sin(t * 42.0 * TAU) * 0.18 + sin(t * 68.0 * TAU) * 0.12
		var s = (last_val * 0.7 + gust) * 0.35
		data[i] = clampi(int((s + 1.0) * 0.5 * 255.0), 0, 255)

	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data

	_wind_audio.stream = wav
	_wind_audio.play()

func _setup_suspended_dust() -> void:
	_suspended_dust = CPUParticles3D.new()
	_suspended_dust.name = "SuspendedAtmosphericDust"
	_suspended_dust.amount = 48
	_suspended_dust.lifetime = 6.0
	_suspended_dust.preprocess = 3.0
	_suspended_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_suspended_dust.emission_box_extents = Vector3(35.0, 8.0, 35.0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.42, 0.24, 0.35) # Ferric oxide dust
	mat.roughness = 0.95
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX

	var sphere = SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	sphere.radial_segments = 4
	sphere.rings = 2
	sphere.material = mat
	_suspended_dust.mesh = sphere

	# Wind drift
	_suspended_dust.direction = Vector3(wind_direction.x, -0.08, wind_direction.y).normalized()
	_suspended_dust.spread = 20.0
	_suspended_dust.initial_velocity_min = 1.2
	_suspended_dust.initial_velocity_max = 2.4
	_suspended_dust.gravity = Vector3(0, -0.2, 0)
	add_child(_suspended_dust)

func _setup_saltation_particles() -> void:
	_saltation_dust = CPUParticles3D.new()
	_saltation_dust.name = "GroundSaltationDust"
	_saltation_dust.amount = 32
	_saltation_dust.lifetime = 2.5
	_saltation_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_saltation_dust.emission_box_extents = Vector3(25.0, 0.4, 25.0)

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.72, 0.38, 0.22, 0.45)

	var sphere = SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	sphere.radial_segments = 4
	sphere.rings = 2
	sphere.material = mat
	_saltation_dust.mesh = sphere

	_saltation_dust.direction = Vector3(wind_direction.x, 0.12, wind_direction.y).normalized()
	_saltation_dust.spread = 15.0
	_saltation_dust.initial_velocity_min = 2.0
	_saltation_dust.initial_velocity_max = 3.8
	_saltation_dust.gravity = Vector3(0, -3.71, 0)
	add_child(_saltation_dust)

func _spawn_dust_devils() -> void:
	# 2 natural convective vortices patrolling distinct zones in the valley / dunes
	var origins = [Vector3(-28.0, 0.0, 34.0), Vector3(36.0, 0.0, -22.0)]
	for i in range(origins.size()):
		var devil = Node3D.new()
		devil.name = "DustDevil_%d" % (i + 1)
		devil.position = origins[i]

		# Visual rotating column
		var col_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 2.4
		cyl.bottom_radius = 0.6
		cyl.height = 14.0
		cyl.radial_segments = 12

		var devil_mat = StandardMaterial3D.new()
		devil_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		devil_mat.albedo_color = Color(0.75, 0.42, 0.25, 0.18)
		devil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cyl.material = devil_mat
		col_mesh.mesh = cyl
		col_mesh.position.y = 7.0
		devil.add_child(col_mesh)

		# Swirling dust particles
		var p = CPUParticles3D.new()
		p.name = "SwirlParticles"
		p.amount = 36
		p.lifetime = 3.5
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(1.8, 6.0, 1.8)

		var p_mat = StandardMaterial3D.new()
		p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		p_mat.albedo_color = Color(0.78, 0.44, 0.26, 0.35)
		var sp = SphereMesh.new()
		sp.radius = 0.03
		sp.height = 0.06
		sp.material = p_mat
		p.mesh = sp

		p.direction = Vector3(0, 1, 0)
		p.spread = 25.0
		p.initial_velocity_min = 2.5
		p.initial_velocity_max = 5.0
		p.gravity = Vector3(0, 0.5, 0) # Updraft
		devil.add_child(p)

		add_child(devil)
		_dust_devils.append(devil)

func _process(delta: float) -> void:
	_time += delta

	# Track player location so dust stays centered around astronaut
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if _suspended_dust:
			_suspended_dust.global_position.x = player.global_position.x
			_suspended_dust.global_position.z = player.global_position.z
			_suspended_dust.global_position.y = player.global_position.y + 4.0
		if _saltation_dust:
			_saltation_dust.global_position.x = player.global_position.x
			_saltation_dust.global_position.z = player.global_position.z
			_saltation_dust.global_position.y = player.global_position.y + 0.2

	# Modulate wind audio volume based on gust cycle
	if _wind_audio:
		var gust = sin(_time * 0.35) * 2.5 + cos(_time * 0.8) * 1.5
		_wind_audio.volume_db = -19.0 + gust

	# Move and spin dust devils along natural wandering trajectories
	for i in range(_dust_devils.size()):
		var devil = _dust_devils[i]
		if not is_instance_valid(devil):
			continue
		devil.rotate_y(3.2 * delta)
		# Wandering path
		var t_off = _time * 0.15 + float(i) * 3.14
		devil.position.x += cos(t_off) * 1.8 * delta + wind_direction.x * 0.8 * delta
		devil.position.z += sin(t_off * 1.3) * 1.8 * delta + wind_direction.y * 0.8 * delta
