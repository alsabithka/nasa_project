extends Node3D

# Echoes Beyond Earth - Scientifically Realistic Mars Jezero Crater Surface & Environment
# Grounded in NASA Mars 2020 Perseverance Mastcam-Z, SuperCam, and Curiosity Mastcam photography.
#
# Scientific Architecture:
# 1. REALISTIC MARTIAN GEOMORPHOLOGY:
#    - Vast uneven rocky plain with gentle elevation swells and distant low crater rim hills.
#    - Delta front layered sedimentary escarpment stepping into ancient lakebed floor.
#    - Meandering Neretva Vallis ancient inflow channel with rounded fluvial gravels.
#    - South Séítah depression with dark barchan sand dunes and wind ripples.
#    - Belva impact crater with raised rim, excavated interior, and outward ejecta blanket.
#    - Kodiak remnant butte / delta mesa outpost.
# 2. SIX SCIENTIFIC SURFACE MATERIALS & GRADUAL BLENDING:
#    - Fine oxidized ferric regolith (reddish-orange powder in hollows).
#    - Coarse regolith & angular gravel.
#    - Dense exposed bedrock visible through loose dust.
#    - Layered sedimentary slabs (tan/ochre laminated siltstone/mudstone).
#    - Dark wind-sculpted basaltic sand deposits in dune troughs.
#    - Pale sulfate duricrust evaporite hardpan.
# 3. REALISTIC ROCK DISTRIBUTION & CLUSTERING:
#    - Multi-tiered flat sedimentary rock slabs with broken edges, fractures, and dust draping.
#    - Large isolated boulders (Belva basalt, Séítah olivine cumulates).
#    - Medium-sized fractured blocks and polished eolian ventifacts.
#    - Scree fields: naturally clustered small stones and pebbles around larger formations with open sand spaces.
# 4. WIND, SAND & DUST:
#    - Small sand ripples, dust accumulation in leeward rock shadows.
#    - Active suspended atmospheric dust and rotating convective dust devils.
# 5. SKY, LIGHTING & CELESTIAL BODIES:
#    - Pale peach, dusty pink and warm butterscotch daytime sky with horizon depth haze.
#    - Irregular potato-shaped Phobos with Stickney crater & distant Deimos.
# 6. EXACT TRIMESH COLLISION: ConcavePolygonShape3D across continuous subdivided mesh.

@export var terrain_size: float = 185.0
@export var grid_subdivisions: int = 130
@export var ground_seed: int = 2021 # Mars 2020 Perseverance landing year

var terrain_body: StaticBody3D
var terrain_mesh_instance: MeshInstance3D

# Real NASA Jezero Crater feature catalog
var craters: Array = [
	# Belva Crater: Major delta-penetrating impact crater exposing deep layered strata
	{"id": "Belva", "pos": Vector2(-32.0, -28.0), "radius": 11.5, "rim": 1.45, "depth": 3.2, "peak": false, "soil_type": "basalt"},
	# Dourbes impact pit
	{"id": "Dourbes", "pos": Vector2(24.0, 18.0), "radius": 6.5, "rim": 0.85, "depth": 1.8, "peak": false, "soil_type": "sediment"},
	# Séítah boundary crater
	{"id": "Seitah_Pit", "pos": Vector2(-15.0, 36.0), "radius": 7.8, "rim": 0.95, "depth": 2.1, "peak": false, "soil_type": "basalt"},
	# Neretva channel scour depression
	{"id": "Channel_Scour", "pos": Vector2(38.0, -35.0), "radius": 8.5, "rim": 0.70, "depth": 1.9, "peak": false, "soil_type": "clay"},
	# Secondary impact craterlets
	{"id": "Micro_1", "pos": Vector2(8.0, 8.0), "radius": 3.4, "rim": 0.42, "depth": 0.85, "peak": false, "soil_type": "duricrust"},
	{"id": "Micro_2", "pos": Vector2(-12.0, -8.0), "radius": 2.9, "rim": 0.35, "depth": 0.70, "peak": false, "soil_type": "duricrust"},
	{"id": "Micro_3", "pos": Vector2(16.0, -18.0), "radius": 3.8, "rim": 0.45, "depth": 0.95, "peak": false, "soil_type": "duricrust"},
	{"id": "Micro_4", "pos": Vector2(-38.0, 14.0), "radius": 4.5, "rim": 0.55, "depth": 1.15, "peak": false, "soil_type": "duricrust"}
]

func _ready() -> void:
	add_to_group("terrain")
	_generate_mars_terrain_mesh_and_collision()
	_create_jezero_boulders_and_ventifacts()
	_create_flat_layered_bedrock_formations()
	_create_rock_clusters_and_scree_fields()
	_create_kodiak_remnant_butte()
	_create_phobos_and_deimos()
	_instantiate_atmosphere_and_hud()
	_align_scene_objects_to_surface()

# Public elevation query
func get_terrain_height(x: float, z: float) -> float:
	return _calc_height(x, z)

# Calculates Martian surface elevation at any point (x, z)
func _calc_height(x: float, z: float) -> float:
	# 1. Delta Front Topography: Jezero river delta scarp stepping up towards northwest (-x, -z)
	var delta_gradient = (-x * 0.038 - z * 0.024)
	# Delta terraced escarpment (sedimentary benches)
	var delta_terrace = sin(x * 0.045 - z * 0.035) * 1.6 + cos(x * 0.025 + z * 0.040) * 1.2
	
	# 2. Neretva Vallis ancient inflow channel: Meandering trough along east (+x)
	var channel_axis = x - 32.0 - sin(z * 0.05) * 6.0
	var channel_dist = abs(channel_axis)
	var channel_cut = 0.0
	if channel_dist < 14.0:
		var cf = cos((channel_dist / 14.0) * (PI * 0.5))
		channel_cut = -cf * 2.2

	# 3. Séítah Formation depression and undulating transverse sand dunes
	var seitah_depression = 0.0
	var seitah_center = Vector2(-20.0, 28.0)
	var s_dist = Vector2(x, z).distance_to(seitah_center)
	if s_dist < 35.0:
		var sf = cos((s_dist / 35.0) * (PI * 0.5))
		seitah_depression = -sf * 1.8
		# Dark sand dunes with sharp slip faces
		var dune_wave = sin(x * 0.18 + z * 0.12) * 0.85 + cos(x * 0.32 - z * 0.10) * 0.35
		seitah_depression += dune_wave * sf

	# 4. Regional gentle undulating plain swells & distant low hills
	var regional_swell = sin(x * 0.018 + z * 0.015) * 1.8 + cos(x * 0.012 - z * 0.022) * 1.4

	# 5. Wind ripple micro-relief (centimeter-scale eolian ripples in dust)
	var ripple = sin(x * 0.55 + z * 0.42) * 0.07 + cos(x * 0.85 - z * 0.65) * 0.04

	var total_h = delta_gradient + delta_terrace + channel_cut + seitah_depression + regional_swell + ripple

	# 6. Impact craters
	for c in craters:
		var center: Vector2 = c["pos"]
		var R: float = c["radius"]
		var rim_h: float = c["rim"]
		var depth: float = c["depth"]
		var d = Vector2(x, z).distance_to(center)
		
		if d < R:
			var norm_d = d / R
			var bowl = -depth * (1.0 - norm_d * norm_d)
			var rim = rim_h * pow(norm_d, 3.5)
			total_h += bowl + rim
		elif d < R * 2.4:
			var ejecta_norm = (d - R) / (R * 1.4)
			var ejecta_h = rim_h * exp(-ejecta_norm * 2.8)
			total_h += ejecta_h

	return total_h

# Realistic PBR Martian surface vertex coloration with 6 blended materials
func _calc_vertex_color(x: float, z: float) -> Color:
	# Material 1: Fine oxidized ferric regolith (reddish-orange & brown powder)
	var mat1_fine_regolith = Color(0.72, 0.33, 0.18)
	# Material 2: Coarse regolith & angular gravel
	var mat2_coarse_gravel = Color(0.58, 0.38, 0.26)
	# Material 3: Exposed bedrock visible through loose dust
	var mat3_bedrock = Color(0.38, 0.30, 0.25)
	# Material 4: Layered sedimentary mudstone / siltstone slabs
	var mat4_layered_rock = Color(0.66, 0.54, 0.42)
	# Material 5: Dark basaltic / olivine-rich sand deposits in dune troughs
	var mat5_dark_sand = Color(0.24, 0.22, 0.20)
	# Material 6: Pale sulfate / duricrust evaporite hardpan
	var mat6_duricrust = Color(0.76, 0.64, 0.52)

	var base_col = mat1_fine_regolith

	# Séítah region has dark basaltic sand dunes with wind ripple color bands
	var seitah_center = Vector2(-20.0, 28.0)
	var s_dist = Vector2(x, z).distance_to(seitah_center)
	if s_dist < 32.0:
		var weight = clampf(1.0 - (s_dist / 32.0), 0.0, 1.0)
		# Troughs between dunes accumulate darker mafic sand grains
		var dune_phase = sin(x * 0.18 + z * 0.12)
		var mafic_blend = mat5_dark_sand if dune_phase < 0.0 else mat2_coarse_gravel
		base_col = base_col.lerp(mafic_blend, weight * 0.85)

	# Delta front terraces expose light sedimentary layers & fractured bedrock
	if x < -6.0 and z < 8.0:
		var terrace_band = sin(x * 0.15 + z * 0.10)
		if terrace_band > 0.15:
			base_col = base_col.lerp(mat4_layered_rock, 0.70)
		elif terrace_band < -0.25:
			base_col = base_col.lerp(mat3_bedrock, 0.55)
		else:
			base_col = base_col.lerp(mat6_duricrust, 0.45)

	# Neretva Vallis ancient river channel: coarse gravel and rounded river sediments
	var channel_dist = abs(x - 32.0 - sin(z * 0.05) * 6.0)
	if channel_dist < 12.0:
		var cw = clampf(1.0 - (channel_dist / 12.0), 0.0, 1.0)
		var stream_blend = mat4_layered_rock.lerp(mat2_coarse_gravel, 0.5)
		base_col = base_col.lerp(stream_blend, cw * 0.70)

	# Impact craters expose basaltic ejecta or bright crushed breccia
	for c in craters:
		var d = Vector2(x, z).distance_to(c["pos"])
		var R: float = c["radius"]
		if d < R * 1.5:
			var cw = clampf(1.0 - (d / (R * 1.5)), 0.0, 1.0)
			if c["soil_type"] == "basalt":
				base_col = base_col.lerp(mat5_dark_sand, cw * 0.75)
			elif c["soil_type"] == "clay":
				base_col = base_col.lerp(mat4_layered_rock, cw * 0.75)
			else:
				base_col = base_col.lerp(mat6_duricrust, cw * 0.60)

	# Gradual natural noise variation: subtle gravel speckles and dust mantling
	var fine_noise = sin(x * 0.35 + z * 0.28) * 0.04 + cos(x * 0.52 - z * 0.44) * 0.03
	var macro_noise = sin(x * 0.08 - z * 0.06) * 0.03
	var total_noise = fine_noise + macro_noise

	return Color(
		clampf(base_col.r + total_noise, 0.12, 0.95),
		clampf(base_col.g + total_noise * 0.82, 0.10, 0.95),
		clampf(base_col.b + total_noise * 0.65, 0.08, 0.95)
	)

# Builds the continuous terrain mesh and exact trimesh collision
func _generate_mars_terrain_mesh_and_collision() -> void:
	terrain_body = StaticBody3D.new()
	terrain_body.name = "MarsTerrainBody"
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
			var uv = Vector2(float(i) / float(grid_subdivisions) * 24.0, float(j) / float(grid_subdivisions) * 24.0)
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

	# Physically based velvety Martian regolith material
	var mars_mat = StandardMaterial3D.new()
	mars_mat.vertex_color_use_as_albedo = true
	mars_mat.albedo_color = Color(1.0, 1.0, 1.0)
	mars_mat.roughness = 0.95
	mars_mat.metallic = 0.03
	mars_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.surface_set_material(0, mars_mat)

	terrain_mesh_instance = MeshInstance3D.new()
	terrain_mesh_instance.name = "TerrainMesh"
	terrain_mesh_instance.mesh = mesh
	terrain_body.add_child(terrain_mesh_instance)

	var col_shape = CollisionShape3D.new()
	col_shape.name = "TerrainCollisionShape"
	col_shape.shape = mesh.create_trimesh_shape()
	terrain_body.add_child(col_shape)

# Creates prominent landmark boulders, wind-sculpted ventifacts, and river conglomerates
func _create_jezero_boulders_and_ventifacts() -> void:
	var mat_basalt = StandardMaterial3D.new()
	mat_basalt.albedo_color = Color(0.24, 0.22, 0.21)
	mat_basalt.roughness = 0.92

	var mat_sediment = StandardMaterial3D.new()
	mat_sediment.albedo_color = Color(0.62, 0.52, 0.40)
	mat_sediment.roughness = 0.95

	var mat_ventifact = StandardMaterial3D.new()
	mat_ventifact.albedo_color = Color(0.48, 0.32, 0.24)
	mat_ventifact.roughness = 0.78 # Polished wind-varnish sheen

	var boulder_catalog = [
		# Belva rim impact boulder (fractured basalt)
		{"name": "BelvaBoulder1", "pos": Vector2(-25.0, -22.0), "radius": 2.4, "h": 2.1, "mat": mat_basalt},
		{"name": "BelvaBoulder2", "pos": Vector2(-36.0, -20.0), "radius": 1.8, "h": 1.6, "mat": mat_basalt},
		# Delta front layered sedimentary boulder
		{"name": "DeltaBenchRock", "pos": Vector2(-16.0, -12.0), "radius": 2.6, "h": 1.4, "mat": mat_sediment},
		# Séítah olivine outcrop boulders
		{"name": "SeitahBlock1", "pos": Vector2(-14.0, 22.0), "radius": 2.0, "h": 1.7, "mat": mat_basalt},
		{"name": "SeitahBlock2", "pos": Vector2(-24.0, 32.0), "radius": 2.2, "h": 1.9, "mat": mat_basalt},
		# Neretva Vallis rounded conglomerate boulder
		{"name": "NeretvaConglomerate", "pos": Vector2(28.0, -18.0), "radius": 1.9, "h": 1.5, "mat": mat_sediment},
		# Fluted eolian ventifacts (wind-abraded faceted rocks)
		{"name": "Ventifact1", "pos": Vector2(12.0, 14.0), "radius": 1.4, "h": 1.2, "mat": mat_ventifact},
		{"name": "Ventifact2", "pos": Vector2(6.0, -10.0), "radius": 1.2, "h": 1.0, "mat": mat_ventifact},
		{"name": "Ventifact3", "pos": Vector2(-6.0, 16.0), "radius": 1.5, "h": 1.1, "mat": mat_ventifact}
	]

	for b_info in boulder_catalog:
		var pos2 = b_info["pos"]
		var y = _calc_height(pos2.x, pos2.y)
		var b_body = StaticBody3D.new()
		b_body.name = b_info["name"]
		b_body.position = Vector3(pos2.x, y + (b_info["h"] * 0.45), pos2.y)
		b_body.collision_layer = 1
		b_body.collision_mask = 2

		var b_mesh_inst = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radial_segments = 8
		cyl.top_radius = b_info["radius"] * 0.75
		cyl.bottom_radius = b_info["radius"]
		cyl.height = b_info["h"]
		cyl.material = b_info["mat"]
		b_mesh_inst.mesh = cyl
		b_mesh_inst.rotation_degrees = Vector3(randf_range(-15, 15), randf_range(0, 360), randf_range(-15, 15))
		b_body.add_child(b_mesh_inst)

		var c_shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(b_info["radius"] * 1.8, b_info["h"], b_info["radius"] * 1.8)
		c_shape.shape = box
		b_body.add_child(c_shape)

		add_child(b_body)

# Creates flat, plate-shaped layered sedimentary bedrock formations inspired by Mars rover photos
func _create_flat_layered_bedrock_formations() -> void:
	var mat_slab_sediment = StandardMaterial3D.new()
	mat_slab_sediment.albedo_color = Color(0.65, 0.53, 0.41) # Tan/ochre sedimentary strata
	mat_slab_sediment.roughness = 0.94

	var mat_slab_edge = StandardMaterial3D.new()
	mat_slab_edge.albedo_color = Color(0.48, 0.38, 0.30) # Darker fractured edge
	mat_slab_edge.roughness = 0.90

	var slab_formations = [
		# Delta front exposed tabulate bedrock pavement
		{"name": "DeltaSlabFormation_A", "pos": Vector2(-20.0, -8.0), "w": 5.5, "l": 4.2, "t": 0.35, "tilt": Vector3(4, 25, -3)},
		{"name": "DeltaSlabFormation_B", "pos": Vector2(-22.5, -6.5), "w": 4.8, "l": 3.6, "t": 0.28, "tilt": Vector3(6, 20, -5)},
		# Stepped sedimentary outcropping (Pahrump Hills style)
		{"name": "SteppedStrata_1", "pos": Vector2(-10.0, -20.0), "w": 6.2, "l": 3.8, "t": 0.42, "tilt": Vector3(-5, 45, 8)},
		{"name": "SteppedStrata_2", "pos": Vector2(-8.2, -18.4), "w": 5.0, "l": 3.2, "t": 0.32, "tilt": Vector3(-4, 42, 6)},
		# Neretva outflow flat pavement slab
		{"name": "NeretvaPavement", "pos": Vector2(22.0, -26.0), "w": 5.8, "l": 4.5, "t": 0.30, "tilt": Vector3(2, -15, 4)},
		# Central plain partially buried slab
		{"name": "PlainsBuriedSlab", "pos": Vector2(2.0, 18.0), "w": 4.4, "l": 3.5, "t": 0.25, "tilt": Vector3(-2, 10, -4)}
	]

	for slab in slab_formations:
		var pos2 = slab["pos"]
		var y = _calc_height(pos2.x, pos2.y)
		var slab_body = StaticBody3D.new()
		slab_body.name = slab["name"]
		slab_body.position = Vector3(pos2.x, y + slab["t"] * 0.4, pos2.y)
		slab_body.rotation_degrees = slab["tilt"]
		slab_body.collision_layer = 1
		slab_body.collision_mask = 2

		# Main tabulate slab
		var slab_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(slab["w"], slab["t"], slab["l"])
		box.material = mat_slab_sediment
		slab_mesh.mesh = box
		slab_body.add_child(slab_mesh)

		# Stepped edge lamination
		var step_edge = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(slab["w"] * 0.92, slab["t"] * 0.6, slab["l"] * 0.88)
		s_box.material = mat_slab_edge
		step_edge.mesh = s_box
		step_edge.position = Vector3(slab["w"] * 0.05, slab["t"] * 0.35, slab["l"] * 0.05)
		slab_body.add_child(step_edge)

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = Vector3(slab["w"], slab["t"] * 1.5, slab["l"])
		col.shape = col_box
		slab_body.add_child(col)

		add_child(slab_body)

# Creates realistic non-uniform rock clusters, scree fields, and partially buried stones
func _create_rock_clusters_and_scree_fields() -> void:
	var mat_angular_stone = StandardMaterial3D.new()
	mat_angular_stone.albedo_color = Color(0.42, 0.30, 0.24)
	mat_angular_stone.roughness = 0.92

	var mat_weathered_stone = StandardMaterial3D.new()
	mat_weathered_stone.albedo_color = Color(0.56, 0.40, 0.30)
	mat_weathered_stone.roughness = 0.96

	var mat_dark_basalt_clast = StandardMaterial3D.new()
	mat_dark_basalt_clast.albedo_color = Color(0.26, 0.24, 0.22)
	mat_dark_basalt_clast.roughness = 0.88

	# Distinct cluster centers representing real geological rock fields
	var cluster_centers = [
		{"origin": Vector2(-24.0, -20.0), "radius": 7.0, "count": 14, "mat": mat_dark_basalt_clast, "type": "Belva Ejecta Field"},
		{"origin": Vector2(-15.0, -10.0), "radius": 6.5, "count": 12, "mat": mat_weathered_stone, "type": "Delta Scree Field"},
		{"origin": Vector2(10.0, 12.0), "radius": 6.0, "count": 10, "mat": mat_angular_stone, "type": "Ventifact Cluster"},
		{"origin": Vector2(26.0, -16.0), "radius": 7.5, "count": 12, "mat": mat_weathered_stone, "type": "Neretva Fluvial Cobbles"},
		{"origin": Vector2(-12.0, 24.0), "radius": 6.0, "count": 10, "mat": mat_dark_basalt_clast, "type": "Séítah Basalt Scree"}
	]

	var seed_counter = 101
	for cluster in cluster_centers:
		var c_pos: Vector2 = cluster["origin"]
		var c_rad: float = cluster["radius"]
		var count: int = cluster["count"]
		var c_mat: StandardMaterial3D = cluster["mat"]

		for i in range(count):
			seed_counter += 7
			var angle = float(seed_counter * 13 % 360) * (PI / 180.0)
			var dist = float(seed_counter * 17 % int(c_rad * 100)) / 100.0
			var rx = c_pos.x + cos(angle) * dist
			var rz = c_pos.y + sin(angle) * dist

			var ry = _calc_height(rx, rz)
			var stone_size = lerp(0.25, 0.75, float(seed_counter % 10) / 10.0)

			var stone_body = StaticBody3D.new()
			stone_body.name = "Stone_%d_%d" % [int(c_pos.x), i]
			# Partially embedded in the loose regolith
			stone_body.position = Vector3(rx, ry + stone_size * 0.35, rz)
			stone_body.rotation_degrees = Vector3(
				float(seed_counter * 23 % 40) - 20.0,
				float(seed_counter * 31 % 360),
				float(seed_counter * 19 % 40) - 20.0
			)
			stone_body.collision_layer = 1
			stone_body.collision_mask = 2

			var stone_mesh = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.radial_segments = 6
			cyl.top_radius = stone_size * 0.7
			cyl.bottom_radius = stone_size
			cyl.height = stone_size * 0.85
			cyl.material = c_mat
			stone_mesh.mesh = cyl
			stone_body.add_child(stone_mesh)

			var col = CollisionShape3D.new()
			var box = BoxShape3D.new()
			box.size = Vector3(stone_size * 1.5, stone_size * 0.85, stone_size * 1.5)
			col.shape = box
			stone_body.add_child(col)

			add_child(stone_body)

# Kodiak Remnant Butte: Iconic delta mesa outpost left standing by billions of years of erosion
func _create_kodiak_remnant_butte() -> void:
	var butte = StaticBody3D.new()
	butte.name = "KodiakButte"
	butte.position = Vector3(45.0, 0.0, 42.0)
	butte.position.y = _calc_height(45.0, 42.0) + 4.5
	butte.collision_layer = 1
	butte.collision_mask = 2

	var butte_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radial_segments = 14
	cyl.top_radius = 8.0
	cyl.bottom_radius = 12.0
	cyl.height = 9.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.66, 0.48, 0.36) # Tan deltaic sandstone
	mat.roughness = 0.94
	cyl.material = mat
	butte_mesh.mesh = cyl
	butte.add_child(butte_mesh)

	var col = CollisionShape3D.new()
	var col_cyl = CylinderShape3D.new()
	col_cyl.radius = 11.0
	col_cyl.height = 9.0
	col.shape = col_cyl
	butte.add_child(col)

	add_child(butte)

# Phobos and Deimos celestial mesh instances in the sky dome
func _create_phobos_and_deimos() -> void:
	# 1. Phobos: Closer (~6000 km orbit), irregular potato shape, Stickney crater landmark
	var phobos_root = Node3D.new()
	phobos_root.name = "PhobosInSky"
	phobos_root.position = Vector3(140.0, 110.0, -180.0)
	add_child(phobos_root)

	var phobos_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 7.5
	sphere.height = 13.0
	sphere.radial_segments = 16
	sphere.rings = 8

	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.35, 0.34, 0.33) # Dark carbonaceous chondrite grey
	p_mat.roughness = 0.96
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	sphere.material = p_mat
	phobos_mesh.mesh = sphere
	phobos_mesh.scale = Vector3(1.4, 0.9, 1.1) # Irregular triaxial ellipsoid
	phobos_mesh.rotation_degrees = Vector3(25, 45, 15)
	phobos_root.add_child(phobos_mesh)

	# Stickney Crater landmark depression on Phobos
	var stickney = MeshInstance3D.new()
	var s_sphere = SphereMesh.new()
	s_sphere.radius = 2.8
	s_sphere.height = 1.6
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.24, 0.23, 0.22)
	s_sphere.material = s_mat
	stickney.mesh = s_sphere
	stickney.position = Vector3(4.2, 1.0, 1.5)
	stickney.scale = Vector3(1.1, 0.4, 1.1)
	phobos_root.add_child(stickney)

	# 2. Deimos: Smaller (~6 km), distant, irregular asteroid-like point
	var deimos_root = Node3D.new()
	deimos_root.name = "DeimosInSky"
	deimos_root.position = Vector3(-190.0, 145.0, 120.0)
	add_child(deimos_root)

	var deimos_mesh = MeshInstance3D.new()
	var d_sphere = SphereMesh.new()
	d_sphere.radius = 2.4
	d_sphere.height = 3.6
	d_sphere.radial_segments = 8
	d_sphere.rings = 4
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.40, 0.39, 0.38)
	d_mat.roughness = 0.95
	d_sphere.material = d_mat
	deimos_mesh.mesh = d_sphere
	deimos_mesh.scale = Vector3(1.2, 0.8, 1.0)
	deimos_root.add_child(deimos_mesh)

# Instantiates the modular exploration & scientific systems
func _instantiate_atmosphere_and_hud() -> void:
	# Mars Atmosphere System (Wind, suspended dust, dust devils)
	var atmo_script = load("res://scripts/environment/mars_atmosphere_system.gd")
	if atmo_script and not get_node_or_null("MarsAtmosphereSystem"):
		var atmo_node = Node3D.new()
		atmo_node.set_script(atmo_script)
		add_child(atmo_node)

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
		player.global_position.y = py + 0.20

	for node in parent_node.get_children():
		if node.is_in_group("artifacts"):
			var ay = _calc_height(node.global_position.x, node.global_position.z)
			node.global_position.y = ay
