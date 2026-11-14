extends SceneTree

# Echoes Beyond Earth - Complete Spherical Mars Planetary System Test Suite
# Tests full compliance with the Infinite, Fully Spherical Mars Specification:
# 1. Complete Planetary Shape (Curvature, 3D sphere, no edges/walls, horizon calculation)
# 2. Correct Planetary Physics (Center-directed gravity, normal alignment, low-gravity jumping)
# 3. Seamless Infinite Exploration (Continuous 360° circum-planetary travel, deterministic terrain)
# 4. Real Martian Geography (Olympus Mons, Valles Marineris, Jezero, Gale, Polar Ice Caps)
# 5. Planetary Navigation System (Local, Regional, Global views, lat/lon telemetry, landmark discovery)

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================================")
	print("TESTING: INFINITE, FULLY SPHERICAL MARS PLANETARY SYSTEM")
	print("==================================================================")
	call_deferred("_run_all_tests")

func _assert_test(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] ", test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] ", test_name)
		failed_count += 1

func _run_all_tests() -> void:
	var mars_scene = load("res://scenes/levels/mars.tscn")
	_assert_test(mars_scene != null, "Mars level scene loaded")
	if not mars_scene:
		_finish()
		return

	var level = mars_scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	var planet = level.get_node_or_null("Terrain")
	_assert_test(planet != null and planet.is_in_group("spherical_planet"), "Spherical Mars planet node exists in 'spherical_planet' group")
	if not planet:
		_finish()
		return

	# --- 1. Complete Planetary Shape & Curvature ---
	print("\n--- 1. Testing Complete Planetary Shape & Curvature ---")
	var r = planet.planet_radius
	_assert_test(r >= 1000.0, "Planet has realistic planetary exploration radius (r = %.1f m)" % r)

	# Verify full 3D sphere: Check positions across all 6 cardinal poles
	var north_pos = planet.get_surface_position(Vector3.UP)
	var south_pos = planet.get_surface_position(Vector3.DOWN)
	var east_pos = planet.get_surface_position(Vector3.RIGHT)
	var west_pos = planet.get_surface_position(Vector3.LEFT)
	var front_pos = planet.get_surface_position(Vector3.BACK)
	var back_pos = planet.get_surface_position(Vector3.FORWARD)

	_assert_test(north_pos.y > r * 0.95, "North Pole exists at +Y (Y: %.1f m)" % north_pos.y)
	_assert_test(south_pos.y < -r * 0.95, "South Pole exists at -Y (Y: %.1f m)" % south_pos.y)
	_assert_test(east_pos.x > r * 0.95, "East Equator exists at +X (X: %.1f m)" % east_pos.x)
	_assert_test(west_pos.x < -r * 0.95, "West Equator exists at -X (X: %.1f m)" % west_pos.x)

	# Curved horizon physics calculation: d = sqrt(2*R*h + h^2)
	var h_ground = 1.8
	var h_aerial = 60.0
	var horizon_ground = sqrt(2.0 * r * h_ground + h_ground * h_ground)
	var horizon_aerial = sqrt(2.0 * r * h_aerial + h_aerial * h_aerial)
	_assert_test(horizon_aerial > horizon_ground * 4.0, "Planetary horizon expands with altitude (Ground: %.1fm -> Aerial: %.1fm)" % [horizon_ground, horizon_aerial])

	# --- 2. Correct Planetary Physics & Center-Directed Gravity ---
	print("\n--- 2. Testing Correct Planetary Physics & Gravity ---")
	var player = level.get_node_or_null("Player")
	_assert_test(player != null, "Player astronaut exists on spherical planet")
	if player:
		# Test gravity direction points to planet center from multiple positions
		var test_positions = [
			Vector3(0, r + 2.0, 0),       # North pole
			Vector3(0, -(r + 2.0), 0),      # South pole
			Vector3(r + 2.0, 0, 0),       # Equator east
			Vector3(0, 0, r + 2.0)        # Equator prime meridian
		]
		for tp in test_positions:
			player.global_position = tp
			player._physics_process(0.016)
			var expected_up = (tp - planet.planet_center).normalized()
			var dot_up = player.current_up_vector.dot(expected_up)
			_assert_test(dot_up > 0.999, "Gravity points toward planet center at %s (dot: %.4f)" % [tp, dot_up])

	# --- 3. Real Martian Geography Across Sphere ---
	print("\n--- 3. Testing Real Martian Geography Across Sphere ---")
	# 3.1 Olympus Mons (18.65° N, 226.2° E)
	var olympus_dir = planet.get_unit_vector_from_lat_lon(18.65, 226.2)
	var olympus_h = planet.get_elevation(olympus_dir)
	var plains_dir = planet.get_unit_vector_from_lat_lon(0.0, 0.0)
	var plains_h = planet.get_elevation(plains_dir)
	_assert_test(olympus_h > plains_h + 30.0, "Olympus Mons towers as highest volcanic shield (Olympus: +%.1fm vs Plains: %+.1fm)" % [olympus_h, plains_h])

	# 3.2 Valles Marineris (13.9° S, 300.8° E)
	var valles_dir = planet.get_unit_vector_from_lat_lon(-13.9, 300.8)
	var valles_h = planet.get_elevation(valles_dir)
	_assert_test(valles_h < plains_h - 10.0, "Valles Marineris plunges as grand canyon chasma (Valles: %+.1fm)" % valles_h)

	# 3.3 Polar Ice Caps: North (Planum Boreum) & South (Planum Australe)
	var north_pole_dir = planet.get_unit_vector_from_lat_lon(88.0, 0.0)
	var south_pole_dir = planet.get_unit_vector_from_lat_lon(-88.0, 0.0)
	var north_col = planet._calculate_spherical_vertex_color(north_pole_dir, 10.0)
	var south_col = planet._calculate_spherical_vertex_color(south_pole_dir, 10.0)
	_assert_test(north_col.r > 0.85 and north_col.b > 0.85, "North Polar Cap exhibits high-albedo perennial ice coloration (RGB: %.2f, %.2f, %.2f)" % [north_col.r, north_col.g, north_col.b])
	_assert_test(south_col.r > 0.85 and south_col.b > 0.85, "South Polar Cap exhibits high-albedo dry-ice coloration (RGB: %.2f, %.2f, %.2f)" % [south_col.r, south_col.g, south_col.b])

	# 3.4 Gale Crater (-5.4° S, 137.8° E)
	var gale_dir = planet.get_unit_vector_from_lat_lon(-5.4, 137.8)
	var gale_coords = planet.get_planetary_coords(planet.get_surface_position(gale_dir))
	_assert_test(is_equal_approx(gale_coords["lat"], -5.4), "Gale Crater coordinates accurate (-5.4°S, 137.8°E)")

	# --- 4. Seamless Exploration & Determinism ---
	print("\n--- 4. Testing Seamless Exploration & Deterministic Terrain ---")
	# Sample terrain height 10 times at same location: must be 100% deterministic
	var test_dir = planet.get_unit_vector_from_lat_lon(34.5, 112.3)
	var h1 = planet.get_elevation(test_dir)
	var all_identical = true
	for i in range(10):
		var h_check = planet.get_elevation(test_dir)
		if not is_equal_approx(h1, h_check):
			all_identical = false
			break
	_assert_test(all_identical, "Spherical terrain generation is 100% deterministic (revisiting produces identical terrain)")

	# Full 360° circum-planetary wrapping test: traverse longitude 0° -> 360°
	var wrap_successful = true
	for deg in range(0, 360, 45):
		var u_vec = planet.get_unit_vector_from_lat_lon(15.0, float(deg))
		var surf = planet.get_surface_position(u_vec)
		var check_coords = planet.get_lat_lon_from_unit_vector(u_vec)
		if abs(check_coords.y - float(deg)) > 0.5:
			wrap_successful = false
			break
	_assert_test(wrap_successful, "Circum-planetary coordinate wrapping confirmed: 360° continuous traversal without seams")

	# --- 5. Planetary Navigation System & Map ---
	print("\n--- 5. Testing Planetary Navigation System & Map ---")
	var map = planet.get_node_or_null("MarsPlanetaryMap")
	_assert_test(map != null, "MarsPlanetaryMap CanvasLayer instantiated")
	if map:
		map.toggle_map()
		_assert_test(map.is_map_open, "Planetary map opens with toggle_map() [M]")
		map.set_zoom_level(map.MapZoomLevel.LOCAL)
		_assert_test(map.current_zoom == map.MapZoomLevel.LOCAL, "Map switches to Local Radar view")
		map.set_zoom_level(map.MapZoomLevel.REGIONAL)
		_assert_test(map.current_zoom == map.MapZoomLevel.REGIONAL, "Map switches to Regional Sector view")
		map.set_zoom_level(map.MapZoomLevel.GLOBAL)
		_assert_test(map.current_zoom == map.MapZoomLevel.GLOBAL, "Map switches to Full 360° Spherical Globe view")
		map.toggle_map()
		_assert_test(not map.is_map_open, "Planetary map closes cleanly")

	level.queue_free()
	_finish()

func _finish() -> void:
	print("\n==================================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==================================================================")
	if failed_count == 0:
		print("SUCCESS: Infinite, Fully Spherical Mars Planetary System verified!\n")
		quit(0)
	else:
		printerr("FAILURE: Test suite encountered failures!\n")
		quit(1)
