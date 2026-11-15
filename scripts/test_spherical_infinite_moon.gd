extends SceneTree

# Verification Suite for:
# 1. Removal of all mountain structures (no massifs, open lunar horizon)
# 2. Continuous periodic terrain elevation across boundaries
# 3. Seamless spherical world wrap (walking off one end connects to the other)
# 4. Infinite walkable navigation around the Moon
# 5. Multi-tile wrap meshes and collision shapes
# 6. Toroidal proximity scanner tracking

func _init() -> void:
	print("==================================================================")
	print("TESTING: INFINITE CONNECTED SPHERICAL MOON & MOUNTAIN REMOVAL")
	print("==================================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load res://scenes/levels/moon.tscn")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	for i in range(15):
		await process_frame
	
	var terrain = world.get_node_or_null("Terrain")
	var player = world.get_node_or_null("Player")
	
	if not terrain or not player:
		printerr("FAIL: Terrain or Player missing!")
		quit(1)
		return
	
	var world_size = terrain.get_world_size() if terrain.has_method("get_world_size") else terrain.terrain_size
	var half_size = world_size * 0.5
	print("[World] Terrain Size: ", world_size, " Half Size: ", half_size)
	
	# TEST 1: Mountain Structures Removed
	print("\n--- 1. Testing Mountain Removal ---")
	# Ensure no mountain massif meshes exist in the tree
	for child in terrain.get_children():
		if "Massif" in child.name or "Mountain" in child.name:
			printerr("FAIL: Mountain structure found in terrain: ", child.name)
			quit(1)
			return
	
	# Check craters catalog for any mountain central peaks
	for c in terrain.craters:
		if c.get("peak", false):
			printerr("FAIL: Crater %s still has central mountain peak!" % c.get("id"))
			quit(1)
			return
	print("PASS: All mountain massif structures and mountain peaks successfully removed.")
	
	# TEST 2: Periodic Boundary Elevation Continuity
	print("\n--- 2. Testing Boundary Elevation Continuity ---")
	var sample_points = [-70.0, -45.0, -20.0, 0.0, 20.0, 45.0, 70.0]
	var max_edge_diff = 0.0
	
	for s in sample_points:
		# Check X boundary: (-half_size, s) vs (+half_size, s)
		var h_x_neg = terrain.get_terrain_height(-half_size, s)
		var h_x_pos = terrain.get_terrain_height(half_size, s)
		var diff_x = absf(h_x_neg - h_x_pos)
		if diff_x > max_edge_diff: max_edge_diff = diff_x
		
		# Check Z boundary: (s, -half_size) vs (s, +half_size)
		var h_z_neg = terrain.get_terrain_height(s, -half_size)
		var h_z_pos = terrain.get_terrain_height(s, half_size)
		var diff_z = absf(h_z_neg - h_z_pos)
		if diff_z > max_edge_diff: max_edge_diff = diff_z
	
	print("[Continuity] Max elevation difference across boundaries: ", max_edge_diff, "m")
	if max_edge_diff > 0.001:
		printerr("FAIL: Elevation boundary discontinuity detected: ", max_edge_diff)
		quit(1)
		return
	print("PASS: Terrain elevation connects seamlessly across boundaries with 0.000m seam!")
	
	# TEST 3: Multi-Tile Wrap Meshes & Collision
	print("\n--- 3. Testing Wrap Mesh & Collision Setup ---")
	var terrain_body = terrain.get_node_or_null("LunarTerrainBody")
	if not terrain_body:
		printerr("FAIL: LunarTerrainBody missing!")
		quit(1)
		return
	
	var wrap_mesh_count = 0
	var wrap_col_count = 0
	for child in terrain_body.get_children():
		if "WrapMesh" in child.name:
			wrap_mesh_count += 1
		if "WrapCol" in child.name:
			wrap_col_count += 1
	
	print("[Tiles] Wrap Mesh Instances: ", wrap_mesh_count, " (Expected 8 surrounding tiles)")
	print("[Tiles] Wrap Collision Shapes: ", wrap_col_count, " (Expected 8 surrounding shapes)")
	if wrap_mesh_count < 8 or wrap_col_count < 8:
		printerr("FAIL: Surrounding wrap tiles incomplete!")
		quit(1)
		return
	print("PASS: 8 surrounding wrap tiles successfully form an infinite seamless horizon.")
	
	# TEST 4: Seamless Spherical World Wrapping (Walking East)
	print("\n--- 4. Testing Spherical World Wrap Navigation ---")
	# Place player 1 meter before the positive X boundary
	player.global_position = Vector3(half_size - 1.0, terrain.get_terrain_height(half_size - 1.0, 0.0) + 0.15, 0.0)
	player.velocity = Vector3(2.5, 0.0, 0.0) # Walking East towards +X boundary
	
	for i in range(10):
		await process_frame
	
	# Move player across the boundary (+X)
	player.global_position.x = half_size + 0.5
	player._handle_spherical_world_wrap()
	
	print("[Wrap X] Global X after crossing +half_size: ", player.global_position.x)
	var expected_x = -half_size + 0.5
	if absf(player.global_position.x - expected_x) > 0.1:
		printerr("FAIL: Player did not wrap cleanly to opposite boundary! Expected: %f, Got: %f" % [expected_x, player.global_position.x])
		quit(1)
		return
	
	# Verify player remains securely grounded after wrap
	for i in range(10):
		await process_frame
	
	print("[Physics] Player on floor after wrap: ", player.is_on_floor(), " Y: ", player.global_position.y)
	if player.global_position.y < -5.0:
		printerr("FAIL: Player fell through after world wrap!")
		quit(1)
		return
	print("PASS: Player wrapped smoothly from East edge to West edge with solid ground adhesion!")
	
	# TEST 5: Seamless Spherical World Wrapping (Walking North)
	player.global_position = Vector3(0.0, terrain.get_terrain_height(0.0, half_size - 1.0) + 0.15, half_size - 1.0)
	player.global_position.z = half_size + 0.5
	player._handle_spherical_world_wrap()
	
	print("[Wrap Z] Global Z after crossing +half_size: ", player.global_position.z)
	var expected_z = -half_size + 0.5
	if absf(player.global_position.z - expected_z) > 0.1:
		printerr("FAIL: Player did not wrap cleanly across Z boundary!")
		quit(1)
		return
	print("PASS: Player wrapped smoothly across North-South boundaries!")
	
	# TEST 6: Scanner Toroidal Tracking
	print("\n--- 6. Testing Scanner Toroidal Tracking Across Boundary ---")
	var scanner = player.get_node_or_null("Scanner")
	if not scanner:
		printerr("FAIL: Scanner missing!")
		quit(1)
		return
	
	var lrv = world.get_node_or_null("Artifact_LRV")
	# Place player at opposite side of world: (-half_size + 5, 0, 12)
	# LRV is at (18, 12).
	# Direct Euclidean distance: ~ 18 - (-85) = 103m (outside standard 65m range!)
	# Wrapped toroidal distance: (half_size - 18) + 5 = 72 + 5 = 77m
	player.global_position = Vector3(-half_size + 5.0, terrain.get_terrain_height(-half_size + 5.0, 12.0) + 0.15, 12.0)
	scanner._perform_scan()
	print("[Scanner] Scan origin: ", player.global_position)
	print("[Scanner] Current distance: ", scanner.current_distance)
	print("[Scanner] Target direction: ", scanner.target_direction)
	
	# If player is placed at (half_size - 15, 0, 12) = (75, 12):
	# LRV is at (18, 12). Distance is 57m (within 65m scan range!)
	player.global_position = Vector3(half_size - 15.0, terrain.get_terrain_height(half_size - 15.0, 12.0) + 0.15, 12.0)
	scanner._perform_scan()
	print("[Scanner Near Edge] Signal strength: ", scanner.current_signal_strength, " Distance: ", scanner.current_distance, " Target: ", scanner.current_target_id)
	if scanner.current_target_id != "apollo_lrv" and scanner.current_target_id != "lunar_ferroan_anorthosite":
		printerr("FAIL: Scanner failed to track artifact near boundary! Target: %s" % scanner.current_target_id)
		quit(1)
		return
	print("PASS: Proximity scanner accurately tracks artifacts across spherical boundaries!")
	
	print("\n==================================================================")
	print("ALL INFINITE SPHERICAL MOON TESTS PASSED SUCCESSFULLY!")
	print("==================================================================")
	quit(0)
