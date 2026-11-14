extends SceneTree

# Automated test suite for Futuristic Sci-Fi Holographic Tactical HUD & UI System

func _init() -> void:
	print("=================================================================")
	print("--- BEGINNING SCI-FI HOLOGRAPHIC TACTICAL UI VERIFICATION ---")
	print("=================================================================")
	call_deferred("_run_test")

func _run_test() -> void:
	var pass_count = 0
	var fail_count = 0
	
	# TEST 1: Check Global Custom Theme in project.godot
	var custom_theme_path = ProjectSettings.get_setting("gui/theme/custom")
	if custom_theme_path == "res://scenes/ui/sci_fi_theme.tres":
		print("[PASS] TEST 1: Global sci_fi_theme.tres registered in project.godot: ", custom_theme_path)
		pass_count += 1
	else:
		printerr("[FAIL] TEST 1: Custom theme not registered in project.godot! Found: ", custom_theme_path)
		fail_count += 1
	
	# TEST 2: Verify Theme Resources and 9-Slice StyleBoxes
	var theme_res = load("res://scenes/ui/sci_fi_theme.tres") as Theme
	if theme_res:
		var has_panel = theme_res.has_stylebox("panel", "PanelContainer")
		var has_btn_normal = theme_res.has_stylebox("normal", "Button")
		var has_btn_hover = theme_res.has_stylebox("hover", "Button")
		var has_btn_pressed = theme_res.has_stylebox("pressed", "Button")
		var has_progress_fill = theme_res.has_stylebox("fill", "ProgressBar")
		if has_panel and has_btn_normal and has_btn_hover and has_btn_pressed and has_progress_fill:
			print("[PASS] TEST 2: sci_fi_theme.tres contains all required 9-slice and neon vector styleboxes.")
			pass_count += 1
		else:
			printerr("[FAIL] TEST 2: Missing styleboxes in sci_fi_theme.tres!")
			fail_count += 1
	else:
		printerr("[FAIL] TEST 2: Could not load sci_fi_theme.tres!")
		fail_count += 1
	
	# Instantiate GameState singleton if running outside full game
	var gs = root.get_node_or_null("GameState")
	if not gs:
		var gs_class = load("res://scripts/autoload/game_state.gd")
		gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)
	
	await process_frame
	
	# TEST 3: Instantiate HUD Scene and verify Node Hierarchy
	var hud_scene = load("res://scenes/ui/hud.tscn") as PackedScene
	if not hud_scene:
		printerr("[FAIL] TEST 3: Could not load res://scenes/ui/hud.tscn")
		quit(1)
		return
	
	var hud_instance = hud_scene.instantiate()
	root.add_child(hud_instance)
	
	for i in range(5):
		await process_frame
	
	# Verify all critical HUD nodes exist
	var location_label = hud_instance.get_node_or_null("TopBar/MarginContainer/HBoxContainer/LocationLabel")
	var counter_label = hud_instance.get_node_or_null("TopBar/MarginContainer/HBoxContainer/CounterBadge/CounterLabel")
	var energy_label = hud_instance.get_node_or_null("TopBar/MarginContainer/HBoxContainer/EnergyPanel/HBox/EnergyLabel")
	var minerals_label = hud_instance.get_node_or_null("TopBar/MarginContainer/HBoxContainer/MineralsPanel/HBox/MineralsLabel")
	var radar_panel = hud_instance.get_node_or_null("RadarWidget")
	var radar_circle = hud_instance.get_node_or_null("RadarWidget/VBoxContainer/RadarCircle")
	var needle = hud_instance.get_node_or_null("RadarWidget/VBoxContainer/RadarCircle/Needle")
	var distance_label = hud_instance.get_node_or_null("RadarWidget/VBoxContainer/DistanceLabel")
	var target_name_label = hud_instance.get_node_or_null("RadarWidget/VBoxContainer/TargetNameLabel")
	var strength_bar = hud_instance.get_node_or_null("RadarWidget/VBoxContainer/StrengthBar")
	var discovery_popup = hud_instance.get_node_or_null("DiscoveryPopup")
	var journal_modal = hud_instance.get_node_or_null("JournalModal")
	var completion_modal = hud_instance.get_node_or_null("CompletionModal")
	
	var all_nodes_present = (
		location_label != null and counter_label != null and energy_label != null and minerals_label != null and
		radar_panel != null and radar_circle != null and needle != null and distance_label != null and
		target_name_label != null and strength_bar != null and discovery_popup != null and
		journal_modal != null and completion_modal != null
	)
	
	if all_nodes_present:
		print("[PASS] TEST 3: HUD node hierarchy verified. All backward-compatible & sci-fi nodes found.")
		pass_count += 1
	else:
		printerr("[FAIL] TEST 3: One or more HUD nodes missing!")
		fail_count += 1
	
	# TEST 4: Tactical Minimap Component attached to RadarCircle
	if radar_circle and radar_circle.get_script():
		var minimap_script_path = radar_circle.get_script().resource_path
		print("[PASS] TEST 4: RadarCircle has Tactical Minimap script: ", minimap_script_path)
		var initial_sweep = radar_circle.sweep_angle
		radar_circle._process(0.1)
		if radar_circle.sweep_angle != initial_sweep:
			print("[PASS] TEST 4b: Radar sweep angle increments correctly (initial: %.2f, now: %.2f)" % [initial_sweep, radar_circle.sweep_angle])
			pass_count += 1
		else:
			printerr("[FAIL] TEST 4b: Radar sweep angle did not update!")
			fail_count += 1
	else:
		printerr("[FAIL] TEST 4: RadarCircle does not have Tactical Minimap script!")
		fail_count += 1
	
	# TEST 5: Dynamic Resource Updates (Energy & Minerals)
	hud_instance._on_resources_updated(85.0, 100.0, 1680)
	if energy_label.text == "85%" and minerals_label.text == "1,680 kg":
		print("[PASS] TEST 5: Real-time resource counters reflect dynamic updates: Energy=", energy_label.text, " Minerals=", minerals_label.text)
		pass_count += 1
	else:
		printerr("[FAIL] TEST 5: Resource labels mismatch! Energy: ", energy_label.text, " Minerals: ", minerals_label.text)
		fail_count += 1
	
	# TEST 6: Scanner Radar Telemetry Formatting
	hud_instance._on_scan_updated("rover", 8.5, 0.82)
	if distance_label.text == "8.5 m" and strength_bar.value == 82.0 and "ANOMALY" in target_name_label.text:
		print("[PASS] TEST 6: Scanner telemetry updates correctly: ", distance_label.text, " | ", target_name_label.text)
		pass_count += 1
	else:
		printerr("[FAIL] TEST 6: Scanner telemetry failed! Dist: ", distance_label.text, " Bar: ", strength_bar.value)
		fail_count += 1
	
	# TEST 7: DigCleanUI Scene Instantiation and Sci-Fi Styling
	var dig_scene = load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene
	if dig_scene:
		var dig_inst = dig_scene.instantiate()
		root.add_child(dig_inst)
		await process_frame
		var dig_card = dig_inst.get_node_or_null("CenterContainer/PanelContainer")
		var dig_preview = dig_inst.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/PreviewBox")
		var dig_bar = dig_inst.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/ProgressBar")
		if dig_card and dig_preview and dig_bar:
			print("[PASS] TEST 7: DigCleanUI successfully instantiated with sci-fi decontamination layout.")
			pass_count += 1
		else:
			printerr("[FAIL] TEST 7: DigCleanUI missing required subnodes!")
			fail_count += 1
		dig_inst.queue_free()
	else:
		printerr("[FAIL] TEST 7: Could not load dig_clean_ui.tscn")
		fail_count += 1
	
	# TEST 8: Main Menu Scene Instantiation and Sci-Fi Holographic Styling
	var menu_scene = load("res://scenes/main_menu.tscn") as PackedScene
	if menu_scene:
		var menu_inst = menu_scene.instantiate()
		root.add_child(menu_inst)
		await process_frame
		var main_card = menu_inst.get_node_or_null("CenterContainer/MainCard")
		var play_moon = menu_inst.get_node_or_null("CenterContainer/MainCard/VBoxContainer/PlayMoonBtn")
		var play_mars = menu_inst.get_node_or_null("CenterContainer/MainCard/VBoxContainer/PlayMarsBtn")
		var controls_modal = menu_inst.get_node_or_null("ControlsModal")
		if main_card and play_moon and play_mars and controls_modal:
			print("[PASS] TEST 8: MainMenu successfully instantiated with sci-fi holographic card & mission modal.")
			pass_count += 1
		else:
			printerr("[FAIL] TEST 8: MainMenu missing required subnodes!")
			fail_count += 1
		menu_inst.queue_free()
	else:
		printerr("[FAIL] TEST 8: Could not load main_menu.tscn")
		fail_count += 1
	
	# TEST 9: Flashback Scene Instantiation and Holographic Card
	var fb_scene = load("res://scenes/ui/flashback.tscn") as PackedScene
	if fb_scene:
		var fb_inst = fb_scene.instantiate()
		fb_inst.artifact_id = "apollo_lrv"
		var fb_card = fb_inst.get_node_or_null("CenterContainer/Card")
		if fb_card:
			print("[PASS] TEST 9: FlashbackSystem instantiated with transparent glass holographic card.")
			pass_count += 1
		else:
			printerr("[FAIL] TEST 9: FlashbackSystem missing Card node!")
			fail_count += 1
		root.add_child(fb_inst)
		await process_frame
		fb_inst.queue_free()
	else:
		printerr("[FAIL] TEST 9: Could not load flashback.tscn")
		fail_count += 1
	
	# Clean up HUD instance
	hud_instance.queue_free()
	
	print("=================================================================")
	print("--- TEST SUMMARY: %d PASSED, %d FAILED ---" % [pass_count, fail_count])
	print("=================================================================")
	
	if fail_count == 0:
		print(">>> ALL SCI-FI HOLOGRAPHIC UI TESTS PASSED SUCCESSFULLY! <<<")
		quit(0)
	else:
		printerr(">>> TEST FAILURES DETECTED! <<<")
		quit(1)
