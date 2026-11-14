extends Node3D

# Echoes Beyond Earth - Vacuum Ballistic Regolith Dust Simulation
# Scientifically accurate lunar dust mechanics:
# 1. Vacuum condition: Air drag = 0.0 (no billowing, no drifting clouds, no floating smoke).
# 2. Lunar gravity = 1.62 m/s²: Kicked regolith particles travel on pure ballistic parabolas.
# 3. Particle lifetime and trajectories are calculated so particles hit the regolith and settle instantly.

var _dust_pool: Array[CPUParticles3D] = []
var _pool_index: int = 0
const POOL_SIZE: int = 16

func _ready() -> void:
	name = "BallisticDustSystem"
	_init_dust_pool()

func _init_dust_pool() -> void:
	var particle_mat = StandardMaterial3D.new()
	particle_mat.albedo_color = Color(0.42, 0.44, 0.46, 0.95)
	particle_mat.roughness = 0.98
	particle_mat.metallic = 0.02
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere.material = particle_mat
	
	for i in range(POOL_SIZE):
		var p = CPUParticles3D.new()
		p.name = "BallisticDust_%d" % i
		p.emitting = false
		p.one_shot = true
		p.mesh = sphere
		p.amount = 28
		p.lifetime = 1.6 # Realistic time for a 1.62 m/s² ballistic arc
		p.explosiveness = 0.95
		p.randomness = 0.3
		
		# Exact lunar gravity vector
		p.gravity = Vector3(0, -1.62, 0)
		p.damping_min = 0.0
		p.damping_max = 0.0 # Strict vacuum: ZERO air resistance
		
		p.direction = Vector3(0, 1, 0)
		p.spread = 45.0
		p.initial_velocity_min = 1.2
		p.initial_velocity_max = 2.4
		
		add_child(p)
		_dust_pool.append(p)

# Spawns a localized ballistic spray behind a moving astronaut boot
func emit_footstep_dust(pos: Vector3, move_direction: Vector3, is_loping: bool) -> void:
	var p = _get_next_particle()
	if not p:
		return
	
	p.global_position = pos + Vector3(0, 0.03, 0)
	p.amount = 36 if is_loping else 20
	p.lifetime = 1.8 if is_loping else 1.3
	
	# Low angle spray kicked back/upward from sole contact
	var kick_dir = (-move_direction * 0.7 + Vector3.UP * 0.8).normalized()
	p.direction = kick_dir
	p.spread = 50.0
	p.initial_velocity_min = 1.5 if is_loping else 0.8
	p.initial_velocity_max = 3.2 if is_loping else 1.8
	p.restart()

# Spawns a 360-degree radial ballistic sheet upon touchdown or jump
func emit_impact_dust(pos: Vector3, impact_strength: float) -> void:
	var p = _get_next_particle()
	if not p:
		return
	
	p.global_position = pos + Vector3(0, 0.02, 0)
	var count = clampi(int(impact_strength * 45), 24, 64)
	p.amount = count
	p.lifetime = 1.6 + impact_strength * 0.4
	
	# Radial 360-degree flat sheet spreading outwards
	p.direction = Vector3(0, 1, 0)
	p.spread = 85.0
	p.initial_velocity_min = 1.2 * impact_strength
	p.initial_velocity_max = 3.4 * impact_strength
	p.restart()

func _get_next_particle() -> CPUParticles3D:
	if _dust_pool.is_empty():
		return null
	var p = _dust_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	return p
