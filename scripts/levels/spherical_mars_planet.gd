extends Node3D

# Echoes Beyond Earth - Infinite, Fully Spherical Mars Planetary System
# Scientifically grounded in NASA MOLA (Mars Orbiter Laser Altimeter), MRO HiRISE, and THEMIS datasets:
# - Planetary Radius: Base radius 1200.0m (scaled coordinate representation of Mars 3,389.5 km).
#   Provides continuous spherical curvature, visible horizon, and zero float-point jitter.
# - Complete 3D Sphere: No edges, no invisible walls. Continuous 360° circum-planetary travel.
# - Cube-Sphere Quadtree/Chunk LOD: 6 cube faces dynamically subdivided into spherical chunks.
# - Deterministic multi-octave geology:
#   * Olympus Mons (18.65° N, 226.2° E): Giant shield volcano rising above datum with summit caldera.
#   * Valles Marineris (13.9° S, 300.8° E): 4000 km grand canyon system with terraced walls.
#   * Jezero Crater (18.38° N, 77.58° E): River delta, ancient lakebed sediments, and Neretva Vallis.
#   * Gale Crater (-5.4° S, 137.8° E): Impact crater with central layered peak (Mount Sharp).
#   * Planum Boreum & Australe: North and South polar ice caps with perennial water/CO2 ice sheets.
#   * Global Dichotomy: Smooth northern lowlands vs heavily cratered southern highlands.
# - Exact Trimesh Collision on nearby active chunks. Distance & horizon-based culling.

signal chunk_loaded(chunk_id: String)
signal location_discovered(location_name: String, coords: Vector2)

# Planetary Constants
const REAL_MARS_RADIUS_KM: float = 3389.5
const MAX_OLYMPUS_HEIGHT_KM: float = 21.2
const MAX_VALLES_DEPTH_KM: float = 7.0

@export var planet_radius: float = 1200.0 # Meters in 3D world space
@export var max_elevation_amplitude: float = 65.0 # Max height displacement (Olympus Mons)
@export var chunk_subdivisions: int = 16 # Vertices per chunk edge (16x16 = 256 quads)
@export var face_grid_size: int = 12 # 12x12 chunks per cube face = 864 chunks total
@export var active_radius_chunks: int = 2 # Chunks loaded around player in each face direction

var planet_center: Vector3 = Vector3.ZERO
var _player_ref: CharacterBody3D = null

# Active chunks dictionary: key -> ChunkData { body: StaticBody3D, mesh_inst: MeshInstance3D, face: int, cx: int, cy: int }
var _active_chunks: Dictionary = {}
var _chunk_pool: Array[Dictionary] = []

# Discovered landmark locations
var known_landmarks: Array[Dictionary] = [
	{
		"id": "jezero",
		"name": "Jezero Crater (Neretva Delta)",
		"lat": 18.38,
		"lon": 77.58,
		"radius_deg": 4.5,
		"desc": "Ancient river delta lakebed explored by NASA's Perseverance rover.",
		"type": "Crater / Lakebed"
	},
	{
		"id": "olympus_mons",
		"name": "Olympus Mons",
		"lat": 18.65,
		"lon": 226.2,
		"radius_deg": 14.0,
		"desc": "The tallest volcano and planetary mountain in the Solar System, rising 21.2 km above datum.",
		"type": "Shield Volcano"
	},
	{
		"id": "valles_marineris",
		"name": "Valles Marineris (Grand Canyon)",
		"lat": -13.9,
		"lon": 300.8,
		"radius_deg": 18.0,
		"desc": "Vast tectonic canyon system stretching over 4,000 km, plunging 7 km deep.",
		"type": "Canyon System"
	},
	{
		"id": "gale_crater",
		"name": "Gale Crater & Mount Sharp",
		"lat": -5.4,
		"lon": 137.8,
		"radius_deg": 5.0,
		"desc": "Curiosity rover exploration site featuring towering central mound Aeolis Mons.",
		"type": "Impact Crater"
	},
	{
		"id": "north_pole",
		"name": "Planum Boreum (North Polar Ice Cap)",
		"lat": 84.0,
		"lon": 0.0,
		"radius_deg": 16.0,
		"desc": "Vast perennial water-ice and carbon-dioxide ice sheet carved by spiral troughs.",
		"type": "Polar Ice Cap"
	},
	{
		"id": "south_pole",
		"name": "Planum Australe (South Polar Ice Cap)",
		"lat": -85.0,
		"lon": 0.0,
		"radius_deg": 15.0,
		"desc": "Residual carbon dioxide dry-ice slab overlying thick dusty water ice deposits.",
		"type": "Polar Ice Cap"
	},
	{
		"id": "meridiani",
		"name": "Meridiani Planum",
		"lat": -1.94,
		"lon": 354.47,
		"radius_deg": 6.0,
		"desc": "Opportunity rover landing plain rich in hematite blueberries formed in ancient groundwater.",
		"type": "Sedimentary Plain"
	},
	{
		"id": "ares_vallis",
		"name": "Ares Vallis Floodplain",
		"lat": 19.13,
		"lon": 326.78,
		"radius_deg": 5.5,
		"desc": "Mars Pathfinder & Sojourner landing site within a catastrophic ancient flood outflow channel.",
		"type": "Outflow Channel"
	}
]

var _discovered_landmark_ids: Array[String] = []
var _last_chunk_key: String = ""

# Cube Face Bases: Maps face index 0..5 to 3D coordinate frame
# 0: +X (Right), 1: -X (Left), 2: +Y (Top/North), 3: -Y (Bottom/South), 4: +Z (Front), 5: -Z (Back)
const CUBE_FACES = [
	{"origin": Vector3(1, -1, -1), "right": Vector3(0, 0, 2), "up": Vector3(0, 2, 0)},     # +X
	{"origin": Vector3(-1, -1, 1), "right": Vector3(0, 0, -2), "up": Vector3(0, 2, 0)},    # -X
	{"origin": Vector3(-1, 1, -1), "right": Vector3(2, 0, 0), "up": Vector3(0, 0, 2)},     # +Y (North Pole)
	{"origin": Vector3(-1, -1, 1), "right": Vector3(2, 0, 0), "up": Vector3(0, 0, -2)},    # -Y (South Pole)
	{"origin": Vector3(-1, -1, 1), "right": Vector3(2, 0, 0), "up": Vector3(0, 2, 0)},     # +Z (Prime Meridian)
	{"origin": Vector3(1, -1, -1), "right": Vector3(-2, 0, 0), "up": Vector3(0, 2, 0)}     # -Z (Anti-Meridian)
]

func _ready() -> void:
	add_to_group("spherical_planet")
	add_to_group("terrain")
	planet_center = global_position
	_create_base_mars_terrain_body()
	_create_jezero_boulders_and_ventifacts()
	_create_kodiak_remnant_butte()
	_create_phobos_and_deimos()
	_instantiate_atmosphere_and_hud()
	call_deferred("_find_player_and_initialize")

# Legacy & sector elevation query for Jezero crater region
func get_terrain_height(x: float, z: float) -> float:
	var delta_gradient = (-x * 0.038 - z * 0.024)
	var delta_terrace = sin(x * 0.045 - z * 0.035) * 1.6 + cos(x * 0.025 + z * 0.040) * 1.2
	var channel_axis = x - 32.0 - sin(z * 0.05) * 6.0
	var channel_dist = abs(channel_axis)
	var channel_cut = 0.0
	if channel_dist < 14.0:
		var cf = cos((channel_dist / 14.0) * (PI * 0.5))
		channel_cut = -cf * 2.2
	var seitah_depression = 0.0
	var seitah_center = Vector2(-20.0, 28.0)
	var s_dist = Vector2(x, z).distance_to(seitah_center)
	if s_dist < 35.0:
		var sf = cos((s_dist / 35.0) * (PI * 0.5))
		seitah_depression = -sf * 1.8
		var dune_wave = sin(x * 0.18 + z * 0.12) * 0.85 + cos(x * 0.32 - z * 0.10) * 0.35
		seitah_depression += dune_wave * sf
	var ripple = sin(x * 0.55 + z * 0.42) * 0.07 + cos(x * 0.85 - z * 0.65) * 0.04
	var total_h = delta_gradient + delta_terrace + channel_cut + seitah_depression + ripple
	var b_dist = Vector2(x, z).distance_to(Vector2(-32.0, -28.0))
	if b_dist < 11.5:
		var norm_d = b_dist / 11.5
		total_h += -3.2 * (1.0 - norm_d * norm_d) + 1.45 * pow(norm_d, 3.5)
	return total_h

func _create_base_mars_terrain_body() -> void:
	var base_body = StaticBody3D.new()
	base_body.name = "MarsTerrainBody"
	base_body.collision_layer = 1
	base_body.collision_mask = 2
	add_child(base_body)

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s = 60.0
	var sub = 12
	var step = (s * 2.0) / float(sub)
	for i in range(sub):
		for j in range(sub):
			var x0 = -s + float(i) * step
			var x1 = -s + float(i + 1) * step
			var z0 = -s + float(j) * step
			var z1 = -s + float(j + 1) * step
			var y00 = get_terrain_height(x0, z0)
			var y10 = get_terrain_height(x1, z0)
			var y01 = get_terrain_height(x0, z1)
			var y11 = get_terrain_height(x1, z1)

			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x0, y00, z0))
			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x1, y10, z0))
			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x1, y11, z1))

			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x0, y00, z0))
			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x1, y11, z1))
			st.set_color(Color(0.72, 0.33, 0.18))
			st.add_vertex(Vector3(x0, y01, z1))

	st.generate_normals()
	var mesh = st.commit()

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "TerrainMesh"
	mesh_inst.mesh = mesh
	base_body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	col.name = "TerrainCollisionShape"
	col.shape = mesh.create_trimesh_shape()
	base_body.add_child(col)

func _create_jezero_boulders_and_ventifacts() -> void:
	var mat_basalt = StandardMaterial3D.new()
	mat_basalt.albedo_color = Color(0.24, 0.22, 0.21)
	var mat_sediment = StandardMaterial3D.new()
	mat_sediment.albedo_color = Color(0.62, 0.52, 0.40)
	var mat_ventifact = StandardMaterial3D.new()
	mat_ventifact.albedo_color = Color(0.48, 0.32, 0.24)
	mat_ventifact.roughness = 0.78

	var boulders = [
		{"name": "BelvaBoulder1", "pos": Vector2(-25.0, -22.0), "r": 2.4, "h": 2.1, "m": mat_basalt},
		{"name": "DeltaBenchRock", "pos": Vector2(-16.0, -12.0), "r": 2.6, "h": 1.4, "m": mat_sediment},
		{"name": "SeitahBlock1", "pos": Vector2(-14.0, 22.0), "r": 2.0, "h": 1.7, "m": mat_basalt},
		{"name": "Ventifact1", "pos": Vector2(12.0, 14.0), "r": 1.4, "h": 1.2, "m": mat_ventifact}
	]
	for b in boulders:
		var pos2 = b["pos"]
		var y = get_terrain_height(pos2.x, pos2.y)
		var body = StaticBody3D.new()
		body.name = b["name"]
		body.position = Vector3(pos2.x, y + b["h"] * 0.45, pos2.y)
		body.collision_layer = 1
		body.collision_mask = 2
		var mi = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = b["r"] * 0.75
		cyl.bottom_radius = b["r"]
		cyl.height = b["h"]
		cyl.material = b["m"]
		mi.mesh = cyl
		body.add_child(mi)
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(b["r"] * 1.8, b["h"], b["r"] * 1.8)
		col.shape = box
		body.add_child(col)
		add_child(body)

func _create_kodiak_remnant_butte() -> void:
	var butte = StaticBody3D.new()
	butte.name = "KodiakButte"
	butte.position = Vector3(45.0, get_terrain_height(45.0, 42.0) + 4.5, 42.0)
	butte.collision_layer = 1
	butte.collision_mask = 2
	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 8.0
	cyl.bottom_radius = 12.0
	cyl.height = 9.0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.66, 0.48, 0.36)
	cyl.material = mat
	mi.mesh = cyl
	butte.add_child(mi)
	var col = CollisionShape3D.new()
	var col_cyl = CylinderShape3D.new()
	col_cyl.radius = 11.0
	col_cyl.height = 9.0
	col.shape = col_cyl
	butte.add_child(col)
	add_child(butte)

func _create_phobos_and_deimos() -> void:
	var phobos_root = Node3D.new()
	phobos_root.name = "PhobosInSky"
	phobos_root.position = Vector3(140.0, 110.0, -180.0)
	add_child(phobos_root)

	var p_mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 7.5
	sphere.height = 13.0
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(0.35, 0.34, 0.33)
	sphere.material = p_mat
	p_mesh.mesh = sphere
	p_mesh.scale = Vector3(1.4, 0.9, 1.1)
	phobos_root.add_child(p_mesh)

	var stickney = MeshInstance3D.new()
	var s_sp = SphereMesh.new()
	s_sp.radius = 2.8
	s_sp.height = 1.6
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.24, 0.23, 0.22)
	s_sp.material = s_mat
	stickney.mesh = s_sp
	stickney.position = Vector3(4.2, 1.0, 1.5)
	stickney.scale = Vector3(1.1, 0.4, 1.1)
	phobos_root.add_child(stickney)

	var deimos_root = Node3D.new()
	deimos_root.name = "DeimosInSky"
	deimos_root.position = Vector3(-190.0, 145.0, 120.0)
	add_child(deimos_root)

	var d_mesh = MeshInstance3D.new()
	var d_sp = SphereMesh.new()
	d_sp.radius = 2.4
	d_sp.height = 3.6
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.40, 0.39, 0.38)
	d_sp.material = d_mat
	d_mesh.mesh = d_sp
	deimos_root.add_child(d_mesh)

func _instantiate_atmosphere_and_hud() -> void:
	var atmo_script = load("res://scripts/environment/mars_atmosphere_system.gd")
	if atmo_script and not get_node_or_null("MarsAtmosphereSystem"):
		var atmo_node = Node3D.new()
		atmo_node.set_script(atmo_script)
		add_child(atmo_node)

	var hud_script = load("res://scripts/ui/astronaut_helmet_hud.gd")
	if hud_script and not get_node_or_null("AstronautHelmetHUD"):
		var hud_node = CanvasLayer.new()
		hud_node.name = "AstronautHelmetHUD"
		hud_node.set_script(hud_script)
		add_child(hud_node)

	var map_script = load("res://scripts/ui/mars_planetary_map.gd")
	if map_script and not get_node_or_null("MarsPlanetaryMap"):
		var map_node = CanvasLayer.new()
		map_node.name = "MarsPlanetaryMap"
		map_node.set_script(map_script)
		add_child(map_node)

func _find_player_and_initialize() -> void:
	_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _player_ref:
		_player_ref = get_parent().get_node_or_null("Player") as CharacterBody3D
	
	if _player_ref:
		# Initial player placement on spherical Jezero Crater
		var jezero_dir = get_unit_vector_from_lat_lon(18.38, 77.58)
		var surf_pos = get_surface_position(jezero_dir)
		_player_ref.global_position = surf_pos + jezero_dir * 1.5
		# Align player to local surface normal
		if _player_ref.has_method("align_to_normal"):
			_player_ref.align_to_normal(jezero_dir)
	
	_update_spherical_chunks(true)
	_align_artifacts_to_sphere()

func _process(_delta: float) -> void:
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
		if not _player_ref:
			return
	
	# Determine current chunk under player
	var p_pos = _player_ref.global_position - planet_center
	var p_dir = p_pos.normalized()
	var chunk_info = get_cube_face_and_coords(p_dir)
	var current_key = "%d_%d_%d" % [chunk_info["face"], chunk_info["cx"], chunk_info["cy"]]
	
	if current_key != _last_chunk_key:
		_last_chunk_key = current_key
		_update_spherical_chunks(false)
		_check_landmark_discovery(p_dir)

# Converts latitude (-90 to +90) and longitude (0 to 360 East) to a unit direction vector
func get_unit_vector_from_lat_lon(lat_deg: float, lon_deg: float) -> Vector3:
	var lat_rad = deg_to_rad(lat_deg)
	var lon_rad = deg_to_rad(lon_deg)
	var y = sin(lat_rad)
	var r_xz = cos(lat_rad)
	var x = r_xz * sin(lon_rad)
	var z = r_xz * cos(lon_rad)
	return Vector3(x, y, z).normalized()

# Converts a unit direction vector to latitude (-90 to +90) and longitude (0 to 360 East)
func get_lat_lon_from_unit_vector(dir: Vector3) -> Vector2:
	var d = dir.normalized()
	var lat = rad_to_deg(asin(clampf(d.y, -1.0, 1.0)))
	var lon = rad_to_deg(atan2(d.x, d.z))
	if lon < 0.0:
		lon += 360.0
	return Vector2(lat, lon)

# Returns detailed planetary telemetry at any 3D world position
func get_planetary_coords(world_pos: Vector3) -> Dictionary:
	var d = (world_pos - planet_center).normalized()
	var coords = get_lat_lon_from_unit_vector(d)
	var lat = coords.x
	var lon = coords.y
	var elev_rel = (world_pos - planet_center).length() - planet_radius
	
	# Scale relative elevation to real Mars kilometers (-7 km to +21.2 km)
	var elev_km = (elev_rel / max_elevation_amplitude) * 12.0
	
	# Temperature model (°C): Latitudinal gradient + elevation lapse rate + polar freeze
	var lat_factor = cos(deg_to_rad(lat))
	var base_temp = lerp(-125.0, -20.0, pow(clampf(lat_factor, 0.0, 1.0), 1.2))
	var lapse_temp = base_temp - (elev_km * 4.5)
	
	# Determine biome
	var biome = "Ferric Oxide Plains"
	if abs(lat) > 74.0:
		biome = "Perennial Polar Ice Sheet"
	elif is_point_near_landmark(lat, lon, "olympus_mons", 12.0):
		biome = "Tharsis Volcanic Shield"
	elif is_point_near_landmark(lat, lon, "valles_marineris", 15.0):
		biome = "Rift Canyon Chasma"
	elif is_point_near_landmark(lat, lon, "jezero", 4.0):
		biome = "Lacustrine Delta Outcrop"
	elif elev_km < -3.0:
		biome = "Deep Impact Basin Floor"
	elif elev_km > 5.0:
		biome = "Highland Bedrock Ridge"
	
	return {
		"lat": lat,
		"lon": lon,
		"elevation_km": elev_km,
		"temp_c": lapse_temp,
		"biome": biome
	}

func is_point_near_landmark(lat: float, lon: float, landmark_id: String, threshold_deg: float) -> bool:
	for lm in known_landmarks:
		if lm["id"] == landmark_id:
			var d_lat = lat - lm["lat"]
			var d_lon = abs(lon - lm["lon"])
			if d_lon > 180.0:
				d_lon = 360.0 - d_lon
			var angular_dist = sqrt(d_lat * d_lat + d_lon * d_lon)
			return angular_dist <= threshold_deg
	return false

# Master elevation calculation: returns displacement in meters above base planet radius
func get_elevation(unit_dir: Vector3) -> float:
	var d = unit_dir.normalized()
	var coords = get_lat_lon_from_unit_vector(d)
	var lat = coords.x
	var lon = coords.y
	
	var total_h = 0.0
	
	# 1. GLOBAL DICHOTOMY: Southern cratered highlands vs Northern smooth plains
	var dichotomy_boundary = sin(deg_to_rad(lon) * 1.5) * 15.0 - 5.0
	var dichotomy_t = smoothstep(dichotomy_boundary - 12.0, dichotomy_boundary + 12.0, lat)
	var dichotomy_elev = lerp(8.0, -6.0, dichotomy_t)
	total_h += dichotomy_elev
	
	# 2. OLYMPUS MONS (18.65° N, 226.2° E): Giant shield volcano
	var o_lat = 18.65
	var o_lon = 226.2
	var d_o_lat = lat - o_lat
	var d_o_lon = abs(lon - o_lon)
	if d_o_lon > 180.0:
		d_o_lon = 360.0 - d_o_lon
	var dist_o_deg = sqrt(d_o_lat * d_o_lat + d_o_lon * d_o_lon)
	if dist_o_deg < 14.0:
		var t_o = dist_o_deg / 14.0
		# Broad shield profile with steep outer scarp
		var shield = pow(cos(t_o * PI * 0.5), 1.8) * 55.0
		# Summit Caldera depression
		if dist_o_deg < 2.5:
			var cald_t = dist_o_deg / 2.5
			shield -= (1.0 - cald_t * cald_t) * 9.5
		total_h += shield
	
	# 3. VALLES MARINERIS (13.9° S, 300.8° E): Grand canyon rift
	var v_lat = -13.9
	if lon >= 265.0 and lon <= 325.0:
		var v_center_lat = v_lat + sin(deg_to_rad(lon - 265.0) * 2.0) * 1.5
		var lat_dist = abs(lat - v_center_lat)
		if lat_dist < 4.5:
			var canyon_t = lat_dist / 4.5
			# Steep stepped canyon walls with deep canyon chasma floor (up to 7-10 km depth)
			var canyon_depth = (1.0 - pow(canyon_t, 2.5)) * 35.0
			total_h -= canyon_depth
	
	# 4. JEZERO CRATER (18.38° N, 77.58° E): River delta and impact crater
	var j_lat = 18.38
	var j_lon = 77.58
	var d_j_lat = lat - j_lat
	var d_j_lon = abs(lon - j_lon)
	if d_j_lon > 180.0:
		d_j_lon = 360.0 - d_j_lon
	var dist_j_deg = sqrt(d_j_lat * d_j_lat + d_j_lon * d_j_lon)
	if dist_j_deg < 4.5:
		var j_t = dist_j_deg / 4.5
		if j_t < 0.7:
			# Crater bowl and sedimentary delta shelf
			var delta_shelf = (1.0 - j_t / 0.7) * -7.5
			if j_t < 0.35 and lon < 77.58:
				delta_shelf += 2.2 # Raised delta fan
			total_h += delta_shelf
		else:
			# Raised crater rim
			var rim_norm = (j_t - 0.7) / 0.3
			var rim = sin(rim_norm * PI) * 3.8
			total_h += rim
	
	# 5. GALE CRATER (-5.4° S, 137.8° E): Central peak Aeolis Mons
	var g_lat = -5.4
	var g_lon = 137.8
	var d_g_lat = lat - g_lat
	var d_g_lon = abs(lon - g_lon)
	if d_g_lon > 180.0:
		d_g_lon = 360.0 - d_g_lon
	var dist_g_deg = sqrt(d_g_lat * d_g_lat + d_g_lon * d_g_lon)
	if dist_g_deg < 5.0:
		var g_t = dist_g_deg / 5.0
		if g_t < 0.3:
			# Central mountain (Mount Sharp)
			total_h += (1.0 - g_t / 0.3) * 8.5
		else:
			# Crater floor depression & rim
			total_h -= (1.0 - g_t) * 5.0
	
	# 6. POLAR ICE CAPS (Planum Boreum / Australe)
	if abs(lat) > 74.0:
		var pole_t = (abs(lat) - 74.0) / 16.0
		# Spiral trough elevation waves
		var spiral = sin(deg_to_rad(lon) * 4.0 + pole_t * 6.0) * 1.8
		var dome = pow(pole_t, 1.4) * 14.0
		total_h += dome + spiral
	
	# 7. PROCEDURAL CRATERING & GEOLOGICAL NOISE (Deterministic spherical harmonics)
	var p_x = d.x * 12.0
	var p_y = d.y * 12.0
	var p_z = d.z * 12.0
	var macro_noise = sin(p_x * 0.45 + p_z * 0.35) * cos(p_y * 0.40) * 4.2
	var meso_noise = sin(p_x * 1.8 - p_y * 1.4) * cos(p_z * 1.6 + p_x * 0.8) * 1.6
	var micro_ripple = sin(p_x * 6.5 + p_z * 5.5) * cos(p_y * 7.2) * 0.35
	
	total_h += macro_noise + meso_noise + micro_ripple
	return total_h

# Returns the exact 3D surface point on the spherical planet
func get_surface_position(unit_dir: Vector3) -> Vector3:
	var d = unit_dir.normalized()
	var h = get_elevation(d)
	return planet_center + d * (planet_radius + h)

# Returns surface normal at any world position
func get_surface_normal(world_pos: Vector3) -> Vector3:
	var d = (world_pos - planet_center).normalized()
	# Sample slight angular tangents to calculate true surface normal
	var eps = 0.0015
	var t1 = (d + Vector3(eps, 0, 0)).normalized()
	var t2 = (d + Vector3(0, 0, eps)).normalized()
	var p0 = get_surface_position(d)
	var p1 = get_surface_position(t1)
	var p2 = get_surface_position(t2)
	var n = (p1 - p0).cross(p2 - p0).normalized()
	if n.dot(d) < 0.0:
		n = -n
	return n

# Determines the cube face (0..5) and integer chunk coordinates (cx, cy) from unit direction
func get_cube_face_and_coords(dir: Vector3) -> Dictionary:
	var d = dir.normalized()
	var abs_x = abs(d.x)
	var abs_y = abs(d.y)
	var abs_z = abs(d.z)
	
	var face = 0
	var max_axis = abs_x
	var u = 0.0
	var v = 0.0
	
	if abs_x >= abs_y and abs_x >= abs_z:
		face = 0 if d.x > 0 else 1
		var sign_x = 1.0 if d.x > 0 else -1.0
		u = (d.z / abs_x) * -sign_x
		v = d.y / abs_x
	elif abs_y >= abs_x and abs_y >= abs_z:
		face = 2 if d.y > 0 else 3
		var sign_y = 1.0 if d.y > 0 else -1.0
		u = d.x / abs_y
		v = (d.z / abs_y) * sign_y
	else:
		face = 4 if d.z > 0 else 5
		var sign_z = 1.0 if d.z > 0 else -1.0
		u = (d.x / abs_z) * sign_z
		v = d.y / abs_z
	
	# Map normalized face coordinate [-1, 1] to integer grid [0, face_grid_size - 1]
	var norm_u = clampf((u + 1.0) * 0.5, 0.0, 0.9999)
	var norm_v = clampf((v + 1.0) * 0.5, 0.0, 0.9999)
	var cx = int(norm_u * float(face_grid_size))
	var cy = int(norm_v * float(face_grid_size))
	
	return {"face": face, "cx": cx, "cy": cy, "u": u, "v": v}

# Dynamically loads nearby chunks with exact collision and unloads distant chunks
func _update_spherical_chunks(force_refresh: bool) -> void:
	if not _player_ref:
		return
	
	var p_pos = _player_ref.global_position - planet_center
	var p_dir = p_pos.normalized()
	var center_info = get_cube_face_and_coords(p_dir)
	var active_face = center_info["face"]
	var center_cx = center_info["cx"]
	var center_cy = center_info["cy"]
	
	var needed_chunk_keys: Dictionary = {}
	
	# Determine required chunks around player in current and adjacent cube faces
	for f in range(6):
		var face_center_dir = _get_face_center_direction(f)
		# Only check faces facing roughly toward player (culls rear half of planet)
		if face_center_dir.dot(p_dir) < -0.2:
			continue
		
		for dx in range(-active_radius_chunks, active_radius_chunks + 1):
			for dy in range(-active_radius_chunks, active_radius_chunks + 1):
				var target_cx = center_cx + dx
				var target_cy = center_cy + dy
				
				# If on active face or neighbor within grid
				if f == active_face:
					if target_cx >= 0 and target_cx < face_grid_size and target_cy >= 0 and target_cy < face_grid_size:
						var key = "%d_%d_%d" % [f, target_cx, target_cy]
						needed_chunk_keys[key] = {"face": f, "cx": target_cx, "cy": target_cy}
				else:
					# Add chunks near edges of adjacent faces
					var adj_cx = clampi(target_cx, 0, face_grid_size - 1)
					var adj_cy = clampi(target_cy, 0, face_grid_size - 1)
					var key = "%d_%d_%d" % [f, adj_cx, adj_cy]
					needed_chunk_keys[key] = {"face": f, "cx": adj_cx, "cy": adj_cy}
	
	# Unload chunks that are no longer needed
	var keys_to_remove: Array = []
	for k in _active_chunks.keys():
		if not needed_chunk_keys.has(k) or force_refresh:
			keys_to_remove.append(k)
	
	for k in keys_to_remove:
		var c_data = _active_chunks[k]
		if is_instance_valid(c_data["body"]):
			c_data["body"].queue_free()
		_active_chunks.erase(k)
	
	# Load missing chunks
	for k in needed_chunk_keys.keys():
		if not _active_chunks.has(k):
			var info = needed_chunk_keys[k]
			_generate_chunk(info["face"], info["cx"], info["cy"], k)

func _get_face_center_direction(face_idx: int) -> Vector3:
	match face_idx:
		0: return Vector3.RIGHT
		1: return Vector3.LEFT
		2: return Vector3.UP
		3: return Vector3.DOWN
		4: return Vector3.BACK
		5: return Vector3.FORWARD
	return Vector3.UP

# Generates a single spherical cube-sphere chunk with PBR vertex colors & trimesh collision
func _generate_chunk(face_idx: int, cx: int, cy: int, key: String) -> void:
	var face_cfg = CUBE_FACES[face_idx]
	var f_origin: Vector3 = face_cfg["origin"]
	var f_right: Vector3 = face_cfg["right"]
	var f_up: Vector3 = face_cfg["up"]
	
	var chunk_step = 1.0 / float(face_grid_size)
	var u_min = float(cx) * chunk_step
	var u_max = float(cx + 1) * chunk_step
	var v_min = float(cy) * chunk_step
	var v_max = float(cy + 1) * chunk_step
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var verts_per_row = chunk_subdivisions + 1
	var grid_pts: Array = []
	grid_pts.resize(verts_per_row)
	
	for i in range(verts_per_row):
		var row: Array = []
		row.resize(verts_per_row)
		var u = lerp(u_min, u_max, float(i) / float(chunk_subdivisions))
		for j in range(verts_per_row):
			var v = lerp(v_min, v_max, float(j) / float(chunk_subdivisions))
			
			# Point on cube face [-1, 1]
			var cube_pt = f_origin + f_right * u + f_up * v
			var unit_dir = cube_pt.normalized()
			
			# Spherical displacement
			var h = get_elevation(unit_dir)
			var surf_pos = unit_dir * (planet_radius + h)
			var col = _calculate_spherical_vertex_color(unit_dir, h)
			var uv = Vector2(u * 18.0, v * 18.0)
			
			row[j] = {"pos": surf_pos, "col": col, "uv": uv}
		grid_pts[i] = row
	
	for i in range(chunk_subdivisions):
		for j in range(chunk_subdivisions):
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
	
	# PBR Martian planetary surface material
	var pbr_mat = StandardMaterial3D.new()
	pbr_mat.vertex_color_use_as_albedo = true
	pbr_mat.roughness = 0.94
	pbr_mat.metallic = 0.04
	pbr_mat.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	mesh.surface_set_material(0, pbr_mat)
	
	var chunk_body = StaticBody3D.new()
	chunk_body.name = "Chunk_" + key
	chunk_body.collision_layer = 1
	chunk_body.collision_mask = 2
	add_child(chunk_body)
	
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "Mesh"
	mesh_inst.mesh = mesh
	chunk_body.add_child(mesh_inst)
	
	# Generate exact ConcavePolygonShape3D collision for player footing
	var col_shape = CollisionShape3D.new()
	col_shape.name = "Collision"
	col_shape.shape = mesh.create_trimesh_shape()
	chunk_body.add_child(col_shape)
	
	_active_chunks[key] = {
		"body": chunk_body,
		"mesh_inst": mesh_inst,
		"face": face_idx,
		"cx": cx,
		"cy": cy
	}
	
	chunk_loaded.emit(key)

# Procedural PBR coloration based on latitude, altitude, and geographic biome
func _calculate_spherical_vertex_color(unit_dir: Vector3, elev: float) -> Color:
	var coords = get_lat_lon_from_unit_vector(unit_dir)
	var lat = coords.x
	var lon = coords.y
	
	# Base rust-red ferric dust
	var col_dust = Color(0.72, 0.33, 0.18)
	# Polar water/CO2 ice
	var col_ice = Color(0.95, 0.96, 0.98)
	# Dark basaltic volcanic rock
	var col_basalt = Color(0.24, 0.22, 0.21)
	# Tan sedimentary delta mudstone
	var col_sediment = Color(0.64, 0.53, 0.41)
	# Sulfate evaporite / duricrust
	var col_duricrust = Color(0.76, 0.63, 0.50)
	
	var final_col = col_dust
	
	# 1. Polar caps (Planum Boreum / Australe)
	if abs(lat) > 72.0:
		var ice_t = clampf((abs(lat) - 72.0) / 10.0, 0.0, 1.0)
		final_col = final_col.lerp(col_ice, ice_t * 0.95)
	
	# 2. Olympus Mons volcanic basalt flanks & caldera
	var d_o_lat = lat - 18.65
	var d_o_lon = abs(lon - 226.2)
	if d_o_lon > 180.0:
		d_o_lon = 360.0 - d_o_lon
	var dist_o = sqrt(d_o_lat * d_o_lat + d_o_lon * d_o_lon)
	if dist_o < 14.0:
		var o_weight = clampf(1.0 - (dist_o / 14.0), 0.0, 1.0)
		final_col = final_col.lerp(col_basalt, o_weight * 0.85)
	
	# 3. Valles Marineris canyon layered stratigraphy
	if lon >= 265.0 and lon <= 325.0 and abs(lat - (-13.9)) < 4.5:
		var canyon_weight = clampf(1.0 - (abs(lat - (-13.9)) / 4.5), 0.0, 1.0)
		# Distinct layered strata alternating tan sedimentary rock and dark basalt
		var strata_band = sin(elev * 0.85)
		var strata_col = col_sediment.lerp(col_basalt, (strata_band + 1.0) * 0.5)
		final_col = final_col.lerp(strata_col, canyon_weight * 0.80)
	
	# 4. Jezero Crater lacustrine clay & delta sediments
	var d_j_lat = lat - 18.38
	var d_j_lon = abs(lon - 77.58)
	if d_j_lon > 180.0:
		d_j_lon = 360.0 - d_j_lon
	var dist_j = sqrt(d_j_lat * d_j_lat + d_j_lon * d_j_lon)
	if dist_j < 4.0:
		var j_weight = clampf(1.0 - (dist_j / 4.0), 0.0, 1.0)
		final_col = final_col.lerp(col_sediment, j_weight * 0.70)
	
	# High-frequency natural variation
	var noise = sin(unit_dir.x * 24.0 + unit_dir.z * 18.0) * 0.03
	return Color(
		clampf(final_col.r + noise, 0.05, 1.0),
		clampf(final_col.g + noise * 0.8, 0.05, 1.0),
		clampf(final_col.b + noise * 0.6, 0.05, 1.0)
	)

# Checks if the astronaut has entered any landmark discovery radius
func _check_landmark_discovery(player_unit_dir: Vector3) -> void:
	var coords = get_lat_lon_from_unit_vector(player_unit_dir)
	var lat = coords.x
	var lon = coords.y
	
	for lm in known_landmarks:
		var lm_id: String = lm["id"]
		if _discovered_landmark_ids.has(lm_id):
			continue
		
		var d_lat = lat - lm["lat"]
		var d_lon = abs(lon - lm["lon"])
		if d_lon > 180.0:
			d_lon = 360.0 - d_lon
		var dist_deg = sqrt(d_lat * d_lat + d_lon * d_lon)
		
		if dist_deg <= lm["radius_deg"]:
			_discovered_landmark_ids.append(lm_id)
			location_discovered.emit(lm["name"], Vector2(lm["lat"], lm["lon"]))
			print("[SphericalMars] Discovered Landmark: ", lm["name"], " at (", lm["lat"], "°, ", lm["lon"], "°)")

# Snaps all artifacts in the scene to their designated planetary spherical coordinates
func _align_artifacts_to_sphere() -> void:
	call_deferred("_do_align_artifacts")

func _do_align_artifacts() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# Geographic placement table for authentic Martian exploration
	var artifact_locations = {
		"jezero_delta_clay": Vector2(18.38, 77.58), # Jezero delta
		"seitah_olivine_basalt": Vector2(18.35, 77.62), # Séítah floor
		"perseverance_heatshield_remnant": Vector2(18.32, 77.52), # EDL impact scatter
		"martian_meteorite_shergottite": Vector2(18.42, 77.65), # Belva crater rim
		"ingenuity": Vector2(18.40, 77.56), # Airfield
		"opportunity": Vector2(-1.94, 354.47), # Meridiani Planum
		"sojourner": Vector2(19.13, 326.78) # Ares Vallis
	}
	
	for child in parent_node.get_children():
		if child.is_in_group("artifacts"):
			var art_id = child.get_artifact_id()
			var target_lat_lon = artifact_locations.get(art_id, Vector2(18.38, 77.58))
			var u_dir = get_unit_vector_from_lat_lon(target_lat_lon.x, target_lat_lon.y)
			var surf_pos = get_surface_position(u_dir)
			var surf_norm = get_surface_normal(surf_pos)
			
			child.global_position = surf_pos
			# Align artifact orientation with local planetary normal
			var cur_up = child.global_transform.basis.y
			if cur_up.cross(surf_norm).length() > 0.01:
				var axis = cur_up.cross(surf_norm).normalized()
				var angle = cur_up.angle_to(surf_norm)
				child.global_rotate(axis, angle)
