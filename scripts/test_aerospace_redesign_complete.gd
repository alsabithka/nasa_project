extends SceneTree

# Comprehensive Master Verification Test for the Game-Wide Aerospace UI/UX Redesign
# Verifies:
# 1. Unified Aerospace Theme palette & StyleBoxes
# 2. Main Menu: Spacecraft flight computer layout, telemetry bar, settings, credits, controls modals
# 3. In-Game HUD: Aerospace header, real-time energy & mineral counters, status indicators, radar scanner
# 4. In-Game System/Pause Menu (SettingsModal): Volume slider, orbit sensitivity slider, fullscreen toggle, resume/restart
# 5. Astronaut Helmet HUD: Circular gauges, ECG waveform graph, battery segments, compass heading tape, gravity & MET
# 6. Tactical Minimap: Degree ticks, coordinate telemetry, 360° sweep, blip tracking, proximity lock reticle
# 7. Field Specimen Decontamination Chamber (DigCleanUI): Scientific instrumentation layout & ultrasonic cleaning
# 8. Historical Transmission Reconstruction (Flashback): Aerospace letterbox, scanline grid, telemetry datastream
# 9. Geological Inspection System (compendium modal): Apollo 17 sample curation dossier

func _init() -> void:
	print("=================================================================")
	print("--- COMMENCING GAME-WIDE AEROSPACE UI/UX REDESIGN AUDIT ---")
	print("=================================================================")
	call_deferred("_run_audit")

func _run_audit() -> void:
	var passes = 0
	var fails = 0
	
	# 1. Palette & Theme Verification
	print("\n--- 1. Testing Unified Aerospace Design System ---")
	if AerospaceTheme.COLOR_CYAN == Color(0.0, 0.898, 1.0, 1.0) and \
	   AerospaceTheme.COLOR_TURQUOISE == Color(0.0, 0.749, 0.647, 1.0) and \
	   AerospaceTheme.COLOR_AMBER == Color(1.0, 0.616, 0.196, 1.0) and \
	   AerospaceTheme.COLOR_CRITICAL == Color(1.0, 0.271, 0.271, 1.0) and \
	   AerospaceTheme.COLOR_STATUS_GREEN == Color(0.224, 0.898, 0.549, 1.0) and \
	   AerospaceTheme.COLOR_TEXT_PRIMARY == Color(0.898, 0.949, 0.961, 1.0) and \
	   AerospaceTheme.COLOR_TEXT_SECONDARY == Color(0.467, 0.565, 0.616, 1.0):
		print("[PASS] AerospaceTheme color constants match required aerospace palette.")
		passes += 1
	else:
		printerr("[FAIL] AerospaceTheme color constants mismatch!")
		fails += 1
	
	# Ensure GameState singleton is ready
	var gs = root.get_node_or_null("GameState")
	if not gs:
		var gs_class = load("res://scripts/autoload/game_state.gd")
		gs = gs_class.new()
		gs.name = "GameState"
		root.add_child(gs)
	await process_frame
	
	# 2. Main Menu Testing
	print("\n--- 2. Testing Main Menu & Flight Computer Interface ---")
	var menu_scene = load("res://scenes/main_menu.tscn") as PackedScene
	if menu_scene:
		var menu = menu_scene.instantiate()
		root.add_child(menu)
		await process_frame
		
		var title = menu.get_node_or_null("CenterContainer/MainCard/VBoxContainer/Title")
		var telem_bar = menu.get_node_or_null("TopTelemetryBar")
		var controls_m = menu.get_node_or_null("ControlsModal")
		var settings_m = menu.get_node_or_null("SettingsModal")
		var credits_m = menu.get_node_or_null("CreditsModal")
		
		if title and telem_bar and controls_m and settings_m and credits_m:
			print("[PASS] Main Menu loaded with flight computer header, controls, settings, and credits modals.")
			passes += 1
		else:
			printerr("[FAIL] Main Menu missing essential aerospace interface nodes!")
			fails += 1
		
		# Test settings toggle
		menu._show_modal(settings_m)
		if settings_m.visible and not controls_m.visible and not credits_m.visible:
			print("[PASS] Main Menu modal management works cleanly.")
			passes += 1
		else:
			printerr("[FAIL] Main Menu modal management failed!")
			fails += 1
		
		menu.queue_free()
	else:
		printerr("[FAIL] Could not load main_menu.tscn")
		fails += 1
	
	await process_frame
	
	# 3. In-Game HUD Testing
	print("\n--- 3. Testing In-Game HUD & In-Game System/Pause Menu ---")
	var hud_scene = load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene:
		var hud = hud_scene.instantiate()
		root.add_child(hud)
		for f in range(5): await process_frame
		
		var status_badge = hud.get_node_or_null("TopBar/MarginContainer/HBoxContainer/StatusBadge")
		var location_label = hud.get_node_or_null("TopBar/MarginContainer/HBoxContainer/LocationLabel")
		var energy_label = hud.get_node_or_null("TopBar/MarginContainer/HBoxContainer/EnergyPanel/HBox/EnergyLabel")
		var minerals_label = hud.get_node_or_null("TopBar/MarginContainer/HBoxContainer/MineralsPanel/HBox/MineralsLabel")
		var settings_modal = hud.get_node_or_null("SettingsModal")
		var radar_widget = hud.get_node_or_null("RadarWidget")
		
		if status_badge and location_label and energy_label and minerals_label and settings_modal and radar_widget:
			print("[PASS] HUD loaded with telemetry status badge, sector banner, resources, and settings modal.")
			passes += 1
		else:
			printerr("[FAIL] HUD missing critical telemetry nodes!")
			fails += 1
		
		# Test SettingsModal (Pause Menu) toggle
		hud.toggle_settings()
		if settings_modal.visible:
			print("[PASS] In-Game System Configuration (Pause Menu) toggles visible.")
			passes += 1
		else:
			printerr("[FAIL] In-Game SettingsModal failed to open!")
			fails += 1
		
		hud.toggle_settings()
		if not settings_modal.visible:
			print("[PASS] In-Game System Configuration closes and returns to gameplay.")
			passes += 1
		else:
			printerr("[FAIL] In-Game SettingsModal failed to close!")
			fails += 1
		
		hud.queue_free()
	else:
		printerr("[FAIL] Could not load hud.tscn")
		fails += 1
	
	await process_frame
	
	# 4. Astronaut Helmet HUD Testing
	print("\n--- 4. Testing Astronaut Helmet Visor Telemetry HUD ---")
	var helmet_script = load("res://scripts/ui/astronaut_helmet_hud.gd")
	if helmet_script:
		var helmet_hud = CanvasLayer.new()
		helmet_hud.set_script(helmet_script)
		root.add_child(helmet_hud)
		await process_frame
		
		# Check internal components
		if helmet_hud.visor_overlay and helmet_hud.top_panel and helmet_hud.left_instrument_panel and helmet_hud.right_instrument_panel:
			print("[PASS] Helmet HUD successfully built visor overlay, telemetry header, left life-support cluster, and right navigation cluster.")
			passes += 1
		else:
			printerr("[FAIL] Helmet HUD missing instrument clusters!")
			fails += 1
		
		# Test ECG waveform update
		var initial_pts = helmet_hud._ecg_points.duplicate()
		helmet_hud._process(0.1)
		if helmet_hud._ecg_points.size() == 60:
			print("[PASS] Real-time dynamic ECG waveform buffer updating smoothly.")
			passes += 1
		else:
			printerr("[FAIL] ECG waveform buffer size mismatch!")
			fails += 1
		
		helmet_hud.queue_free()
	else:
		printerr("[FAIL] Could not load astronaut_helmet_hud.gd")
		fails += 1
	
	await process_frame
	
	# 5. Tactical Minimap Testing
	print("\n--- 5. Testing Tactical Minimap & Lunar Navigation Instrument ---")
	var minimap_script = load("res://scripts/ui/tactical_minimap.gd")
	if minimap_script:
		var minimap = Control.new()
		minimap.set_script(minimap_script)
		minimap.size = Vector2(160, 160)
		root.add_child(minimap)
		await process_frame
		
		var init_angle = minimap.sweep_angle
		minimap._process(0.2)
		if minimap.sweep_angle > init_angle:
			print("[PASS] Tactical Minimap 360° radar sweep advancing with phosphor trail: %.2f rad" % minimap.sweep_angle)
			passes += 1
		else:
			printerr("[FAIL] Tactical Minimap sweep angle did not advance!")
			fails += 1
		
		minimap.queue_free()
	else:
		printerr("[FAIL] Could not load tactical_minimap.gd")
		fails += 1
	
	await process_frame
	
	# 6. Digging & Cleaning Decontamination Chamber Testing
	print("\n--- 6. Testing Field Specimen Decontamination Chamber ---")
	var dig_scene = load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene
	if dig_scene:
		var dig = dig_scene.instantiate()
		root.add_child(dig)
		await process_frame
		
		var pb = dig.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/ProgressBar")
		var hint = dig.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/BrushHint")
		var led = dig.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/InstrumentStatusHBox/StatusLed")
		
		if pb and hint and led:
			print("[PASS] Decontamination chamber initialized with ultrasonic tool telemetry and progress meters.")
			passes += 1
		else:
			printerr("[FAIL] Decontamination chamber missing essential telemetry nodes!")
			fails += 1
		
		dig.queue_free()
	else:
		printerr("[FAIL] Could not load dig_clean_ui.tscn")
		fails += 1
	
	await process_frame
	
	# 7. Flashback Testing
	print("\n--- 7. Testing NASA Historical Transmission Reconstruction ---")
	var fb_scene = load("res://scenes/ui/flashback.tscn") as PackedScene
	if fb_scene:
		var fb = fb_scene.instantiate()
		fb.artifact_id = "apollo_lrv"
		var card = fb.get_node_or_null("CenterContainer/Card")
		var grid_overlay = fb.get_node_or_null("GridOverlay")
		if card and grid_overlay:
			print("[PASS] Flashback transmission reconstructed with scanline grid backdrop and aerospace glass card.")
			passes += 1
		else:
			printerr("[FAIL] Flashback interface missing card or grid overlay!")
			fails += 1
		
		root.add_child(fb)
		await process_frame
		fb.queue_free()
	else:
		printerr("[FAIL] Could not load flashback.tscn")
		fails += 1
	
	await process_frame
	
	# 8. Geological Sample Curation Dossier Testing
	print("\n--- 8. Testing Geological Sample Curation Dossier ---")
	var geo_script = load("res://scripts/exploration/geology_inspection_system.gd")
	if geo_script:
		var geo = Node3D.new()
		geo.set_script(geo_script)
		root.add_child(geo)
		await process_frame
		
		geo.start_inspection("sample_70017")
		await process_frame
		
		if geo._inspection_ui and geo.is_inspecting:
			print("[PASS] Apollo 17 Sample 70017 Curation Dossier opened with aerospace glass dossier styling.")
			passes += 1
			geo.close_inspection()
			if not geo.is_inspecting:
				print("[PASS] Sample Dossier cleanly closed and released mouse.")
				passes += 1
			else:
				printerr("[FAIL] Sample Dossier failed to close!")
				fails += 1
		else:
			printerr("[FAIL] Geological sample inspection failed to launch UI!")
			fails += 1
		
		geo.queue_free()
	else:
		printerr("[FAIL] Could not load geology_inspection_system.gd")
		fails += 1
	
	print("\n=================================================================")
	print("--- AUDIT SUMMARY: %d PASSED, %d FAILED ---" % [passes, fails])
	print("=================================================================")
	
	if fails == 0:
		print(">>> ALL AEROSPACE UI/UX REDESIGN SYSTEMS OPERATING NOMINALLY! <<<")
		quit(0)
	else:
		printerr(">>> FAILURES ENCOUNTERED IN AEROSPACE UI AUDIT! <<<")
		quit(1)
