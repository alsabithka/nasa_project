extends Node3D

# Procedural Lunar Surface Generator
# Creates an authentic lunar environment: craters, boulders, regolith hills, Earth in sky, and footprint trails.

@export var terrain_size: float = 140.0
@export var ground_seed: int = 1969

func _ready() -> void:
	_create_lunar_ground()
	_create_craters()
	_create_boulder_fields()
	_create_footprint_trails()
	_create_distant_horizon()
	_create_earth_in_sky()

func _create_lunar_ground() -> void:
	# Main lunar regolith ground body
	var body = StaticBody3D.new()
	body.name = "RegolithGround"
	body.collision_layer = 1
	body.collision_mask = 2
	add_child(body)
	
	# Base ground plane with lunar regolith material
	var ground_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(terrain_size, terrain_size)
	plane.subdivide_width = 30
	plane.subdivide_depth = 30
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.44, 0.46, 0.48) # Ash grey lunar regolith
	mat.roughness = 0.95
	mat.metallic = 0.02
	plane.material = mat
	ground_mesh.mesh = plane
	body.add_child(ground_mesh)
	
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(terrain_size, 0.6, terrain_size)
	col.shape = box_shape
	col.position = Vector3(0, -0.3, 0)
	body.add_child(col)
	
	# Undulating gentle mounds/ridges across the lunar surface
	var mound_positions = [
		Vector3(-25, -0.2, -35), Vector3(30, -0.1, -20),
		Vector3(-40, -0.2, 20), Vector3(35, -0.15, 30),
		Vector3(0, -0.2, -50), Vector3(-10, -0.1, 45)
	]
	var mound_scales = [
		Vector3(22, 1.8, 18), Vector3(25, 2.2, 25),
		Vector3(28, 2.5, 20), Vector3(20, 1.6, 22),
		Vector3(35, 3.0, 25), Vector3(30, 2.4, 25)
	]
	
	var mound_mat = StandardMaterial3D.new()
	mound_mat.albedo_color = Color(0.40, 0.42, 0.44)
	mound_mat.roughness = 0.96
	
	for i in range(mound_positions.size()):
		var mound = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radial_segments = 16
		s_mesh.rings = 8
		s_mesh.material = mound_mat
		mound.mesh = s_mesh
		mound.scale = mound_scales[i]
		mound.position = mound_positions[i]
		body.add_child(mound)
		
		# Collision for mounds
		var m_col = CollisionShape3D.new()
		var m_shape = SphereShape3D.new()
		m_shape.radius = 1.0
		m_col.shape = m_shape
		m_col.scale = mound_scales[i]
		m_col.position = mound_positions[i]
		body.add_child(m_col)

func _create_craters() -> void:
	# Prominent lunar craters with raised rims and dark interior floors
	var crater_data = [
		{"pos": Vector3(18, 0, 12), "radius": 7.0, "rim_height": 0.9, "inner": 5.5},   # LRV crater site
		{"pos": Vector3(-16, 0, -18), "radius": 8.5, "rim_height": 1.1, "inner": 6.8}, # Descent stage site
		{"pos": Vector3(-20, 0, 15), "radius": 6.0, "rim_height": 0.75, "inner": 4.8}, # ALSEP crater rim
		{"pos": Vector3(38, 0, -15), "radius": 11.0, "rim_height": 1.6, "inner": 8.5}, # Large background crater
		{"pos": Vector3(-45, 0, -28), "radius": 13.0, "rim_height": 1.8, "inner": 10.0},
		{"pos": Vector3(8, 0, -35), "radius": 5.0, "rim_height": 0.6, "inner": 3.8},
		{"pos": Vector3(-32, 0, 38), "radius": 7.5, "rim_height": 1.0, "inner": 5.8},
		{"pos": Vector3(45, 0, 25), "radius": 9.0, "rim_height": 1.2, "inner": 7.0}
	]
	
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.38, 0.40, 0.42)
	rim_mat.roughness = 0.96
	
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.28, 0.30, 0.32) # Darker basalt dust in crater floor
	floor_mat.roughness = 0.98
	
	for c in crater_data:
		var pos: Vector3 = c["pos"]
		var r: float = c["radius"]
		var h: float = c["rim_height"]
		
		# Torus-shaped crater rim
		var rim = MeshInstance3D.new()
		var torus = TorusMesh.new()
		torus.outer_radius = r
		torus.inner_radius = c["inner"]
		torus.rings = 24
		torus.ring_segments = 12
		torus.material = rim_mat
		rim.mesh = torus
		rim.position = Vector3(pos.x, h * 0.4, pos.z)
		rim.scale = Vector3(1.0, h / ((r - c["inner"]) * 0.5), 1.0)
		add_child(rim)
		
		# Depressed dark interior floor
		var floor_mesh = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = c["inner"] * 0.95
		cyl.bottom_radius = c["inner"] * 0.95
		cyl.height = 0.08
		cyl.material = floor_mat
		floor_mesh.mesh = cyl
		floor_mesh.position = Vector3(pos.x, 0.02, pos.z)
		add_child(floor_mesh)

func _create_boulder_fields() -> void:
	# Scattered lunar ejecta rocks and boulders with faceted geometric shapes
	var rock_mat_light = StandardMaterial3D.new()
	rock_mat_light.albedo_color = Color(0.48, 0.50, 0.52)
	rock_mat_light.roughness = 0.95
	
	var rock_mat_dark = StandardMaterial3D.new()
	rock_mat_dark.albedo_color = Color(0.32, 0.34, 0.36)
	rock_mat_dark.roughness = 0.98
	
	var rock_data = [
		{"pos": Vector3(7, 0.5, 6), "scale": Vector3(1.4, 0.9, 1.2), "rot": Vector3(12, 45, 8), "dark": false},
		{"pos": Vector3(14, 0.7, 8), "scale": Vector3(1.8, 1.2, 1.5), "rot": Vector3(-8, 30, 15), "dark": true},
		{"pos": Vector3(22, 0.6, 16), "scale": Vector3(1.6, 1.0, 1.4), "rot": Vector3(20, 90, 0), "dark": false},
		{"pos": Vector3(-8, 0.6, -10), "scale": Vector3(1.5, 1.0, 1.3), "rot": Vector3(5, 60, -10), "dark": true},
		{"pos": Vector3(-13, 0.8, -14), "scale": Vector3(2.2, 1.4, 1.9), "rot": Vector3(-15, 20, 5), "dark": false},
		{"pos": Vector3(-21, 0.5, -22), "scale": Vector3(1.3, 0.8, 1.1), "rot": Vector3(10, 110, 15), "dark": true},
		{"pos": Vector3(-15, 0.6, 10), "scale": Vector3(1.7, 1.1, 1.5), "rot": Vector3(-10, 45, -5), "dark": false},
		{"pos": Vector3(-25, 0.7, 19), "scale": Vector3(2.0, 1.3, 1.8), "rot": Vector3(18, 75, 12), "dark": true},
		{"pos": Vector3(28, 1.2, -8), "scale": Vector3(3.2, 2.2, 2.8), "rot": Vector3(8, 15, -8), "dark": false},
		{"pos": Vector3(32, 0.5, -12), "scale": Vector3(1.4, 0.9, 1.2), "rot": Vector3(-12, 85, 20), "dark": true},
		{"pos": Vector3(-35, 1.4, 8), "scale": Vector3(3.8, 2.5, 3.2), "rot": Vector3(14, 120, -12), "dark": true},
		{"pos": Vector3(-38, 0.6, 14), "scale": Vector3(1.5, 1.0, 1.3), "rot": Vector3(5, 30, 10), "dark": false},
		{"pos": Vector3(4, 0.35, -22), "scale": Vector3(1.0, 0.6, 0.9), "rot": Vector3(25, 50, -15), "dark": false},
		{"pos": Vector3(10, 0.45, -26), "scale": Vector3(1.2, 0.8, 1.1), "rot": Vector3(-5, 140, 8), "dark": true},
		{"pos": Vector3(-5, 0.4, 25), "scale": Vector3(1.1, 0.7, 1.0), "rot": Vector3(15, 40, 0), "dark": false},
		{"pos": Vector3(24, 0.5, 28), "scale": Vector3(1.4, 0.9, 1.3), "rot": Vector3(-18, 65, 14), "dark": true},
		{"pos": Vector3(-28, 0.9, -32), "scale": Vector3(2.4, 1.6, 2.1), "rot": Vector3(10, 10, -10), "dark": false},
		{"pos": Vector3(18, 0.4, -38), "scale": Vector3(1.2, 0.7, 1.0), "rot": Vector3(-8, 95, 18), "dark": true}
	]
	
	for r in rock_data:
		var rock_body = StaticBody3D.new()
		rock_body.position = r["pos"]
		rock_body.rotation_degrees = r["rot"]
		rock_body.scale = r["scale"]
		add_child(rock_body)
		
		var rock_mesh = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radial_segments = 8  # Faceted, angular look
		s_mesh.rings = 5
		s_mesh.material = rock_mat_dark if r["dark"] else rock_mat_light
		rock_mesh.mesh = s_mesh
		rock_body.add_child(rock_mesh)
		
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 0.85
		col.shape = shape
		rock_body.add_child(col)

func _create_footprint_trails() -> void:
	# Visible astronaut bootprints and rover wheel tracks pressed into the grey dust
	var track_mat = StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.32, 0.34, 0.36) # Darker compacted lunar soil
	track_mat.roughness = 0.99
	
	# Trail 1: Origin (0,0,0) toward Lunar Roving Vehicle (18, 0, 12)
	_build_trail(Vector3(0, 0.005, 0), Vector3(16, 0.005, 11), 16, track_mat, true)
	
	# Trail 2: Origin (0,0,0) toward Descent Stage (-16, 0, -18)
	_build_trail(Vector3(0, 0.005, 0), Vector3(-14, 0.005, -16), 14, track_mat, false)
	
	# Trail 3: Origin (0,0,0) toward ALSEP site (-20, 0, 15)
	_build_trail(Vector3(0, 0.005, 0), Vector3(-18, 0.005, 14), 14, track_mat, false)

func _build_trail(start_pos: Vector3, end_pos: Vector3, steps: int, mat: Material, is_rover: bool) -> void:
	var dir = (end_pos - start_pos) / float(steps)
	var perp = Vector3(-dir.z, 0, dir.x).normalized()
	
	for i in range(1, steps):
		var center = start_pos + dir * float(i)
		
		if is_rover and i > 4:
			# Twin parallel rover wheel tracks
			for side in [-0.65, 0.65]:
				var track = MeshInstance3D.new()
				var p = PlaneMesh.new()
				p.size = Vector2(0.28, 0.7)
				p.material = mat
				track.mesh = p
				track.position = center + perp * side
				track.rotation.y = atan2(dir.x, dir.z)
				add_child(track)
		else:
			# Staggered left/right astronaut bootprints
			var side_offset = 0.22 if (i % 2 == 0) else -0.22
			var boot = MeshInstance3D.new()
			var p = PlaneMesh.new()
			p.size = Vector2(0.22, 0.38)
			p.material = mat
			boot.mesh = p
			boot.position = center + perp * side_offset
			boot.rotation.y = atan2(dir.x, dir.z)
			add_child(boot)

func _create_distant_horizon() -> void:
	# Subtle mountain ridges on the distant lunar horizon
	var horizon_mat = StandardMaterial3D.new()
	horizon_mat.albedo_color = Color(0.24, 0.26, 0.28)
	horizon_mat.roughness = 0.98
	
	var horizon_angles = [0, 45, 90, 135, 180, 225, 270, 315]
	var dist = 95.0
	
	for a in horizon_angles:
		var rad = deg_to_rad(a)
		var peak = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = 0.5
		p_mesh.bottom_radius = 28.0
		p_mesh.height = 14.0
		p_mesh.radial_segments = 12
		p_mesh.material = horizon_mat
		peak.mesh = p_mesh
		peak.position = Vector3(sin(rad) * dist, 2.0, cos(rad) * dist)
		peak.scale = Vector3(1.2, 0.6, 1.2)
		add_child(peak)

func _create_earth_in_sky() -> void:
	# Earth visible as a majestic blue marble in the lunar sky
	var earth_root = Node3D.new()
	earth_root.name = "EarthInSky"
	# Position high in the black sky
	earth_root.position = Vector3(180, 110, -260)
	add_child(earth_root)
	
	# Earth sphere
	var earth_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 18.0
	sphere.height = 36.0
	sphere.radial_segments = 32
	sphere.rings = 16
	
	var earth_mat = StandardMaterial3D.new()
	# Vibrant deep ocean blue with swirling white cloud accents
	earth_mat.albedo_color = Color(0.18, 0.45, 0.85)
	earth_mat.roughness = 0.3
	earth_mat.emission_enabled = true
	earth_mat.emission = Color(0.12, 0.35, 0.70)
	earth_mat.emission_energy_multiplier = 0.4
	sphere.material = earth_mat
	earth_mesh.mesh = sphere
	earth_mesh.rotation_degrees = Vector3(23.5, -40, 15)
	earth_root.add_child(earth_mesh)
	
	# Atmosphere glow ring
	var glow_mesh = MeshInstance3D.new()
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = 18.8
	glow_sphere.height = 37.6
	glow_sphere.radial_segments = 24
	glow_sphere.rings = 12
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color = Color(0.5, 0.8, 1.0, 0.22)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.4, 0.75, 1.0)
	glow_mat.emission_energy_multiplier = 0.6
	glow_sphere.material = glow_mat
	glow_mesh.mesh = glow_sphere
	earth_root.add_child(glow_mesh)
