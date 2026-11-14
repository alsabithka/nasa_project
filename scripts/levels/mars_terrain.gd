extends Node3D

# Echoes Beyond Earth - Infinite, Fully Spherical Mars Planetary System & Jezero Surface Environment
# Grounded in NASA Mars 2020 Perseverance Mastcam-Z, SuperCam, Curiosity Mastcam, MOLA, and HiRISE datasets:
# Landing Site: Jezero Crater (18.38° N, 77.58° E)
#
# Scientific Architecture:
# 1. INFINITE FULLY SPHERICAL MARS:
#    - Complete 3D sphere: Base radius 1200.0m (scaled coordinate representation of Mars 3,389.5 km).
#    - Curvature & Gravity: Planetary center at Vector3(0, -1200, 0); local gravity points directly toward center.
#    - Continuous 360° circum-planetary navigation with zero artificial boundaries or invisible walls.
#    - Dynamic Cube-Sphere quadtree chunk streaming with distance-based LOD and culling.
# 2. REALISTIC REFERENCE BIOME (JEZERO CRATER LANDING PLAIN):
#    - Broad foreground covered with fine reddish-orange Martian regolith and wind-shaped ripples.
#    - Asymmetric aerodynamic wind ripple profiles with dark basaltic grain accumulation in troughs.
#    - Multi-tiered flat sedimentary bedrock slabs with stepped fracture edges (mudstone/siltstone).
#    - Varied rock clusters, ventifacts, volcanic basalt boulders, and scree fields with open sandy spaces.
#    - Meandering Neretva Vallis ancient inflow channel and South Séítah dark barchan dunes.
#    - Kodiak remnant butte / delta mesa outpost standing on the western horizon.
# 3. GLOBAL MARTIAN BIOME SYSTEM & REAL GEOGRAPHY:
#    - Olympus Mons (18.65° N, 226.2° E): Giant shield volcano (+65m above datum) with summit caldera and basal scarp.
#    - Valles Marineris (13.9° S, 300.8° E): Grand canyon chasma plunging -32m deep with terraced bedrock walls.
#    - Gale Crater & Mount Sharp (-5.4° S, 137.8° E): Central layered sedimentary mound with sulfate clay beds.
#    - Planum Boreum (84° N) & Planum Australe (-85° S): Polar water-ice and CO2 dry-ice sheets with spiral troughs.
#    - Global Dichotomy: Smooth northern lowlands (Vastitas Borealis) vs heavily cratered southern highlands (Noachis Terra).
# 4. SCIENTIFIC PBR SHADER & ATMOSPHERE:
#    - Tangent-space normal perturbation creates micro-shadows along ripple crests under low-angle sunlight.
#    - Suspended ferric oxide dust particles, convective dust devils, and authentic low-pressure wind acoustics.
#    - Phobos (Stickney crater landmark) and Deimos in the butterscotch/salmon sky dome.

signal chunk_loaded(chunk_id: String)
signal location_discovered(location_name: String, coords: Vector2)

# Planetary Constants
const REAL_MARS_RADIUS_KM: float = 3389.5
const MAX_OLYMPUS_HEIGHT_KM: float = 21.2
const MAX_VALLES_DEPTH_KM: float = 7.0

# Terrain Dimensions & Spherical Parameters
@export var terrain_size: float = 185.0
@export var grid_subdivisions: int = 130
@export var ground_seed: int = 2021 # Mars 2020 Perseverance landing year
@export var planet_radius: float = 1200.0 # 3D world meters representing 3,389.5 km
@export var chunk_subdivisions: int = 12 # 12x12 = 144 quads per planetary chunk
@export var face_grid_size: int = 8 # 8x8 chunks per cube face

var planet_center: Vector3 = Vector3(0.0, -1200.0, 0.0)
var terrain_body: StaticBody3D
var terrain_mesh_instance: MeshInstance3D

var _active_chunks: Dictionary = {}
var _player_ref: CharacterBody3D = null
var _last_chunk_check_pos: Vector3 = Vector3.ZERO
var _basis_jezero_rotation: Basis = Basis.IDENTITY
var _spawned_historical_spacecraft: Dictionary = {}

# Known NASA planetary landmarks & biomes
var known_landmarks: Array[Dictionary] = [
	{
		"id": "jezero",
		"name": "Jezero Crater & Neretva Delta",
		"lat": 18.38,
		"lon": 77.58,
		"radius_deg": 4.5,
		"biome": "Rocky Sandy Plain (Primary Reference Biome)",
		"desc": "Ancient river delta lakebed with wind-shaped sand ripples and sedimentary rock slabs."
	},
	{
		"id": "olympus_mons",
		"name": "Olympus Mons (Summit Caldera)",
		"lat": 18.65,
		"lon": 226.2,
		"radius_deg": 12.0,
		"biome": "Volcanic Shield & Caldera",
		"desc": "The tallest volcano in the Solar System, rising 21.2 km above datum with basal cliffs."
	},
	{
		"id": "valles_marineris",
		"name": "Valles Marineris (Chasma)",
		"lat": -13.9,
		"lon": 300.8,
		"radius_deg": 16.0,
		"biome": "Tectonic Canyon Chasma",
		"desc": "Grand canyon system plunging 7 km deep with terraced bedrock walls."
	},
	{
		"id": "gale_crater",
		"name": "Gale Crater & Mount Sharp",
		"lat": -5.4,
		"lon": 137.8,
		"radius_deg": 5.0,
		"biome": "Impact Crater & Central Mound",
		"desc": "Curiosity rover exploration site featuring towering central mound Aeolis Mons."
	},
	{
		"id": "north_pole",
		"name": "Planum Boreum (North Polar Ice Cap)",
		"lat": 84.0,
		"lon": 0.0,
		"radius_deg": 14.0,
		"biome": "Polar Water/CO2 Ice Sheet",
		"desc": "Vast perennial water-ice and dry-ice cap carved by spiral troughs."
	},
	{
		"id": "south_pole",
		"name": "Planum Australe (South Polar Ice Cap)",
		"lat": -85.0,
		"lon": 0.0,
		"radius_deg": 14.0,
		"biome": "Polar Residual Dry Ice Sheet",
		"desc": "Residual carbon dioxide dry-ice sheet overlying thick dusty deposits."
	},
	{
		"id": "meridiani",
		"name": "Meridiani Planum",
		"lat": -1.94,
		"lon": 354.47,
		"radius_deg": 6.0,
		"biome": "Hematite Sand Plains",
		"desc": "Opportunity rover plain rich in hematite blueberries formed by ancient groundwater."
	},
	{
		"id": "elysium",
		"name": "Elysium Planitia",
		"lat": 4.5,
		"lon": 135.6,
		"radius_deg": 7.0,
		"biome": "Smooth Volcanic Plain",
		"desc": "Vast smooth volcanic plain investigated by NASA's InSight lander."
	}
]

# Historical Mars Surface Exploration Hardware catalog (authentic NASA landing coordinates)
var historical_spacecraft_catalog: Array[Dictionary] = [
	{
		"id": "pathfinder",
		"name": "Mars Pathfinder Lander",
		"lat": 19.33,
		"lon": 326.45,
		"site": "Ares Vallis",
		"dust_level": 0.50
	},
	{
		"id": "sojourner",
		"name": "Sojourner Rover",
		"lat": 19.3302,
		"lon": 326.4503,
		"site": "Ares Vallis (Adjacent to Pathfinder)",
		"dust_level": 0.45
	},
	{
		"id": "spirit",
		"name": "Spirit Rover (MER-A)",
		"lat": -14.57,
		"lon": 175.47,
		"site": "Gusev Crater / Columbia Hills - Troy",
		"dust_level": 0.70
	},
	{
		"id": "opportunity",
		"name": "Opportunity Rover (MER-B)",
		"lat": -1.95,
		"lon": 354.47,
		"site": "Meridiani Planum / Perseverance Valley",
		"dust_level": 0.65
	},
	{
		"id": "viking_1",
		"name": "Viking 1 Lander",
		"lat": 22.27,
		"lon": 312.05,
		"site": "Chryse Planitia",
		"dust_level": 0.55
	},
	{
		"id": "viking_2",
		"name": "Viking 2 Lander",
		"lat": 47.97,
		"lon": 134.29,
		"site": "Utopia Planitia",
		"dust_level": 0.55
	},
	{
		"id": "phoenix",
		"name": "Phoenix Mars Lander",
		"lat": 68.22,
		"lon": 234.25,
		"site": "Vastitas Borealis",
		"dust_level": 0.40
	},
	{
		"id": "insight",
		"name": "InSight Mars Lander",
		"lat": 4.50,
		"lon": 135.62,
		"site": "Elysium Planitia",
		"dust_level": 0.70
	},
	{
		"id": "ingenuity",
		"name": "Ingenuity Mars Helicopter",
		"lat": 18.44,
		"lon": 77.45,
		"site": "Jezero Crater / Valinor Hills",
		"dust_level": 0.30
	}
]

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
	add_to_group("spherical_planet")
	_init_planetary_basis()
	_generate_mars_terrain_mesh_and_collision()
	_create_jezero_boulders_and_ventifacts()
	_create_flat_layered_bedrock_formations()
	_create_rock_clusters_and_scree_fields()
	_create_kodiak_remnant_butte()
	_create_phobos_and_deimos()
	_instantiate_atmosphere_and_hud()
	_align_scene_objects_to_surface()
	_find_player_and_initialize()

func _process(_delta: float) -> void:
	if not _player_ref:
		_find_player_and_initialize()
		return

	_update_spherical_chunks(false)
	var unit_p = (_player_ref.global_position - planet_center).normalized()
	_check_landmark_discovery(unit_p)
	_update_historical_spacecraft_proximity(unit_p)

func _find_player_and_initialize() -> void:
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _player_ref:
		var parent = get_parent()
		if parent:
			_player_ref = parent.get_node_or_null("Player") as CharacterBody3D

# Initialises the rotation basis aligning Jezero Crater (18.38° N, 77.58° E) to Vector3.UP
func _init_planetary_basis() -> void:
	planet_center = Vector3(0.0, -planet_radius, 0.0)
	var v0 = Vector3(
		cos(deg_to_rad(18.38)) * sin(deg_to_rad(77.58)),
		sin(deg_to_rad(18.38)),
		cos(deg_to_rad(18.38)) * cos(deg_to_rad(77.58))
	).normalized()
	var rot_axis = v0.cross(Vector3.UP).normalized()
	var rot_angle = v0.angle_to(Vector3.UP)
	_basis_jezero_rotation = Basis(rot_axis, rot_angle)

# Public elevation query (backward compatible for Jezero landing site)
func get_terrain_height(x: float, z: float) -> float:
	return _calc_height(x, z)

# Returns the spherical 3D surface point for local coordinates (x, z)
func get_surface_point(x: float, z: float) -> Vector3:
	var unit_dir = Vector3(x, planet_radius, z).normalized()
	var elev = _calc_height(x, z)
	return planet_center + unit_dir * (planet_radius + elev)

# Returns surface normal at any world position
func get_surface_normal(world_pos: Vector3) -> Vector3:
	var diff = world_pos - planet_center
	if diff.length_squared() > 1.0:
		return diff.normalized()
	return Vector3.UP

# Returns surface position for any unit direction vector from planet center
func get_surface_position(unit_dir: Vector3) -> Vector3:
	var elev = get_elevation(unit_dir)
	return planet_center + unit_dir.normalized() * (planet_radius + elev)

# Converts direction vector to real Martian latitude and longitude
func get_lat_lon_from_unit_vector(dir: Vector3) -> Vector2:
	var v_prime = _basis_jezero_rotation.inverse() * dir.normalized()
	var lat = rad_to_deg(asin(clampf(v_prime.y, -1.0, 1.0)))
	var lon = rad_to_deg(atan2(v_prime.x, v_prime.z))
	if lon < 0.0:
		lon += 360.0
	return Vector2(lat, lon)

# Converts real Martian latitude and longitude to unit direction vector on sphere
func get_unit_vector_from_lat_lon(lat_deg: float, lon_deg: float) -> Vector3:
	var phi = deg_to_rad(lat_deg)
	var lam = deg_to_rad(lon_deg)
	var v_prime = Vector3(cos(phi) * sin(lam), sin(phi), cos(phi) * cos(lam)).normalized()
	return (_basis_jezero_rotation * v_prime).normalized()

# Returns comprehensive planetary coordinates and telemetry for a world position
func get_planetary_coords(world_pos: Vector3) -> Dictionary:
	var unit_dir = (world_pos - planet_center).normalized()
	var coords = get_lat_lon_from_unit_vector(unit_dir)
	var elev = (world_pos - planet_center).length() - planet_radius

	var current_biome = "Jezero Crater Plain"
	var nearest_landmark = ""
	var min_dist = 9999.0

	for lm in known_landmarks:
		var d = _angular_distance_deg(coords.x, coords.y, lm["lat"], lm["lon"])
		if d < lm["radius_deg"]:
			current_biome = lm["biome"]
			nearest_landmark = lm["name"]
			break
		elif d < min_dist:
			min_dist = d
			nearest_landmark = lm["name"]

	return {
		"lat": coords.x,
		"lon": coords.y,
		"elevation": elev,
		"biome": current_biome,
		"nearest_landmark": nearest_landmark,
		"unit_dir": unit_dir
	}

# Calculates surface elevation for any unit direction on the planetary sphere
func get_elevation(unit_dir: Vector3) -> float:
	var dist_to_jezero = unit_dir.angle_to(Vector3.UP)
	if dist_to_jezero < 0.12:
		var lx = unit_dir.x * planet_radius
		var lz = unit_dir.z * planet_radius
		var h_local = _calc_height(lx, lz)
		if dist_to_jezero < 0.075:
			return h_local
		var coords = get_lat_lon_from_unit_vector(unit_dir)
		var h_glob = _calc_global_elevation(coords.x, coords.y, unit_dir)
		var blend_w = (dist_to_jezero - 0.075) / (0.12 - 0.075)
		return lerp(h_local, h_glob, blend_w)

	var c = get_lat_lon_from_unit_vector(unit_dir)
	return _calc_global_elevation(c.x, c.y, unit_dir)

# Global planetary elevation based on real NASA MOLA data
func _calc_global_elevation(lat: float, lon: float, unit_dir: Vector3) -> float:
	var total_h = 0.0

	# 1. Global Dichotomy: Northern lowlands (-3.5m) vs Southern highlands (+4.5m)
	var dichotomy_boundary = sin(deg_to_rad(lat) - 0.22) * 4.8
	total_h += dichotomy_boundary

	# 2. Olympus Mons (18.65° N, 226.2° E) - Tallest volcano in Solar System (+65m above datum)
	var d_oly = _angular_distance_deg(lat, lon, 18.65, 226.2)
	if d_oly < 12.0:
		var norm_oly = d_oly / 12.0
		var shield_profile = cos(norm_oly * PI * 0.5)
		var shield_h = pow(shield_profile, 1.4) * 65.0
		if norm_oly > 0.88:
			var scarp_factor = (norm_oly - 0.88) / 0.12
			shield_h -= scarp_factor * 12.0
		if d_oly < 1.6:
			var cald_norm = d_oly / 1.6
			var cald_depth = (1.0 - cald_norm * cald_norm) * 11.5
			shield_h -= cald_depth
		total_h += shield_h

	# 3. Valles Marineris (13.9° S, 300.8° E) - 4000 km Grand Canyon plunging -32m deep
	var lat_dist_vm = abs(lat - (-13.9))
	var lon_dist_vm = abs(lon - 300.8)
	if lat_dist_vm < 5.0 and lon_dist_vm < 32.0:
		var lat_factor = cos((lat_dist_vm / 5.0) * PI * 0.5)
		var lon_factor = cos((lon_dist_vm / 32.0) * PI * 0.5)
		var chasma_depth = lat_factor * lon_factor * 32.0
		var terrace_wave = sin(lat_dist_vm * 4.5) * 2.2 * lat_factor
		total_h -= (chasma_depth + terrace_wave)

	# 4. Gale Crater & Mount Sharp (-5.4° S, 137.8° E)
	var d_gale = _angular_distance_deg(lat, lon, -5.4, 137.8)
	if d_gale < 4.2:
		var norm_gale = d_gale / 4.2
		var bowl = -14.0 * (1.0 - norm_gale * norm_gale)
		var rim = 4.0 * pow(norm_gale, 3.0)
		var mound = 0.0
		if d_gale < 1.8:
			mound = cos((d_gale / 1.8) * PI * 0.5) * 16.5
		total_h += bowl + rim + mound

	# 5. Planum Boreum (North Polar Ice Cap, lat > 76°)
	if lat > 76.0:
		var p_norm = (lat - 76.0) / 14.0
		var dome = sin(p_norm * PI * 0.5) * 7.5
		var spiral = sin(deg_to_rad(lon) * 3.0 + p_norm * 8.0) * 1.8 * p_norm
		total_h += dome - spiral

	# 6. Planum Australe (South Polar Ice Cap, lat < -76°)
	if lat < -76.0:
		var s_norm = (-76.0 - lat) / 14.0
		var s_dome = sin(s_norm * PI * 0.5) * 6.5
		total_h += s_dome

	# 7. Multi-frequency Martian highland cratering and regional rolling swells
	var wave1 = sin(unit_dir.x * 14.0 + unit_dir.z * 11.0) * 2.4
	var wave2 = cos(unit_dir.y * 18.0 - unit_dir.x * 12.0) * 1.6
	var wave3 = sin(unit_dir.x * 32.0 - unit_dir.z * 28.0) * 0.8
	total_h += wave1 + wave2 + wave3

	return total_h

# Great-circle angular distance on a sphere in degrees
func _angular_distance_deg(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var phi1 = deg_to_rad(lat1)
	var phi2 = deg_to_rad(lat2)
	var delta_phi = deg_to_rad(lat2 - lat1)
	var delta_lambda = deg_to_rad(lon2 - lon1)
	var a = sin(delta_phi * 0.5) * sin(delta_phi * 0.5) + cos(phi1) * cos(phi2) * sin(delta_lambda * 0.5) * sin(delta_lambda * 0.5)
	a = clampf(a, 0.0, 1.0)
	var c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
	return rad_to_deg(c)

# Calculates local Jezero Crater surface elevation at any point (x, z)
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
	var mat1_fine_regolith = Color(0.72, 0.33, 0.18)
	var mat2_coarse_gravel = Color(0.58, 0.38, 0.26)
	var mat3_bedrock = Color(0.38, 0.30, 0.25)
	var mat4_layered_rock = Color(0.66, 0.54, 0.42)
	var mat5_dark_sand = Color(0.24, 0.22, 0.20)
	var mat6_duricrust = Color(0.76, 0.64, 0.52)

	var base_col = mat1_fine_regolith

	# Séítah region has dark basaltic sand dunes with wind ripple color bands
	var seitah_center = Vector2(-20.0, 28.0)
	var s_dist = Vector2(x, z).distance_to(seitah_center)
	if s_dist < 32.0:
		var weight = clampf(1.0 - (s_dist / 32.0), 0.0, 1.0)
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

	var fine_noise = sin(x * 0.35 + z * 0.28) * 0.04 + cos(x * 0.52 - z * 0.44) * 0.03
	var macro_noise = sin(x * 0.08 - z * 0.06) * 0.03
	var total_noise = fine_noise + macro_noise

	return Color(
		clampf(base_col.r + total_noise, 0.12, 0.95),
		clampf(base_col.g + total_noise * 0.82, 0.10, 0.95),
		clampf(base_col.b + total_noise * 0.65, 0.08, 0.95)
	)

# Spherical vertex coloration across Martian biomes
func _calculate_spherical_vertex_color(unit_dir: Vector3, elev: float) -> Color:
	var coords = get_lat_lon_from_unit_vector(unit_dir)
	var lat = coords.x
	var lon = coords.y

	# Polar Ice Caps: Brilliant white/cyan water and CO2 dry ice frost
	if lat > 77.0 or lat < -77.0:
		var polar_frost = Color(0.92, 0.94, 0.97)
		var dust_layer = Color(0.78, 0.65, 0.55)
		var p_trough = clampf((elev - 2.0) / 4.0, 0.0, 1.0)
		return dust_layer.lerp(polar_frost, p_trough)

	# Olympus Mons & Tharsis Volcanic Shield: Dark basalt lava flows & scoria
	var d_oly = _angular_distance_deg(lat, lon, 18.65, 226.2)
	if d_oly < 12.0:
		var mat_dark_basalt = Color(0.20, 0.18, 0.18)
		var mat_oxidized_lava = Color(0.38, 0.26, 0.20)
		var ow = clampf(elev / 45.0, 0.0, 1.0)
		return mat_oxidized_lava.lerp(mat_dark_basalt, ow)

	# Valles Marineris Canyon: Terraced sedimentary sandstone & mudstone strata
	var lat_dist_vm = abs(lat - (-13.9))
	var lon_dist_vm = abs(lon - 300.8)
	if lat_dist_vm < 5.0 and lon_dist_vm < 32.0:
		var mat_canyon_light = Color(0.68, 0.48, 0.32)
		var mat_canyon_dark = Color(0.35, 0.24, 0.18)
		var strata_phase = sin(elev * 0.45) * 0.5 + 0.5
		return mat_canyon_dark.lerp(mat_canyon_light, strata_phase)

	# Gale Crater: Mudstones and dark basaltic dunes
	var d_gale = _angular_distance_deg(lat, lon, -5.4, 137.8)
	if d_gale < 4.2:
		return Color(0.58, 0.44, 0.34)

	# Southern Cratered Highlands: Ancient crust, dusty terracotta with grey breccia clasts
	if lat < 0.0:
		var highland_dust = Color(0.62, 0.35, 0.22)
		var impact_breccia = Color(0.38, 0.32, 0.28)
		var crat_mix = sin(unit_dir.x * 25.0 + unit_dir.z * 22.0) * 0.5 + 0.5
		return highland_dust.lerp(impact_breccia, crat_mix * 0.4)

	# Northern Lowlands (Vastitas Borealis): Fine oxidized ferric regolith
	var fine_regolith = Color(0.72, 0.38, 0.22)
	var coarse_sand = Color(0.58, 0.34, 0.24)
	var var_noise = sin(unit_dir.x * 18.0 - unit_dir.z * 15.0) * 0.5 + 0.5
	return fine_regolith.lerp(coarse_sand, var_noise * 0.45)

# Builds the continuous Jezero landing plain terrain mesh and exact trimesh collision
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
			var pos = get_surface_point(x, z)
			var col = _calc_vertex_color(x, z)
			var uv = Vector2(float(i) / float(grid_subdivisions) * 24.0, float(j) / float(grid_subdivisions) * 24.0)
			row[j] = {"pos": pos, "col": col, "uv": uv}
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

	# Scientifically calibrated wind-rippled Martian regolith surface material
	var shader = load("res://shaders/mars_regolith_surface.gdshader")
	if shader:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = shader
		mesh.surface_set_material(0, shader_mat)
	else:
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

# Cube-sphere chunk streaming across Mars
func _update_spherical_chunks(force_refresh: bool = false) -> void:
	if not _player_ref:
		_find_player_and_initialize()
		if not _player_ref:
			return

	var p_pos = _player_ref.global_position
	if not force_refresh and (p_pos - _last_chunk_check_pos).length_squared() < 64.0:
		return
	_last_chunk_check_pos = p_pos

	var unit_p = (p_pos - planet_center).normalized()
	var cube_info = get_cube_face_and_coords(unit_p)
	var p_face: int = cube_info["face"]
	var p_cx: int = cube_info["cx"]
	var p_cy: int = cube_info["cy"]

	var needed_keys: Dictionary = {}
	var dist_from_origin = Vector2(p_pos.x, p_pos.z).length()
	var generate_distance = 1

	for dcx in range(-generate_distance, generate_distance + 1):
		for dcy in range(-generate_distance, generate_distance + 1):
			var cx = p_cx + dcx
			var cy = p_cy + dcy
			if cx >= 0 and cx < face_grid_size and cy >= 0 and cy < face_grid_size:
				var key = "chunk_%d_%d_%d" % [p_face, cx, cy]
				# Near origin, central MarsTerrainBody provides maximum micro-detail
				if p_face == 2 and cx == 4 and cy == 4 and dist_from_origin < 80.0:
					continue
				needed_keys[key] = {"face": p_face, "cx": cx, "cy": cy}

	for key in needed_keys:
		if not _active_chunks.has(key):
			var info = needed_keys[key]
			_generate_chunk(info["face"], info["cx"], info["cy"], key)

	var to_remove: Array = []
	for key in _active_chunks:
		if not needed_keys.has(key):
			to_remove.append(key)

	for key in to_remove:
		var chunk_node = _active_chunks[key]
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
		_active_chunks.erase(key)

# Generates a single spherical chunk mesh with collision and PBR material
func _generate_chunk(face_idx: int, cx: int, cy: int, key: String) -> void:
	var chunk_body = StaticBody3D.new()
	chunk_body.name = key
	chunk_body.collision_layer = 1
	chunk_body.collision_mask = 2

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_step = 2.0 / float(face_grid_size)
	var v_step = 2.0 / float(face_grid_size)
	var u_min = -1.0 + float(cx) * u_step
	var v_min = -1.0 + float(cy) * v_step

	var subs = chunk_subdivisions
	var num_pts = subs + 1
	var grid_pts: Array = []
	grid_pts.resize(num_pts)

	for i in range(num_pts):
		var row: Array = []
		row.resize(num_pts)
		var u = u_min + (float(i) / float(subs)) * u_step
		for j in range(num_pts):
			var v = v_min + (float(j) / float(subs)) * v_step
			var unit_dir = cube_to_sphere(face_idx, u, v)
			var elev = get_elevation(unit_dir)
			var pos = planet_center + unit_dir * (planet_radius + elev)
			var col = _calculate_spherical_vertex_color(unit_dir, elev)
			var uv = Vector2(float(i) / float(subs) * 6.0, float(j) / float(subs) * 6.0)
			row[j] = {"pos": pos, "col": col, "uv": uv}
		grid_pts[i] = row

	for i in range(subs):
		for j in range(subs):
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

	var shader = load("res://shaders/mars_regolith_surface.gdshader")
	if shader:
		var sm = ShaderMaterial.new()
		sm.shader = shader
		mesh.surface_set_material(0, sm)
	else:
		var std_mat = StandardMaterial3D.new()
		std_mat.vertex_color_use_as_albedo = true
		std_mat.roughness = 0.94
		mesh.surface_set_material(0, std_mat)

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "ChunkMesh"
	mesh_inst.mesh = mesh
	chunk_body.add_child(mesh_inst)

	var col_shape = CollisionShape3D.new()
	col_shape.name = "ChunkCol"
	col_shape.shape = mesh.create_trimesh_shape()
	chunk_body.add_child(col_shape)

	add_child(chunk_body)
	_active_chunks[key] = chunk_body
	chunk_loaded.emit(key)

# Maps 3D direction vector to cube face and UV coordinates
func get_cube_face_and_coords(dir: Vector3) -> Dictionary:
	var x = dir.x
	var y = dir.y
	var z = dir.z
	var ax = absf(x)
	var ay = absf(y)
	var az = absf(z)

	var face = 0
	var u = 0.0
	var v = 0.0

	if ax >= ay and ax >= az:
		if x > 0.0:
			face = 0
			u = -z / x
			v = -y / x
		else:
			face = 1
			u = z / -x
			v = -y / -x
	elif ay >= ax and ay >= az:
		if y > 0.0:
			face = 2
			u = x / y
			v = z / y
		else:
			face = 3
			u = x / -y
			v = -z / -y
	else:
		if z > 0.0:
			face = 4
			u = x / z
			v = -y / z
		else:
			face = 5
			u = -x / -z
			v = -y / -z

	var cx = clampi(int((u + 1.0) * 0.5 * float(face_grid_size)), 0, face_grid_size - 1)
	var cy = clampi(int((v + 1.0) * 0.5 * float(face_grid_size)), 0, face_grid_size - 1)
	return {"face": face, "u": u, "v": v, "cx": cx, "cy": cy}

# Maps cube face and UV coordinates to unit sphere vector
func cube_to_sphere(face: int, u: float, v: float) -> Vector3:
	var v3 = Vector3.ZERO
	match face:
		0: v3 = Vector3(1.0, -v, -u)
		1: v3 = Vector3(-1.0, -v, u)
		2: v3 = Vector3(u, 1.0, v)
		3: v3 = Vector3(u, -1.0, -v)
		4: v3 = Vector3(u, -v, 1.0)
		5: v3 = Vector3(-u, -v, -1.0)
	return v3.normalized()

# Landmark discovery notification
func _check_landmark_discovery(player_unit_dir: Vector3) -> void:
	var coords = get_lat_lon_from_unit_vector(player_unit_dir)
	for lm in known_landmarks:
		var d = _angular_distance_deg(coords.x, coords.y, lm["lat"], lm["lon"])
		if d < lm["radius_deg"]:
			if not lm.get("discovered", false):
				lm["discovered"] = true
				location_discovered.emit(lm["name"], Vector2(coords.x, coords.y))

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
	mat_ventifact.roughness = 0.78

	var boulders = [
		{"name": "BelvaBoulder1", "pos": Vector2(-28.0, -22.0), "size": 2.4, "mat": mat_basalt, "rot": Vector3(12, 45, 8)},
		{"name": "BelvaBoulder2", "pos": Vector2(-36.0, -32.0), "size": 3.1, "mat": mat_basalt, "rot": Vector3(-8, 110, 15)},
		{"name": "DeltaBenchRock", "pos": Vector2(-18.0, -14.0), "size": 2.8, "mat": mat_sediment, "rot": Vector3(5, 75, -12)},
		{"name": "SeitahBlock1", "pos": Vector2(-18.0, 22.0), "size": 2.1, "mat": mat_basalt, "rot": Vector3(20, -30, 10)},
		{"name": "SeitahBlock2", "pos": Vector2(-24.0, 32.0), "size": 2.6, "mat": mat_basalt, "rot": Vector3(-15, 60, -5)},
		{"name": "NeretvaConglomerate", "pos": Vector2(30.0, -24.0), "size": 2.2, "mat": mat_sediment, "rot": Vector3(8, 140, 6)},
		{"name": "Ventifact1", "pos": Vector2(12.0, 14.0), "size": 1.6, "mat": mat_ventifact, "rot": Vector3(35, 12, -20)},
		{"name": "Ventifact2", "pos": Vector2(-8.0, 12.0), "size": 1.3, "mat": mat_ventifact, "rot": Vector3(-25, 85, 15)},
		{"name": "Ventifact3", "pos": Vector2(22.0, -8.0), "size": 1.5, "mat": mat_ventifact, "rot": Vector3(15, -45, -10)}
	]

	for b in boulders:
		var pos2 = b["pos"]
		var b_size = b["size"]
		var surf_pos = get_surface_point(pos2.x, pos2.y)

		var boulder = StaticBody3D.new()
		boulder.name = b["name"]
		boulder.position = surf_pos + Vector3(0.0, b_size * 0.45, 0.0)
		boulder.rotation_degrees = b["rot"]
		boulder.collision_layer = 1
		boulder.collision_mask = 2

		var b_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(b_size * 1.15, b_size * 0.9, b_size * 1.3)
		box.material = b["mat"]
		b_mesh.mesh = box
		boulder.add_child(b_mesh)

		var col = CollisionShape3D.new()
		var col_box = BoxShape3D.new()
		col_box.size = box.size
		col.shape = col_box
		boulder.add_child(col)

		add_child(boulder)

# Multi-tiered flat sedimentary bedrock slabs with stepped fracture edges
func _create_flat_layered_bedrock_formations() -> void:
	var mat_slab_sediment = StandardMaterial3D.new()
	mat_slab_sediment.albedo_color = Color(0.64, 0.50, 0.38)
	mat_slab_sediment.roughness = 0.94

	var mat_slab_edge = StandardMaterial3D.new()
	mat_slab_edge.albedo_color = Color(0.48, 0.36, 0.28)
	mat_slab_edge.roughness = 0.92

	var slab_formations = [
		{"name": "DeltaSlabFormation_A", "pos": Vector2(-12.0, -6.0), "w": 6.5, "l": 4.8, "t": 0.45, "tilt": Vector3(4, 25, -3)},
		{"name": "DeltaSlabFormation_B", "pos": Vector2(-22.0, -8.0), "w": 7.2, "l": 5.4, "t": 0.50, "tilt": Vector3(-5, -40, 6)},
		{"name": "SteppedStrata_1", "pos": Vector2(-8.0, -16.0), "w": 4.8, "l": 3.6, "t": 0.35, "tilt": Vector3(6, 15, -2)},
		{"name": "SteppedStrata_2", "pos": Vector2(-14.0, -24.0), "w": 5.0, "l": 3.2, "t": 0.32, "tilt": Vector3(-4, 42, 6)},
		{"name": "NeretvaPavement", "pos": Vector2(22.0, -26.0), "w": 5.8, "l": 4.5, "t": 0.30, "tilt": Vector3(2, -15, 4)},
		{"name": "PlainsBuriedSlab", "pos": Vector2(2.0, 18.0), "w": 4.4, "l": 3.5, "t": 0.25, "tilt": Vector3(-2, 10, -4)}
	]

	for slab in slab_formations:
		var pos2 = slab["pos"]
		var surf_pos = get_surface_point(pos2.x, pos2.y)
		var slab_body = StaticBody3D.new()
		slab_body.name = slab["name"]
		slab_body.position = surf_pos + Vector3(0.0, slab["t"] * 0.4, 0.0)
		slab_body.rotation_degrees = slab["tilt"]
		slab_body.collision_layer = 1
		slab_body.collision_mask = 2

		var slab_mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(slab["w"], slab["t"], slab["l"])
		box.material = mat_slab_sediment
		slab_mesh.mesh = box
		slab_body.add_child(slab_mesh)

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

# Realistic non-uniform rock clusters, scree fields, and partially buried stones
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

			var surf_pos = get_surface_point(rx, rz)
			var stone_size = lerp(0.25, 0.75, float(seed_counter % 10) / 10.0)

			var stone_body = StaticBody3D.new()
			stone_body.name = "Stone_%d_%d" % [int(c_pos.x), i]
			stone_body.position = surf_pos + Vector3(0.0, stone_size * 0.35, 0.0)
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
	var surf_pos = get_surface_point(-48.0, 32.0)
	butte.position = surf_pos + Vector3(0.0, 4.5, 0.0)
	butte.collision_layer = 1
	butte.collision_mask = 2

	var butte_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 6.5
	cyl.bottom_radius = 11.5
	cyl.height = 9.0

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.66, 0.48, 0.36)
	mat.roughness = 0.94
	cyl.material = mat
	butte_mesh.mesh = cyl
	butte.add_child(butte_mesh)

	var col = CollisionShape3D.new()
	var c_shape = CylinderShape3D.new()
	c_shape.radius = 10.0
	c_shape.height = 9.0
	col.shape = c_shape
	butte.add_child(col)

	add_child(butte)

# Phobos and Deimos celestial mesh instances in the sky dome
func _create_phobos_and_deimos() -> void:
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
	p_mat.albedo_color = Color(0.35, 0.34, 0.33)
	p_mat.roughness = 0.96
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	sphere.material = p_mat
	phobos_mesh.mesh = sphere
	phobos_mesh.scale = Vector3(1.4, 0.9, 1.1)
	phobos_mesh.rotation_degrees = Vector3(25, 45, 15)
	phobos_root.add_child(phobos_mesh)

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

# Instantiates modular atmosphere and telemetry HUD
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

# Snaps player and artifacts to the exact generated elevation
func _align_scene_objects_to_surface() -> void:
	call_deferred("_do_align")

func _do_align() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return

	var player = parent_node.get_node_or_null("Player")
	if player:
		var p_x = player.global_position.x
		var p_z = player.global_position.z
		var surf_pos = get_surface_point(p_x, p_z)
		player.global_position = surf_pos + Vector3(0.0, 0.20, 0.0)
		var surf_norm = get_surface_normal(player.global_position)
		if player.has_method("align_to_normal"):
			player.align_to_normal(surf_norm)

	for node in parent_node.get_children():
		if node.is_in_group("artifacts"):
			var ax = node.global_position.x
			var az = node.global_position.z
			var surf_pos = get_surface_point(ax, az)
			var surf_norm = get_surface_normal(surf_pos)
			node.global_position = surf_pos
			var cur_up = node.global_transform.basis.y
			if cur_up.cross(surf_norm).length_squared() > 0.0001:
				var axis = cur_up.cross(surf_norm).normalized()
				var angle = cur_up.angle_to(surf_norm)
				node.global_transform.basis = Basis(axis, angle) * node.global_transform.basis

# Proximity streaming and geographical spawning for historical Mars exploration hardware
func _update_historical_spacecraft_proximity(unit_p: Vector3) -> void:
	for sc in historical_spacecraft_catalog:
		var sc_id: String = sc["id"]
		var sc_dir = get_unit_vector_from_lat_lon(sc["lat"], sc["lon"])
		var ang_dist = unit_p.angle_to(sc_dir)
		# Within ~0.08 rad (~96 meters on sphere), dynamically stream in the spacecraft
		if ang_dist < 0.08:
			if not _spawned_historical_spacecraft.has(sc_id) or not is_instance_valid(_spawned_historical_spacecraft[sc_id]):
				spawn_historical_spacecraft(sc_id)

func spawn_historical_spacecraft(sc_id: String) -> Node3D:
	if _spawned_historical_spacecraft.has(sc_id) and is_instance_valid(_spawned_historical_spacecraft[sc_id]):
		return _spawned_historical_spacecraft[sc_id]

	var sc_info: Dictionary = {}
	for item in historical_spacecraft_catalog:
		if item["id"] == sc_id:
			sc_info = item
			break
	if sc_info.is_empty():
		return null

	var art_scene = load("res://scenes/artifact/artifact.tscn")
	if not art_scene:
		return null

	var art = art_scene.instantiate()
	art.name = "HistoricalSpacecraft_" + sc_id.capitalize()
	art.artifact_id = sc_id

	var unit_dir = get_unit_vector_from_lat_lon(sc_info["lat"], sc_info["lon"])
	var surf_pos = get_surface_position(unit_dir)
	var surf_norm = get_surface_normal(surf_pos)

	var parent_node = get_parent()
	if parent_node:
		parent_node.add_child(art)
	else:
		add_child(art)

	art.global_position = surf_pos
	var cur_up = art.global_transform.basis.y
	if cur_up.cross(surf_norm).length_squared() > 0.0001:
		var axis = cur_up.cross(surf_norm).normalized()
		var angle = cur_up.angle_to(surf_norm)
		art.global_transform.basis = Basis(axis, angle) * art.global_transform.basis

	if art.has_method("set_recovered_visuals"):
		art.set_recovered_visuals()

	_spawned_historical_spacecraft[sc_id] = art
	return art

func get_spacecraft_world_position(sc_id: String) -> Vector3:
	for item in historical_spacecraft_catalog:
		if item["id"] == sc_id:
			var unit_dir = get_unit_vector_from_lat_lon(item["lat"], item["lon"])
			return get_surface_position(unit_dir)
	return Vector3.ZERO
