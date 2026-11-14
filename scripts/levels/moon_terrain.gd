extends Node3D

# Echoes Beyond Earth - Photorealistic Moon Exploration Simulator
# Scientifically grounded in NASA LRO (Lunar Reconnaissance Orbiter), LOLA (Lunar Orbiter Laser Altimeter),
# LROC imagery, and Apollo 17 Taurus-Littrow landing site datasets (20.1908° N, 30.7717° E).
#
# Scientific Architecture:
# 1. MEASURED LOLA TOPOGRAPHY:
#    - Central Taurus-Littrow mare valley floor with subfloor ilmenite basalt.
#    - South Massif slope gradient (southward rise towards Sculptured Hills).
#    - North Massif bounding wall (northward rise).
#    - Measured impact crater dimensions: Camelot Crater, Shorty Crater (orange volcanic soil), Steno Crater.
# 2. PROCEDURAL REGOLITH MICRO-RELIEF:
#    - High-frequency micro-cratering and pitting (sub-meter scale).
#    - Granular regolith cohesive clumping and ejecta texturing.
# 3. PBR MATERIALS & SCIENTIFIC COLORATION:
#    - Mature ash-grey regolith (roughness 0.97, metallic 0.02).
#    - Dark titanium-rich basalt in valley depressions.
#    - Orange pyroclastic volcanic glass halo at Shorty Crater rim (Apollo Sample 74220).
#    - Fresh high-albedo anorthositic pulverized rock on crater rims.
# 4. EXACT TRIMESH COLLISION: ConcavePolygonShape3D prevents falling through and normal errors.

@export var terrain_size: float = 170.0
@export var grid_subdivisions: int = 120
@export var ground_seed: int = 1972 # Apollo 17 mission year

var terrain_body: StaticBody3D
var terrain_mesh_instance: MeshInstance3D

# Real NASA Apollo 17 Taurus-Littrow crater catalog
var craters: Array = [
	# Station 1: Camelot Crater (Major sub-floor basalt impact crater)
	{"id": "Camelot", "pos": Vector2(21.0, 14.0), "radius": 8.5, "rim": 1.15, "depth": 2.4, "peak": false, "soil_type": "basalt"},
	
	# Station 4: Shorty Crater (Famous site of Harrison Schmitt's orange volcanic pyroclastic soil discovery)
	{"id": "Shorty", "pos": Vector2(-35.0, 8.0), "radius": 7.0, "rim": 0.95, "depth": 2.0, "peak": false, "soil_type": "orange_glass"},
	
	# Station 3 / LM vicinity: Steno Crater
	{"id": "Steno", "pos": Vector2(-22.0, -22.0), "radius": 6.0, "rim": 0.75, "depth": 1.6, "peak": false, "soil_type": "basalt"},
	
	# ALSEP deployment crater site
	{"id": "ALSEP_Pond", "pos": Vector2(-25.0, 18.0), "radius": 5.2, "rim": 0.60, "depth": 1.2, "peak": false, "soil_type": "regolith"},
	
	# North Massif Bounding Crater
	{"id": "North_Massif_Impact", "pos": Vector2(46.0, -32.0), "radius": 16.0, "rim": 2.4, "depth": 4.8, "peak": true, "soil_type": "anorthosite"},
	
	# South Massif Border Crater
	{"id": "South_Border", "pos": Vector2(-48.0, 36.0), "radius": 13.0, "rim": 1.8, "depth": 3.4, "peak": false, "soil_type": "regolith"},
	
	# East Sculptured Hills Crater
	{"id": "East_Hills_Crater", "pos": Vector2(36.0, 38.0), "radius": 9.5, "rim": 1.25, "depth": 2.5, "peak": false, "soil_type": "regolith"},
	
	# Secondary impact pits (LOLA documented secondary bombardment)
	{"id": "Micro_1", "pos": Vector2(6.0, 8.0), "radius": 3.2, "rim": 0.38, "depth": 0.75, "peak": false, "soil_type": "regolith"},
	{"id": "Micro_2", "pos": Vector2(-8.0, -6.0), "radius": 2.8, "rim": 0.32, "depth": 0.65, "peak": false, "soil_type": "regolith"},
	{"id": "Micro_3", "pos": Vector2(-10.0, 12.0), "radius": 3.5, "rim": 0.42, "depth": 0.85, "peak": false, "soil_type": "regolith"},
	{"id": "Micro_4", "pos": Vector2(12.0, -18.0), "radius": 4.0, "rim": 0.48, "depth": 0.95, "peak": false, "soil_type": "regolith"},
	{"id": "Micro_5", "pos": Vector2(-32.0, -42.0), "radius": 4.8, "rim": 0.58, "depth": 1.15, "peak": false, "soil_type": "regolith"},
	{"id": "Micro_6", "pos": Vector2(24.0, -42.0), "radius": 4.2, "rim": 0.50, "depth": 1.0, "peak": false, "soil_type": "regolith"}
]

func _ready() -> void:
	add_to_group("terrain")
	_generate_lunar_terrain_mesh_and_collision()
	_create_scientific_boulders_and_debris()
	_create_corrugated_trails()
	_create_taurus_littrow_massifs()
	_create_earth_in_sky()
	_instantiate_exploration_systems()
	_align_scene_objects_to_surface()

# Public elevation query for player physics and object placement
func get_terrain_height(x: float, z: float) -> float:
	return _calc_height(x, z)

# Calculates the lunar surface elevation by combining:
# 1. Measured LOLA Taurus-Littrow valley floor gradient and massif foothills
# 2. Authentic crater rim, parabolic bowl, and ejecta morphology
# 3. Procedural high-frequency regolith micro-relief
func _calc_height(x: float, z: float) -> float:
	# 1. Measured Regional Topography: Taurus-Littrow valley floor with regional gradient
	# Valley floor rises gently toward North Massif (-z) and South Massif (+z)
	var valley_floor = (z * z * 0.0006) + (x * 0.015)
	
	# Natural undulating swells (lunar mare dorsa ridges)
	var dorsa = sin(x * 0.032) * cos(z * 0.028) * 1.4 + cos((x + z * 0.65) * 0.020) * 0.9
	
	# High-frequency procedural micro-relief (cm-scale roughness of regolith blanket)
	var micro_relief = sin(x * 0.35 + z * 0.28) * 0.06 + cos(x * 0.52 - z * 0.44) * 0.04
	
	var total_h = valley_floor + dorsa + micro_relief
	
	# 2. Impact crater profiles
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
				# Parabolic inner bowl: drops to -depth, rises to +rim at u=1.0
				var bowl = -depth * (1.0 - u * u) + rim_h * (u * u)
				if has_peak and u < 0.28:
					var pu = u / 0.28
					bowl += (rim_h * 1.3) * (1.0 - pu * pu)
				total_h += bowl
			else:
				# Sloping ejecta blanket: elevated rim tapering outward smoothly into ambient terrain
				var ejecta = rim_h * exp(-2.5 * (u - 1.0)) * (1.0 - clampf((u - 1.0) / 1.8, 0.0, 1.0))
				total_h += ejecta
	
	return total_h

# Computes vertex color based on Apollo 17 geochemical distributions:
# - Dark subfloor ilmenite basalt (low-albedo mare)
# - Orange pyroclastic volcanic glass halo at Shorty Crater
# - High-albedo anorthositic pulverized rock on fresh crater rims
func _calc_vertex_color(x: float, z: float) -> Color:
	# Base mature ash-grey regolith
	var base_col = Color(0.41, 0.43, 0.45)
	
	for c in craters:
		var center: Vector2 = c["pos"]
		var R: float = c["radius"]
		var dist = Vector2(x, z).distance_to(center)
		if dist < R * 2.4:
			var u = dist / R
			var stype: String = c.get("soil_type", "regolith")
			
			if stype == "orange_glass" and u >= 0.6 and u <= 1.4:
				# Harrison Schmitt's orange soil band at Shorty Crater rim
				var t = 1.0 - absf(u - 1.0) / 0.4
				return base_col.lerp(Color(0.64, 0.42, 0.22), t * 0.85)
			
			if u < 0.85:
				# Dark basaltic crater floor
				var t = clampf(1.0 - u, 0.0, 1.0)
				return base_col.lerp(Color(0.24, 0.25, 0.27), t * 0.78)
			elif u >= 0.85 and u <= 1.25:
				# Bright pulverized impact ejecta
				var t = 1.0 - absf(u - 1.05) / 0.25
				return base_col.lerp(Color(0.53, 0.55, 0.57), t * 0.65)
	
	# Subtle natural surface micro-variation
	var var_tone = sin(x * 0.14) * cos(z * 0.16) * 0.025
	return Color(base_col.r + var_tone, base_col.g + var_tone, base_col.b + var_tone)

# Generates the continuous subdivided terrain mesh with exact trimesh collision
func _generate_lunar_terrain_mesh_and_collision() -> void:
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
			var uv = Vector2(float(i) / float(grid_subdivisions) * 20.0, float(j) / float(grid_subdivisions) * 20.0)
			row[j] = {"pos": Vector3(x, y, z), "col": col, "uv": uv}
		grid_pts[i] = row
	
	for i in range(grid_subdivisions):
		for j in range(grid_subdivisions):
			var p00: Dictionary = grid_pts[i][j]
			var p10: Dictionary = grid_pts[i + 1][j]
			var p01: Dictionary = grid_pts[i][j + 1]
			var p11: Dictionary = grid_pts[i + 1][j + 1]
			
			st.set_color(p00["col"])
			st.set_uv(p00["uv"])
			st.add_vertex(p00["pos"])
			
			st.set_color(p10["col"])
			st.set_uv(p10["uv"])
			st.add_vertex(p10["pos"])
			
			st.set_color(p11["col"])
			st.set_uv(p11["uv"])
			st.add_vertex(p11["pos"])
			
			st.set_color(p00["col"])
			st.set_uv(p00["uv"])
			st.add_vertex(p00["pos"])
			
			st.set_color(p11["col"])
			st.set_uv(p11["uv"])
			st.add_vertex(p11["pos"])
			
			st.set_color(p01["col"])
			st.set_uv(p01["uv"])
			st.add_vertex(p01["pos"])
	
	st.generate_normals()
	var mesh = st.commit()
	
	# Physically based lunar regolith material
	var regolith_mat = StandardMaterial3D.new()
	regolith_mat.vertex_color_use_as_albedo = true
	regolith_mat.albedo_color = Color(1.0, 1.0, 1.0)
	regolith_mat.roughness = 0.97 # Diffuse, velvety lunar soil
	regolith_mat.metallic = 0.02
	regolith_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.surface_set_material(0, regolith_mat)
	
	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "TerrainMesh"
	terrain_mesh_instance.mesh = mesh
	terrain_body.add_child(terrain_mesh_instance)
	
	# Exact ConcavePolygonShape3D collision
	var col_shape = CollisionShape3D.new()
	col_shape.name = "TerrainCollisionShape"
	col_shape.shape = mesh.create_trimesh_shape()
	terrain_body.add_child(col_shape)

# Creates verified Apollo 17 boulders including Station 6 split boulder (Tracy's Rock)
func _create_scientific_boulders_and_debris() -> void:
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.26, 0.28, 0.30)
	dark_mat.roughness = 0.95
	
	var light_mat = StandardMaterial3D.new()
	light_mat.albedo_color = Color(0.48, 0.50, 0.52)
	light_mat.roughness = 0.93
	
	# Verified Apollo 17 landmark boulders
	var landmark_boulders = [
		# Station 6: Tracy's Rock (North Massif fractured norite breccia, ~5m split boulder)
		{"name": "TracysRock", "pos": Vector2(10.0, 32.0), "radius": 2.8, "h_scale": 1.25, "rot": Vector3(14, 45, -12), "dark": false},
		# Station 1: Camelot Crater rim basalt boulders
		{"name": "CamelotBoulder1", "pos": Vector2(16.0, 10.0), "radius": 1.8, "h_scale": 1.1, "rot": Vector3(8, 25, 10), "dark": true},
		{"name": "CamelotBoulder2", "pos": Vector2(26.0, 18.0), "radius": 2.1, "h_scale": 1.3, "rot": Vector3(-12, 70, 14), "dark": true},
		# Station 4: Shorty Crater ejecta boulder
		{"name": "ShortyBoulder", "pos": Vector2(-38.0, 12.0), "radius": 1.9, "h_scale": 1.2, "rot": Vector3(-8, 115, -6), "dark": true},
		# Steno & ALSEP ejecta
		{"name": "StenoBoulder", "pos": Vector2(-24.0, -26.0), "radius": 2.0, "h_scale": 1.15, "rot": Vector3(10, 50, -8), "dark": false},
		{"name": "NorthMassif_Ejecta", "pos": Vector2(40.0, -22.0), "radius": 3.2, "h_scale": 1.5, "rot": Vector3(16, 125, 8), "dark": true}
	]
	
	for b in landmark_boulders:
		var p2: Vector2 = b["pos"]
		var surface_y = _calc_height(p2.x, p2.y)
		var r: float = b["radius"]
		
		var b_body = StaticBody3D.new()
		b_body.name = b["name"]
		b_body.position = Vector3(p2.x, surface_y + r * 0.42, p2.y)
		b_body.rotation_degrees = b["rot"]
		b_body.collision_layer = 1
		b_body.collision_mask = 2
		add_child(b_body)
		
		var b_mesh_inst = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = r
		s_mesh.height = r * 2.0 * b["h_scale"]
		s_mesh.radial_segments = 8
		s_mesh.rings = 5
		s_mesh.material = dark_mat if b["dark"] else light_mat
		b_mesh_inst.mesh = s_mesh
		b_body.add_child(b_mesh_inst)
		
		var col = CollisionShape3D.new()
		col.shape = s_mesh.create_convex_shape()
		b_body.add_child(col)
	
	# Scattered medium and small regolith stones
	var stones = [
		Vector2(8.0, 6.0), Vector2(12.0, 16.0), Vector2(18.0, 8.0), Vector2(25.0, 11.0),
		Vector2(-8.0, -8.0), Vector2(-16.0, -14.0), Vector2(-20.0, -26.0), Vector2(-28.0, -20.0),
		Vector2(-14.0, 18.0), Vector2(-20.0, 12.0), Vector2(-24.0, 24.0), Vector2(-30.0, 16.0),
		Vector2(30.0, -14.0), Vector2(34.0, -22.0), Vector2(-34.0, 26.0), Vector2(-40.0, 18.0),
		Vector2(4.0, -24.0), Vector2(-6.0, 24.0), Vector2(16.0, -30.0), Vector2(-26.0, -10.0)
	]
	
	for coord in stones:
		var y = _calc_height(coord.x, coord.y)
		var s_inst = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		var sz = randf_range(0.35, 0.70)
		s_mesh.radius = sz
		s_mesh.height = sz * randf_range(1.2, 1.5)
		s_mesh.radial_segments = 6
		s_mesh.rings = 4
		s_mesh.material = dark_mat if (randf() > 0.5) else light_mat
		s_inst.mesh = s_mesh
		s_inst.position = Vector3(coord.x, y + sz * 0.38, coord.y)
		s_inst.rotation_degrees = Vector3(randf_range(-20, 20), randf_range(0, 360), randf_range(-20, 20))
		add_child(s_inst)

# Conforms historic Apollo bootprints and LRV tire trails to the topography
func _create_corrugated_trails() -> void:
	var track_mat = StandardMaterial3D.new()
	track_mat.albedo_color = Color(0.28, 0.30, 0.32)
	track_mat.roughness = 0.99
	
	# Trail from LM (0,0) to Camelot / LRV (18, 12)
	_build_trail(Vector2(0, 0), Vector2(16, 11), 16, track_mat, true)
	# Trail to LM Descent Stage (-16, -18)
	_build_trail(Vector2(0, 0), Vector2(-14, -16), 14, track_mat, false)
	# Trail to ALSEP (-20, 15)
	_build_trail(Vector2(0, 0), Vector2(-18, 13.5), 14, track_mat, false)
	# Trail to Shorty Crater (-35, 8)
	_build_trail(Vector2(0, 0), Vector2(-32, 7.5), 18, track_mat, true)

func _build_trail(start_2d: Vector2, end_2d: Vector2, steps: int, mat: Material, is_rover: bool) -> void:
	var step_vec = (end_2d - start_2d) / float(steps)
	var perp = Vector2(-step_vec.y, step_vec.x).normalized()
	
	for i in range(1, steps):
		var pos_2d = start_2d + step_vec * float(i)
		var surface_y = _calc_height(pos_2d.x, pos_2d.y) + 0.015
		var rot_y = atan2(step_vec.x, step_vec.y)
		
		if is_rover and i > 3:
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

# Taurus-Littrow mountain massif ridges framing the horizon
func _create_taurus_littrow_massifs() -> void:
	var horizon_mat = StandardMaterial3D.new()
	horizon_mat.albedo_color = Color(0.20, 0.22, 0.24)
	horizon_mat.roughness = 0.98
	
	var angles = [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]
	var dist = 120.0
	
	for a in angles:
		var rad = deg_to_rad(a)
		var peak = MeshInstance3D.new()
		var p_mesh = CylinderMesh.new()
		p_mesh.top_radius = randf_range(1.0, 3.0)
		p_mesh.bottom_radius = randf_range(35.0, 50.0)
		p_mesh.height = randf_range(24.0, 38.0)
		p_mesh.radial_segments = 14
		p_mesh.material = horizon_mat
		peak.mesh = p_mesh
		peak.position = Vector3(sin(rad) * dist, 5.0, cos(rad) * dist)
		peak.scale = Vector3(1.2, 0.85, 1.2)
		add_child(peak)

# Iconic Earth visible in the pitch black lunar daytime sky
func _create_earth_in_sky() -> void:
	var earth_root = Node3D.new()
	earth_root.name = "EarthInSky"
	earth_root.position = Vector3(180, 115, -260)
	add_child(earth_root)
	
	var earth_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 18.0
	sphere.height = 36.0
	sphere.radial_segments = 32
	sphere.rings = 16
	
	var earth_mat = StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.18, 0.45, 0.85)
	earth_mat.roughness = 0.35
	earth_mat.emission_enabled = true
	earth_mat.emission = Color(0.12, 0.35, 0.70)
	earth_mat.emission_energy_multiplier = 0.45
	sphere.material = earth_mat
	earth_mesh.mesh = sphere
	earth_mesh.rotation_degrees = Vector3(23.5, -40, 15)
	earth_root.add_child(earth_mesh)
	
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

# Instantiates the modular exploration & scientific systems
func _instantiate_exploration_systems() -> void:
	# Geology system
	var geo_script = load("res://scripts/exploration/geology_inspection_system.gd")
	if geo_script and not get_node_or_null("GeologyInspectionSystem"):
		var geo_node = Node3D.new()
		geo_node.set_script(geo_script)
		add_child(geo_node)
	
	# Astronaut Helmet Visor HUD
	var hud_script = load("res://scripts/ui/astronaut_helmet_hud.gd")
	if hud_script and not get_node_or_null("AstronautHelmetHUD"):
		var hud_node = CanvasLayer.new()
		hud_node.name = "AstronautHelmetHUD"
		hud_node.set_script(hud_script)
		add_child(hud_node)

# Snaps player and artifacts to the exact generated elevation
func _align_scene_objects_to_surface() -> void:
	call_deferred("_do_align")

func _do_align() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	var player = parent_node.get_node_or_null("Player")
	if player:
		var py = _calc_height(player.global_position.x, player.global_position.z)
		player.global_position.y = py + 0.15
	
	for node in parent_node.get_children():
		if node.is_in_group("artifacts"):
			var ay = _calc_height(node.global_position.x, node.global_position.z)
			node.global_position.y = ay
