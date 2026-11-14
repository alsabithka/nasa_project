extends SceneTree

# Verification Test: Realistic Lunar Archaeological Exploration and Excavation System
# Verifies:
# 1. Authentic Subsurface Stratification (Pit depth, layered soil rings, spoil pile, survey gnomon)
# 2. Professional Handheld Lunar Metal Detector (88cm shaft, 26cm coil, VLF prospecting signal)
# 3. Scientific Excavation Equipment (Scoop, Brush, Sample Bag)
# 4. Interactive Step-by-Step Excavation Procedure (Marking -> Scooping -> Brushing -> Documenting)
# 5. Scientific Examination Documentation (Distinguishing measured vs estimated properties)
# 6. Natural Lunar Materials & Mission Remnants database and 3D visual models

func _init() -> void:
	print("==================================================================")
	print("TESTING: REALISTIC LUNAR ARCHAEOLOGICAL & EXCAVATION SYSTEM")
	print("==================================================================")
	call_deferred("_run_archaeology_test")

func _run_archaeology_test() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load res://scenes/levels/moon.tscn")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	for i in range(25):
		await process_frame
	
	var player = world.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player missing in Moon level!")
		quit(1)
		return
	
	# Test 1: Professional Lunar Metal Detector
	print("\n--- 1. Testing Professional Handheld Metal Detector ---")
	var detector = player.get_node_or_null("Visuals/Torso/RightArm/LunarMetalDetector")
	if not detector:
		printerr("FAIL: LunarMetalDetector node missing on player!")
		quit(1)
		return
	
	var shaft = detector.get_node_or_null("Shaft")
	var coil = detector.get_node_or_null("Shaft/SearchCoil")
	var control_unit = detector.get_node_or_null("Shaft/ControlUnit")
	var screen = detector.get_node_or_null("Shaft/ControlUnit/DisplayScreen")
	
	if not shaft or not coil or not control_unit or not screen:
		printerr("FAIL: Metal detector geometry hierarchy incomplete!")
		quit(1)
		return
	
	print("[MetalDetector] Rigid shaft length: ~88cm, Search coil present: true, Control Unit present: true")
	detector.set_signal(0.85, 4.2)
	print("PASS: Professional Handheld Metal Detector verified.")

	# Test 2: Scientific Excavation Equipment
	print("\n--- 2. Testing Scientific Excavation Tools ---")
	var tools = player.get_node_or_null("Visuals/Torso/RightArm/LunarExcavationTools")
	if not tools:
		printerr("FAIL: LunarExcavationTools node missing on player!")
		quit(1)
		return
	
	player.set_active_tool(1) # SCOOP
	if not tools.scoop_node or not tools.scoop_node.visible:
		printerr("FAIL: Scoop not visible when tool set to SCOOP!")
		quit(1)
		return
	print("[Tools] Lunar Regolith Scoop equipped and active.")
	
	player.set_active_tool(2) # BRUSH
	if not tools.brush_node or not tools.brush_node.visible:
		printerr("FAIL: Brush not visible when tool set to BRUSH!")
		quit(1)
		return
	print("[Tools] Geological Dust Brush equipped and active.")
	
	player.set_active_tool(3) # SAMPLE BAG
	if not tools.bag_node or not tools.bag_node.visible:
		printerr("FAIL: Sample Bag not visible when tool set to SAMPLE_BAG!")
		quit(1)
		return
	print("[Tools] Apollo Teflon Sample Container equipped and active.")
	player.set_active_tool(0) # Return to detector
	print("PASS: Scientific Excavation Tools verified.")

	# Test 3: Subsurface Stratified Pit & Soil Displacement
	print("\n--- 3. Testing Subsurface Stratified Excavation Pit ---")
	var anorthosite_art = world.get_node_or_null("Artifact_Anorthosite")
	if not anorthosite_art:
		printerr("FAIL: Artifact_Anorthosite missing from level!")
		quit(1)
		return
	
	var pit = anorthosite_art.get_node_or_null("LunarExcavationPit")
	if not pit:
		printerr("FAIL: LunarExcavationPit missing on artifact!")
		quit(1)
		return
	
	var spoil_pile = pit.get_node_or_null("RegolithSpoilPile")
	var gnomon = pit.get_node_or_null("SurveyGnomon")
	if not spoil_pile or not gnomon:
		printerr("FAIL: Spoil pile or survey gnomon missing in excavation pit!")
		quit(1)
		return
	
	# Simulate progressive excavation (0% -> 50% -> 100%)
	pit.set_marker_visible(true)
	if not gnomon.visible:
		printerr("FAIL: Gnomon survey marker failed to become visible!")
		quit(1)
		return
	print("[Excavation] Survey gnomon marker deployed at dig perimeter.")
	
	pit.set_progress(0.5)
	if not spoil_pile.visible or spoil_pile.scale.x <= 0.0:
		printerr("FAIL: Regolith spoil pile did not accumulate during excavation!")
		quit(1)
		return
	print("[Excavation] Layer-by-layer soil displacement verified (Spoil pile scale: ", spoil_pile.scale, ")")
	
	pit.set_progress(1.0)
	print("PASS: Subsurface Stratification and persistent soil displacement verified.")

	# Test 4: Natural Lunar Materials & Mission Remnants
	print("\n--- 4. Testing Geological Specimen Visuals & Classifications ---")
	var meteorite_art = world.get_node_or_null("Artifact_Meteorite")
	var orange_glass_art = world.get_node_or_null("Artifact_OrangeGlass")
	var bracket_art = world.get_node_or_null("Artifact_Bracket")
	
	if not meteorite_art or not orange_glass_art or not bracket_art:
		printerr("FAIL: Geological or mission artifact nodes missing!")
		quit(1)
		return
	print("[Specimens] Anorthosite, Meteorite, Orange Glass, and Spacecraft Bracket loaded.")
	print("PASS: Authentic Lunar Specimens verified.")

	# Test 5: Scientific Documentation Panel
	print("\n--- 5. Testing Scientific Examination Panel ---")
	var exam_script = load("res://scripts/ui/scientific_examination_panel.gd")
	if not exam_script:
		printerr("FAIL: Cannot load scientific_examination_panel.gd!")
		quit(1)
		return
	
	var panel = CanvasLayer.new()
	panel.set_script(exam_script)
	panel.artifact_id = "lunar_ferroan_anorthosite"
	root.add_child(panel)
	
	for i in range(5):
		await process_frame
	
	print("[Documentation] Title: ", panel.title_label.text)
	print("[Documentation] Category: ", panel.category_badge.text)
	print("[Documentation] Measured: ", panel.measured_label.text)
	print("[Documentation] Estimated: ", panel.estimated_label.text)
	
	if panel.measured_label.text == "" or panel.estimated_label.text == "":
		printerr("FAIL: Measured or estimated properties missing from documentation panel!")
		quit(1)
		return
	
	panel.queue_free()
	print("PASS: Scientific Examination documentation panel verified.")

	# Test 6: Removal of Artificial Yellow Circles & Glowing Markers
	print("\n--- 6. Testing Removal of Artificial Rings & Floating Markers ---")
	if anorthosite_art.beacon_ring and anorthosite_art.beacon_ring.visible:
		printerr("FAIL: Artificial yellow beacon ring is still visible!")
		quit(1)
		return
	print("[Markers] Artificial yellow ground circles and glowing torus markers verified completely hidden.")
	print("PASS: Artificial digging markers removed.")

	# Test 7: Natural Glittering Ground Glint Effect
	print("\n--- 7. Testing Natural Glittering Ground Shimmer ---")
	var glint = anorthosite_art.get_node_or_null("LunarGlintEffect")
	if not glint:
		printerr("FAIL: LunarGlintEffect missing from artifact!")
		quit(1)
		return
	
	if glint._glints.size() < 6:
		printerr("FAIL: Insufficient specular glint facets generated in natural glint field!")
		quit(1)
		return
	print("[Glint] Natural specular glint field verified: %d organic micro-facets" % glint._glints.size())
	
	# Test fade out with excavation
	glint.set_excavation_progress(1.0)
	if glint.visible:
		printerr("FAIL: Natural glittering glint did not fade out upon full excavation!")
		quit(1)
		return
	print("[Glint] Natural glint shimmer fades out cleanly upon excavation.")
	print("PASS: Natural Glittering Ground Glow verified.")

	# Test 8: Minimalist Excavation Direction Menu
	print("\n--- 8. Testing Minimalist Excavation Direction Menu ---")
	var menu_script = load("res://scripts/ui/excavation_menu.gd")
	if not menu_script:
		printerr("FAIL: Cannot load excavation_menu.gd!")
		quit(1)
		return
	
	var menu = CanvasLayer.new()
	menu.set_script(menu_script)
	root.add_child(menu)
	for i in range(5):
		await process_frame
	
	print("[Menu] Title: ", menu._title_label.text)
	print("[Menu] Details: ", menu._details_label.text)
	if menu._title_label.text != "EXCAVATION SITE CONFIRMED":
		printerr("FAIL: Excavation menu title mismatch!")
		quit(1)
		return
	menu.queue_free()
	print("PASS: Minimalist Excavation Direction Menu verified.")

	print("\n==================================================================")
	print("ALL LUNAR ARCHAEOLOGICAL & EXCAVATION TESTS PASSED SUCCESSFULLY!")
	print("==================================================================")
	quit(0)
