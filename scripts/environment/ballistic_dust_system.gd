extends Node3D

# Echoes Beyond Earth - Subtle Realistic Lunar Regolith Dust Simulation
# Scientifically grounded in real Apollo surface observations:
# 1. Subtle, small regolith particles disturbed directly around the boot sole (no large clouds or smoke).
# 2. Strict vacuum physics: air drag = 0.0, no atmospheric drifting, billows, or wind.
# 3. Pure ballistic parabolas under exact 1.62 m/s² lunar gravity:
#    Particles rise slightly (10-25 cm) and fall naturally back onto the surface.
# 4. Intensity corresponds directly to the strength of ground contact.

var _dust_pool: Array[CPUParticles3D] = []
var _pool_index: int = 0
const POOL_SIZE: int = 16

func _ready() -> void:
	name = "BallisticDustSystem"
	_init_dust_pool()

func _init_dust_pool() -> void:
	# Subtle, realistic small lunar regolith grain material
	var particle_mat = StandardMaterial3D.new()
	particle_mat.albedo_color = Color(0.44, 0.45, 0.47, 0.75) # Fine ash-grey lunar soil
	particle_mat.roughness = 0.98
	particle_mat.metallic = 0.02
	
	# Small, fine grain geometry (8 mm radius)
	var sphere = SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere.material = particle_mat
	
	for i in range(POOL_SIZE):
		var p = CPUParticles3D.new()
		p.name = "BallisticDust_%d" % i
		p.emitting = false
		p.one_shot = true
		p.mesh = sphere
		p.amount = 8 # Subtle, small particle count
		p.lifetime = 0.8 # Natural ballistic arc duration
		p.explosiveness = 0.95
		p.randomness = 0.35
		
		# Exact lunar gravitational acceleration
		p.gravity = Vector3(0, -1.62, 0)
		p.damping_min = 0.0
		p.damping_max = 0.0 # Strict vacuum: ZERO air drag/floating
		
		p.direction = Vector3(0, 1, 0)
		p.spread = 35.0
		p.initial_velocity_min = 0.35
		p.initial_velocity_max = 0.75
		
		add_child(p)
		_dust_pool.append(p)

# Spawns a small, subtle disturbance of lunar dust around the boot sole during walking/hopping
func emit_footstep_dust(pos: Vector3, move_direction: Vector3, is_loping: bool) -> void:
	var p = _get_next_particle()
	if not p:
		return
	
	p.global_position = pos + Vector3(0, 0.02, 0)
	p.amount = 10 if is_loping else 6 # Very subtle particle emission
	p.lifetime = 0.85 if is_loping else 0.65
	
	# Low-angle subtle spray around the boot sole
	var kick_dir = (Vector3.UP * 0.88 + move_direction * 0.12).normalized()
	p.direction = kick_dir
	p.spread = 40.0
	p.initial_velocity_min = 0.4 if is_loping else 0.28
	p.initial_velocity_max = 0.85 if is_loping else 0.55
	p.restart()

# Spawns a subtle, natural dust dispersal upon landing or jump takeoff based on contact strength
func emit_impact_dust(pos: Vector3, impact_strength: float) -> void:
	var p = _get_next_particle()
	if not p:
		return
	
	p.global_position = pos + Vector3(0, 0.015, 0)
	# Subtle particle count scaled with landing force (8 to 16 particles)
	var count = clampi(int(impact_strength * 10), 8, 16)
	p.amount = count
	p.lifetime = 0.85 + clampf(impact_strength * 0.15, 0.0, 0.3)
	
	# Low-angle radial dispersal around feet
	p.direction = Vector3(0, 1, 0)
	p.spread = 50.0
	p.initial_velocity_min = 0.35
	p.initial_velocity_max = clampf(0.6 * impact_strength, 0.45, 1.1)
	p.restart()

func _get_next_particle() -> CPUParticles3D:
	if _dust_pool.is_empty():
		return null
	var p = _dust_pool[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	return p
