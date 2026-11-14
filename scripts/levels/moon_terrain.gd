extends Node3D

# Echoes Beyond Earth - Realistic Lunar Surface Environment
# Designed in accordance with NASA Apollo 11, 15, 17 and LROC photographic data.
# Features:
# - Continuous procedural heightmap terrain with undulating mare topography
# - Physically authentic impact craters: raised rims, parabolic inner bowls, central peaks, and ejecta blankets
# - Multi-scale rock and boulder fields with collision on landmark boulders
# - Two-tone lunar regolith shading (dark mare basalt floors vs lighter anorthositic ejecta rims)
# - Exact trimesh ConcavePolygonShape3D collision (zero non-uniform scaling glitches, zero falling through)
# - Astronaut bootprints and dual rover tire tracks conforming to terrain elevation
# - Distant mountain massif horizon (resembling Apollo 15 Apennine / Apollo 17 Taurus-Littrow ridges)
# - Earth in the deep black sky
# - Automatic surface height snapping for Player and historical equipment

@export var terrain_size: float = 160.0
@export var grid_subdivisions: int = 110
@export var ground_seed: int = 1969

# Static body and mesh instances
var terrain_body: StaticBody3D
var terrain_mesh_instance: MeshInstance3D

# Authentic Apollo-era impact craters catalog
# Positioned to frame the 3 historical artifact recovery sites:
# 1. LRV at (18, y, 12) on crater rim/ejecta
# 2. LM Descent Stage at (-16, y, -18) on smooth landing plain near degraded crater
# 3. ALSEP at (-20, y, 15) on undisturbed regolith
var craters: Array = [
	# Artifact vicinity craters
	{"pos": Vector2(21.0, 14.0), "radius": 7.5, "rim": 0.85, "depth": 1.7, "peak": false},  # LRV rim crater
	{"pos": Vector2(-22.0, -22.0), "radius": 9.0, "rim": 1.10, "depth": 2.2, "peak": false}, # LM site crater
	{"pos": Vector2(-25.0, 18.0), "radius": 5.5, "rim": 0.65, "depth": 1.3, "peak": false},  # ALSEP site crater
	
	# Prominent landscape craters
	{"pos": Vector2(44.0, -26.0), "radius": 15.5, "rim": 2.2, "depth": 4.5, "peak": true},   # Large complex crater with central peak
	{"pos": Vector2(-46.0, 32.0), "radius": 12.5, "rim": 1.6, "depth": 3.2, "peak": false},  # Northwest crater
	{"pos": Vector2(4.0, -48.0), "radius": 11.0, "rim": 1.4, "depth": 2.8, "peak": false},   # South crater
	{"pos": Vector2(-52.0, -14.0), "radius": 9.5, "rim": 1.2, "depth": 2.4, "peak": false},  # West crater
	{"pos": Vector2(34.0, 36.0), "radius": 8.0, "rim": 1.0, "depth": 2.0, "peak": false},   # Northeast crater
	
	# Secondary micro-craters (pitted lunar regolith)
	{"pos": Vector2(5.0, 7.0), "radius": 3.0, "rim": 0.35, "depth": 0.7, "peak": false},
	{"pos": Vector2(-7.0, -5.0), "radius": 2.6, "rim": 0.30, "depth": 0.6, "peak": false},
	{"pos": Vector2(-9.0, 11.0), "radius": 3.2, "rim": 0.38, "depth": 0.75, "peak": false},
	{"pos": Vector2(11.0, -16.0), "radius": 3.8, "rim": 0.42, "depth": 0.85, "peak": false},
	{"pos": Vector2(-32.0, -40.0), "radius": 4.8, "rim": 0.55, "depth": 1.1, "peak": false},
	{"pos": Vector2(25.0, -40.0), "radius": 4.2, "rim": 0.48, "depth": 0.95, "peak": false}
]

func _ready() -> void:
	_generate_terrain_mesh_and_collision()
	_create_boulder_and_rock_fields()
	_create_footprints_and_rover_tracks()
	_create_distant_mountain_massifs()
	_create_earth_in_sky()
	_align_scene_objects_to_surface()

# Public height query method
func get_terrain_height(x: float, z: float) -> float:
	return _calc_height(x, z)

# Calculates the lunar surface elevation using multi-frequency rolling mare math and authentic crater profiles
func _calc_height(x: float, z: float) -> float:
	# 1. Base rolling hills (lunar mare dorsa and subtle undulating swells)
	var h = sin(x * 0.035) * cos(z * 0.030) * 1.5 + cos((x + z * 0.7) * 0.022) * 1.0 + sin((x * 0.6 - z) * 0.042) * 0.45
	
	# 2. Cumulative impact crater morphology
	for c in craters:
		var center: Vector2 = c["pos"]
		var R: float = c["radius"]
		var rim_h: float = c["rim"]
		var depth: float = c["depth"]
		var has_peak: bool = c.get("peak", false)
		
		var dist = Vector2(x, z).distance_to(center)
		if dist < R * 2.8:
			var u = dist / R
			if u < 1.0:
				# Parabolic inner bowl: drops to -depth at center, rises smoothly to +rim at u=1.0
				var bowl = -depth * (1.0 - u * u) + rim_h * (u * u)
				if has_peak and u < 0.28:
					var pu = u / 0.28
					bowl += (rim_h * 1.3) * (1.0 - pu * pu)
				h += bowl
			else:
				# Ejecta blanket: elevated rim tapering outward smoothly into ambient terrain
				var ejecta = rim_h * exp(-2.5 * (u - 1.0)) * (1.0 - clampf((u - 1.0) / 1.8, 0.0, 1.0))
				h += ejecta
	
	return h

# Computes vertex shading color: darker basalt for crater bowls, brighter pulverized anorthosite for rims/ejecta
func _calc_vertex_color(x: float, z: float) -> Color:
	# Base ash-grey regolith
	var base_col = Color(0.42, 0.44, 0.46)
	
	# Check proximity to craters
	for c in craters:
		var center: Vector2 = c["pos"]
		var R: float = c["radius"]
		var dist = Vector2(x, z).distance_to(center)
		if dist < R * 2.2:
			var u = dist / R
			if u < 0.85:
				# Darker basaltic floor
				var t = clampf(1.0 - u, 0.0, 1.0)
				return base_col.lerp(Color(0.25, 0.26, 0.28), t * 0.75)
			elif u >= 0.85 and u <= 1.25:
				# Bright pulverized impact ejecta and rim
				var t = 1.0 - absf(u - 1.05) / 0.25
				return base_col.lerp(Color(0.54, 0.56, 0.58), t * 0.65)
	
	# Subtle natural surface color micro-variation
	var var_tone = sin(x * 0.12) * cos(z * 0.14) * 0.03
	return Color(base_col.r + var_tone, base_col.g + var_tone, base_col.b + var_tone)

# Generates the continuous subdivided terrain mesh and attaches exact trimesh collision
func _generate_terrain_mesh_and_collision() -> void:
	terrain_body = StaticBody3D.new()
	terrain_body.name = "LunarTerrainBody"
	terrain_body.collision_layer = 1
	terrain_body.collision_mask = 2
	add_child(terrain_body)
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_size = terrain_size * 0.5
	var step = terrain_size / float(grid_subdivisions)
	var num_verts_per_side = grid_subdivisions + 1
	
	# Precalculate grid coordinates and heights
	var grid_pts: Array = []
	grid_pts.resize(num_verts_per_side)
	for i in range(num_verts_per_side):
		var row: Array = []
		row.resize(num_verts_per_side)
		var x = -half_size + float(i) * step
		for j in range(num_verts_per_side):
			var z = -half_size + float(j) * step
			var y = _calc_height(x, z)
			var col = _calc_vertex_color(x, z)
			var uv = Vector2(float(i) / float(grid_subdivisions) * 16.0, float(j) / float(grid_subdivisions) * 16.0)
			row[j] = {"pos": Vector3(x, y, z), "col": col, "uv": uv}
		grid_pts[i] = row
	
	# Build triangulated quads
	for i in range(grid_subdivisions):
		for j in range(grid_subdivisions):
			var p00: Dictionary = grid_pts[i][j]
			var p10: Dictionary = grid_pts[i + 1][j]
			var p01: Dictionary = grid_pts[i][j + 1]
			var p11: Dictionary = grid_pts[i + 1][j + 1]
			
			# Triangle 1: p00 -> p10 -> p11
			st.set_color(p00["col"])
			st.set_uv(p00["uv"])
			st.add_vertex(p00["pos"])
			
			st.set_color(p10["col"])
			st.set_uv(p10["uv"])
			st.add_vertex(p10["pos"])
			
			st.set_color(p11["col"])
			st.set_uv(p11["uv"])
			st.add_vertex(p11["pos"])
			
			# Triangle 2: p00 -> p11 -> p01
			st.set_color(p00["col"])
			st.set_uv(p00["uv"])
			st.add_vertex(p00["pos"])
			
			st.set_color(p11["col"])
			st.set_uv(p11["uv"])
			st.add_vertex(p11["pos"])
			
			st.set_color(p01["col"])
			st.set_uv(p01["uv"])
			st.add_vertex(p01["pos"])
	
	# Generate smooth per-vertex normals across the entire terrain
	st.generate_normals()
	
	var mesh = st.commit()
	
	# Realistic lunar regolith material
	var regolith_mat = StandardMaterial3D.new()
	regolith_mat.vertex_color_use_as_albedo = true
	regolith_mat.albedo_color = Color(1.0, 1.0, 1.0)
	regolith_mat.roughness = 0.96 # Highly diffuse, powdery lunar soil
	regolith_mat.metallic = 0.02
	regolith_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.surface_set_material(0, regolith_mat)
	
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "TerrainMesh"
	terrain_mesh_instance.mesh = mesh
	terrain_body.add_child(terrain_mesh_instance)
	
	# Exact trimesh ConcavePolygonShape3D collision (prevents falling through and collision normal anomalies)
	var col_shape = CollisionShape3D.new()
	col_shape.name = "TerrainCollisionShape"
	col_shape.shape = mesh.create_trimesh_shape()
	terrain_body.add_child(col_shape)

# Creates realistic multi-scale boulders and scattered rock debris
func _create_boulder_and_rock_fields() -> void:
	# Materials for weathered lunar basalt boulders
	var boulder_mat_dark = StandardMaterial3D.new()
	boulder_mat_dark.albedo_color = Color(0.28, 0.30, 0.32)
	boulder_mat_dark.roughness = 0.95
	
	var boulder_mat_light = StandardMaterial3D.new()
	boulder_mat_light.albedo_color = Color(0.46, 0.48, 0.50)
	boulder_mat_light.roughness = 0.94
	
	# 1. Landmark large boulders (with physically accurate convex collision)
	var large_boulders = [
		{"pos": Vector2(14.0, 8.0), "radius": 1.6, "h_scale": 1.1, "rot": Vector3(12, 35, -8), "dark": true},
		{"pos": Vector2(25.0, 17.0), "radius": 1.8, "h_scale": 1.3, "rot": Vector3(-10, 80, 15), "dark": false},
		{"pos": Vector2(-12.0, -12.0), "radius": 1.9, "h_scale": 1.2, "rot": Vector3(8, 45, 10), "dark": true},
		{"pos": Vector2(-24.0, -26.0), "radius": 2.2, "h_scale": 1.4, "rot": Vector3(-15, 110, -5), "dark": false},
		{"pos": Vector2(-14.0, 12.0), "radius": 1.5, "h_scale": 1.0, "rot": Vector3(14, 60, 12), "dark": false},
		{"pos": Vector2(-28.0, 22.0), "radius": 2.0, "h_scale": 1.3, "rot": Vector3(-8, 25, -14), "dark": true},
		{"pos": Vector2(38.0, -18.0), "radius": 3.0, "h_scale": 1.6, "rot": Vector3(16, 130, 10), "dark": true},
		{"pos": Vector2(-38.0, 8.0), "radius": 2.8, "h_scale": 1.5, "rot": Vector3(-12, 95, -8), "dark": false}
	]
	
	for b in large_boulders:
		var p2: Vector2 = b["pos"]
		var surface_y = _calc_height(p2.x, p2.y)
		var r: float = b["radius"]
		
		var b_body = StaticBody3D.new()
		b_body.position = Vector3(p2.x, surface_y + r * 0.45, p2.y)
		b_body.rotation_degrees = b["rot"]
		b_body.collision_layer = 1
		b_body.collision_mask = 2
		add_child(b_body)
		
		var b_mesh_inst = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = r
		s_mesh.height = r * 2.0 * b["h_scale"]
		s_mesh.radial_segments = 8 # Faceted angular boulder appearance
		s_mesh.rings = 5
		s_mesh.material = boulder_mat_dark if b["dark"] else boulder_mat_light
		b_mesh_inst.mesh = s_mesh
		b_body.add_child(b_mesh_inst)
		
		# Uniform convex collision shape to eliminate any non-uniform normal distortion
		var col = CollisionShape3D.new()
		col.shape = s_mesh.create_convex_shape()
		b_body.add_child(col)
	
	# 2. Medium and small scattered ejecta rocks (visual meshes for optimal performance)
	var rock_coords = [
		Vector2(8.0, 6.0), Vector2(10.0, 14.0), Vector2(17.0, 7.0), Vector2(24.0, 9.0),
		Vector2(-7.0, -8.0), Vector2(-15.0, -14.0), Vector2(-18.0, -25.0), Vector2(-26.0, -18.0),
		Vector2(-12.0, 16.0), Vector2(-18.0, 10.0), Vector2(-22.0, 22.0), Vector2(-27.0, 14.0),
		Vector2(28.0, -12.0), Vector2(32.0, -20.0), Vector2(-32.0, 24.0), Vector2(-36.0, 16.0),
		Vector2(3.0, -22.0), Vector2(-4.0, 22.0), Vector2(15.0, -28.0), Vector2(-25.0, -8.0)
	]
	
	for coord in rock_coords:
		var y = _calc_height(coord.x, coord.y)
		var rock_mesh = MeshInstance3D.new()
		var r_mesh = SphereMesh.new()
		var sz = randf_range(0.35, 0.75)
		r_mesh.radius = sz
		r_mesh.height = sz * randf_range(1.2, 1.6)
		r_mesh.radial_segments = 6
		r_mesh.rings = 4
		r_mesh.material = boulder_mat_dark if (randf() > 0.5) else boulder_mat_light
		rock_mesh.mesh = r_mesh
		rock_mesh.position = Vector3(coord.x, y + sz * 0.4, coord.y)
		rock_mesh.rotation_degrees = Vector3(randf_range(-25, 25), randf_range(0, 360), randf_range(-25, 25))
		add_child(rock_mesh)

# Creates authentic astronaut bootprints and rover tire tracks conforming to the undulating terrain
func _create_footprints_and_rover_tracks() -> void:
	var track_mat = StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.30, 0.32, 0.34) # Compacted, shadowed lunar regolith
	track_mat.roughness = 0.99
	
	# Trail 1: Origin (0,0) toward Lunar Roving Vehicle (18, 12)
	_generate_trail(Vector2(0, 0), Vector2(16, 11), 16, track_mat, true)
	
	# Trail 2: Origin (0,0) toward LM Descent Stage (-16, -18)
	_generate_trail(Vector2(0, 0), Vector2(-14, -16), 14, track_mat, false)
	
	# Trail 3: Origin (0,0) toward ALSEP (-20, 15)
	_generate_trail(Vector2(0, 0), Vector2(-18, 13.5), 14, track_mat, false)

func _generate_trail(start_2d: Vector2, end_2d: Vector2, steps: int, mat: Material, is_rover: bool) -> void:
	var step_vec = (end_2d - start_2d) / float(steps)
	var perp = Vector2(-step_vec.y, step_vec.x).normalized()
	
	for i in range(1, steps):
		var pos_2d = start_2d + step_vec * float(i)
		var surface_y = _calc_height(pos_2d.x, pos_2d.y) + 0.015 # Clean slight offset above surface
		var rot_y = atan2(step_vec.x, step_vec.y)
		
		if is_rover and i > 4:
			# Dual parallel rover tracks
			for side in [-0.65, 0.65]:
				var t_pos = pos_2d + perp * side
				var t_y = _calc_height(t_pos.x, t_pos.y) + 0.015
				var track = MeshInstance3D.new()
				var p = PlaneMesh.new()
				p.size = Vector2(0.28, 0.65)
				p.material = mat
				track.mesh = p
				track.position = Vector3(t_pos.x, t_y, t_pos.y)
				track.rotation.y = rot_y
				add_child(track)
		else:
			# Alternating astronaut bootprints
			var side_offset = 0.22 if (i % 2 == 0) else -0.22
			var b_pos = pos_2d + perp * side_offset
			var b_y = _calc_height(b_pos.x, b_pos.y) + 0.015
			var boot = MeshInstance3D.new()
			var p = PlaneMesh.new()
			p.size = Vector2(0.22, 0.38)
			p.material = mat
			boot.mesh = p
			boot.position = Vector3(b_pos.x, b_y, b_pos.y)
			boot.rotation.y = rot_y
			add_child(boot)

# Creates distant mountain massif silhouettes on the horizon (Apollo 15 Apennines & Apollo 17 Taurus-Littrow)
func _create_distant_mountain_massifs() -> void:
	var horizon_mat = StandardMaterial3D.new()
	horizon_mat.albedo_color = Color(0.22, 0.24, 0.26)
	horizon_mat.roughness = 0.98
	
	var angles = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
	var dist = 115.0
	
	for a in angles:
		var rad = deg_to_rad(a)
		var peak = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = randf_range(0.8, 2.5)
		p_mesh.bottom_radius = randf_range(30.0, 45.0)
		p_mesh.height = randf_range(20.0, 32.0)
		p_mesh.radial_segments = 14
		p_mesh.material = horizon_mat
		peak.mesh = p_mesh
		peak.position = Vector3(sin(rad) * dist, 4.0, cos(rad) * dist)
		peak.scale = Vector3(1.2, 0.8, 1.2)
		add_child(peak)

# Creates the iconic Earth in the black lunar sky
func _create_earth_in_sky() -> void:
	var earth_root = Node3D.new()
	earth_root.name = "EarthInSky"
	earth_root.position = Vector3(180, 115, -260)
	add_child(earth_root)
	
	# Earth sphere
	var earth_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 18.0
	sphere.height = 36.0
	sphere.radial_segments = 32
	sphere.rings = 16
	
	var earth_mat = StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.18, 0.45, 0.85) # Vibrant ocean blue
	earth_mat.roughness = 0.35
	earth_mat.emission_enabled = true
	earth_mat.emission = Color(0.12, 0.35, 0.70)
	earth_mat.emission_energy_multiplier = 0.45
	sphere.material = earth_mat
	earth_mesh.mesh = sphere
	earth_mesh.rotation_degrees = Vector3(23.5, -40, 15)
	earth_root.add_child(earth_mesh)
	
	# Thin atmospheric glow halo
	var glow_mesh = MeshInstance3D.new()
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = 18.7
	glow_sphere.height = 37.4
	glow_sphere.radial_segments = 24
	glow_sphere.rings = 12
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.albedo_color = Color(0.5, 0.8, 1.0, 0.20)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.4, 0.75, 1.0)
	glow_mat.emission_energy_multiplier = 0.6
	glow_sphere.material = glow_mat
	glow_mesh.mesh = glow_sphere
	earth_root.add_child(glow_mesh)

# Automatically aligns player and artifacts to the exact generated terrain elevation
func _align_scene_objects_to_surface() -> void:
	call_deferred("_do_align")

func _do_align() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# Align player spawn
	var player = parent_node.get_node_or_null("Player")
	if player:
		var py = _calc_height(player.global_position.x, player.global_position.z)
		player.global_position.y = py + 0.15
	
	# Align artifacts to terrain surface
	for node in parent_node.get_children():
		if node.is_in_group("artifacts"):
			var ay = _calc_height(node.global_position.x, node.global_position.z)
			node.global_position.y = ay
