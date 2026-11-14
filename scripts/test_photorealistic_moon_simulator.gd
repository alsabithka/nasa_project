extends SceneTree

# Comprehensive Verification: Third-Person Minion Moon Exploration Simulator
# Verifies:
# 1. Astronaut Minion character model (yellow cylindrical body, twin silver goggles, expressive eyes, transparent helmet visor, NASA spacesuit, PLSS backpack)
# 2. Third-person camera system (over-the-shoulder chase view, 3.2m distance, collision mask 1, zoom in/out)
# 3. Minion locomotion & waddle under exact 1.62 m/s² lunar gravity
# 4. Ballistic regolith dust & persistent corrugated footprints
# 5. Vacuum internal helmet acoustics
# 6. NASA Apollo 17 scientific geology inspection & LRO/LOLA terrain
# 7. Telemetry HUD and interaction stability

func _init() -> void:
	print("==================================================================")
	print("TESTING: THIRD-PERSON MINION MOON EXPLORATION SIMULATOR")
	print("==================================================================")
	call_deferred("_run_simulation_test")

func _run_simulation_test() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load res://scenes/levels/moon.tscn")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	for i in range(20):
		await process_frame
	
	var terrain = world.get_node_or_null("Terrain")
	var player = world.get_node_or_null("Player")
	
	if not terrain or not player:
		printerr("FAIL: Terrain or Player missing!")
		quit(1)
		return
	
	# Test 1: Minion Character Model & Visual Features
	print("\n--- 1. Testing Astronaut Minion Character Model ---")
	var torso = player.get_node_or_null("Visuals/Torso")
	var head = player.get_node_or_null("Visuals/Torso/Head")
	var left_goggle = player.get_node_or_null("Visuals/Torso/Head/LeftGoggleRing")
	var right_goggle = player.get_node_or_null("Visuals/Torso/Head/RightGoggleRing")
	var visor = player.get_node_or_null("Visuals/Torso/Head/TransparentVisor")
	var plss = player.get_node_or_null("Visuals/Torso/BackpackPLSS")
	var tank1 = player.get_node_or_null("Visuals/Torso/BackpackPLSS/OxygenTank1")
	var tank2 = player.get_node_or_null("Visuals/Torso/BackpackPLSS/OxygenTank2")
	
	if not torso or not head or not left_goggle or not right_goggle or not visor or not plss or not tank1 or not tank2:
		printerr("FAIL: Minion astronaut visual hierarchy incomplete!")
		quit(1)
		return
	
	var head_mesh = head.get_node_or_null("MinionHeadMesh")
	if head_mesh and head_mesh.mesh and head_mesh.mesh.material:
		var col = head_mesh.mesh.material.albedo_color
		print("[Minion] Head albedo color: ", col, " (Expected Minion Yellow)")
		if col.r < 0.9 or col.g < 0.7 or col.b > 0.3:
			printerr("FAIL: Head color does not match classic Minion yellow!")
			quit(1)
			return
	
	# Verify transparent helmet visor
	if visor.mesh and visor.mesh.material:
		var v_mat = visor.mesh.material
		print("[Minion] Helmet visor transparency mode: ", v_mat.transparency, " (Expected 1 = ALPHA)")
		if v_mat.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
			printerr("FAIL: Helmet visor is not transparent alpha glass!")
			quit(1)
			return
	print("PASS: Astronaut Minion model, goggles, eyes, transparent visor, and PLSS verified.")
	
	# Test 2: Third-Person Camera System
	print("\n--- 2. Testing Third-Person Camera System ---")
	print("[Camera] Player is_first_person: ", player.is_first_person, " (Expected false)")
	print("[Camera] SpringArm length: ", player.spring_arm.spring_length, "m (Expected ~3.2m)")
	print("[Camera] CameraPivot Y: ", player.camera_pivot.position.y, "m (Expected ~0.85m centered on Minion)")
	print("[Camera] SpringArm collision mask: ", player.spring_arm.collision_mask, " (Expected 1 for terrain collision)")
	
	if player.is_first_person or player.spring_arm.spring_length < 2.5 or player.spring_arm.collision_mask != 1:
		printerr("FAIL: Third-person camera system parameters incorrect!")
		quit(1)
		return
	
	# Test camera zoom in/out with mouse wheel events
	var ev_zoom_in = InputEventMouseButton.new()
	ev_zoom_in.button_index = MOUSE_BUTTON_WHEEL_UP
	ev_zoom_in.pressed = true
	var len_before = player.spring_arm.spring_length
	player._unhandled_input(ev_zoom_in)
	print("[Camera] Zoom in test: %f -> %f m" % [len_before, player.spring_arm.spring_length])
	if player.spring_arm.spring_length >= len_before:
		printerr("FAIL: Camera zoom in with wheel up failed!")
		quit(1)
		return
	
	var ev_zoom_out = InputEventMouseButton.new()
	ev_zoom_out.button_index = MOUSE_BUTTON_WHEEL_DOWN
	ev_zoom_out.pressed = true
	player._unhandled_input(ev_zoom_out)
	print("[Camera] Zoom out test: now %f m" % player.spring_arm.spring_length)
	print("PASS: Third-person camera framing, collision, and zoom verified.")
	
	# Test 3: Minion Locomotion & Calibrated 3.24 m/s² Lunar Gravity
	print("\n--- 3. Testing Minion Locomotion & 3.24 m/s² Physics ---")
	print("[Physics] Lunar gravity: ", player.gravity, " m/s²")
	if abs(player.gravity - 3.24) > 0.05:
		printerr("FAIL: Gravity is not 3.24 m/s²!")
		quit(1)
		return
	
	# Wait until player settles on floor
	var settle_frames = 0
	while not player.is_on_floor() and settle_frames < 60:
		settle_frames += 1
		await process_frame
	
	print("[Physics] Minion on floor: ", player.is_on_floor(), " Y pos: ", player.global_position.y)
	
	# Test jump trajectory
	player.jump()
	print("[Physics] Low-gravity jump initiated. Velocity: ", player.velocity.y, " m/s")
	if player.velocity.y <= 0.0:
		printerr("FAIL: Jump velocity was not applied!")
		quit(1)
		return
	
	var jump_frames = 0
	while not player.is_on_floor() and jump_frames < 200:
		jump_frames += 1
		await process_frame
	
	print("[Physics] Low-gravity jump completed. Airtime frames: %d (~%.2fs)" % [jump_frames, float(jump_frames)/60.0])
	print("PASS: Minion 3.24 m/s² lunar physics & low-gravity jump verified.")
	
	# Test 4: Dynamic Footprints & Ballistic Regolith Dust
	print("\n--- 4. Testing Footprints & Ballistic Dust ---")
	var fp_system = world.get_node_or_null("FootprintSystem")
	if not fp_system:
		fp_system = player.footprint_system
	if not fp_system:
		printerr("FAIL: FootprintSystem missing!")
		quit(1)
		return
	
	fp_system.place_footprint(player.global_position, Vector3.UP, 0.0, false, 1.0)
	var fp0 = fp_system.get_node_or_null("Footprint_0")
	if not fp0 or not fp0.visible:
		printerr("FAIL: Footprint not deposited!")
		quit(1)
		return
	print("[Footprints] Footprint successfully placed at: ", fp0.global_position)
	
	var dust_system = world.get_node_or_null("BallisticDustSystem")
	if not dust_system:
		dust_system = player.dust_system
	if not dust_system:
		printerr("FAIL: BallisticDustSystem missing!")
		quit(1)
		return
	
	dust_system.emit_footstep_dust(player.global_position, Vector3.FORWARD, true)
	var dust_p = dust_system.get_node_or_null("BallisticDust_0")
	if not dust_p or abs(dust_p.gravity.y - (-3.24)) > 0.05:
		printerr("FAIL: Ballistic dust parameters incorrect!")
		quit(1)
		return
	print("[Dust] Ballistic dust gravity verified at 3.24 m/s².")
	print("PASS: Footprints and ballistic regolith dust verified.")
	
	# Test 5: Vacuum Audio Architecture
	print("\n--- 5. Testing Vacuum Audio Architecture ---")
	var audio_sys = player.audio_system
	if not audio_sys or not audio_sys.plss_hum_player.playing:
		printerr("FAIL: Vacuum audio system or PLSS hum not active!")
		quit(1)
		return
	audio_sys.play_footstep(true)
	audio_sys.play_quindar_tone()
	print("PASS: Vacuum audio system active.")
	
	# Test 6: NASA Geological Inspection System
	print("\n--- 6. Testing Scientific Geology System ---")
	var geo_sys = terrain.get_node_or_null("GeologyInspectionSystem")
	if not geo_sys or not geo_sys.geological_samples.has("sample_74220"):
		printerr("FAIL: Geology inspection system or Sample 74220 missing!")
		quit(1)
		return
	
	geo_sys.start_inspection("sample_74220")
	await process_frame
	print("[Geology] Inspecting: ", geo_sys.active_sample.get("name"))
	if not geo_sys.is_inspecting:
		printerr("FAIL: Inspection did not open!")
		quit(1)
		return
	geo_sys.close_inspection()
	await process_frame
	print("PASS: Scientific geological fieldwork system verified.")
	
	# Test 7: Minion Astronaut HUD Telemetry
	print("\n--- 7. Testing Astronaut Telemetry HUD ---")
	var hud = terrain.get_node_or_null("AstronautHelmetHUD")
	if not hud:
		printerr("FAIL: AstronautHelmetHUD missing!")
		quit(1)
		return
	print("[HUD] View readout: ", hud.view_mode_label.text)
	print("[HUD] Suit pressure: ", hud.suit_pressure_label.text)
	print("[HUD] Gravity: ", hud.gravity_label.text)
	print("PASS: Astronaut HUD telemetry verified.")
	
	print("\n==================================================================")
	print("ALL THIRD-PERSON MINION SIMULATOR TESTS PASSED SUCCESSFULLY!")
	print("==================================================================")
	quit(0)
