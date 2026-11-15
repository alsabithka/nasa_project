extends SceneTree

func _init() -> void:
	call_deferred("_test_all")

func _test_all() -> void:
	print("==================================================================")
	print("AUDIT: TASK 5 (DIG MINIGAME) & TASK 6 (CLEAN MINIGAME)")
	print("==================================================================")
	
	# --- 1. Test Dig Minigame ---
	print("\n--- 1. Testing Dig Minigame ---")
	var dig_scene = load("res://scenes/ui/dig_minigame.tscn")
	var dig_ui = dig_scene.instantiate()
	dig_ui.artifact_id = "apollo_lrv"
	get_root().add_child(dig_ui)
	
	await process_frame
	await process_frame
	
	if dig_ui.tiles.size() != 40:
		printerr("FAIL: Expected 40 tiles in 8x5 grid, got: ", dig_ui.tiles.size())
		quit(1)
		return
	print("PASS: 8x5 grid (40 tiles) initialized.")
	
	# Test clicking tiles
	var hit_count = 0
	for i in range(dig_ui.tiles.size()):
		var tile = dig_ui.tiles[i]
		if tile.is_artifact:
			# Hit until cleared
			while not tile.cleared:
				dig_ui._hit_tile(i)
				hit_count += 1
	
	print("Hits performed to excavate artifact: ", hit_count)
	print("Combo count: ", dig_ui.combo_count)
	print("Depth bar value: ", dig_ui.depth_bar.value)
	
	if not dig_ui.is_won:
		printerr("FAIL: Dig minigame did not reach win condition after clearing all artifact tiles")
		quit(1)
		return
	print("PASS: Dig minigame win condition reached!")
	
	dig_ui.queue_free()
	await process_frame
	
	# --- 2. Test Cleaning Minigame ---
	print("\n--- 2. Testing Cleaning Minigame ---")
	var clean_scene = load("res://scenes/ui/dig_clean_ui.tscn")
	var clean_ui = clean_scene.instantiate()
	clean_ui.artifact_id = "apollo_lrv"
	get_root().add_child(clean_ui)
	
	await process_frame
	await process_frame
	
	if not clean_ui.dirt_image or not clean_ui.dirt_texture:
		printerr("FAIL: Dirt image or texture missing")
		quit(1)
		return
	print("PASS: 160x160 dirt mask & texture initialized.")
	
	# Simulate scrubbing across the mask
	clean_ui.is_scrubbing = true
	var sim_scrubs = 0
	for y in range(20, 140, 15):
		for x in range(20, 140, 15):
			clean_ui._apply_brush(Vector2(x * 2.5, y * 1.5))
			sim_scrubs += 1
	
	clean_ui._calculate_clean_percentage()
	print("Scrub passes: ", sim_scrubs, " -> Percent clean: %.1f%%" % clean_ui.percent_clean)
	
	# Scrub thoroughly to reach 95%
	for rep in range(8):
		for py in range(0, 240, 16):
			for px in range(0, 440, 16):
				clean_ui._apply_brush(Vector2(px, py))
	
	clean_ui._calculate_clean_percentage()
	print("Thorough scrub -> Percent clean: %.1f%%" % clean_ui.percent_clean)
	
	if not clean_ui.is_complete:
		printerr("FAIL: Clean minigame should auto-complete when reaching >= 95%")
		quit(1)
		return
	print("PASS: Clean minigame successfully completed at >= 95%!")
	
	clean_ui.queue_free()
	await process_frame
	
	# --- 3. Test Full Artifact State Flow & Emergence ---
	print("\n--- 3. Testing Full Artifact Flow & Emergence ---")
	var art_scene = load("res://scenes/artifact/artifact.tscn")
	var artifact = art_scene.instantiate()
	artifact.artifact_id = "apollo_lrv"
	get_root().add_child(artifact)
	
	await process_frame
	await process_frame
	
	# Set to DIG_SITE
	artifact._set_state(artifact.ArtifactState.DIG_SITE)
	print("Artifact initial state: DIG_SITE, visual_model y: %.3f" % artifact.visual_model.position.y)
	
	# Trigger excavation minigame
	artifact._start_digging_minigame()
	if artifact.current_state != artifact.ArtifactState.DIGGING:
		printerr("FAIL: State should be DIGGING")
		quit(1)
		return
	print("PASS: State transitioned to DIGGING.")
	
	# Complete minigame
	artifact._on_dig_minigame_finished()
	if artifact.current_state != artifact.ArtifactState.EXPOSED:
		printerr("FAIL: State should be EXPOSED")
		quit(1)
		return
	print("PASS: State transitioned to EXPOSED after dig finished.")
	
	# Verify emergence tween started
	await process_frame
	print("Visual model emergence starting: y = %.3f" % artifact.visual_model.position.y)
	
	# Trigger cleaning
	artifact._start_cleaning()
	if artifact.current_state != artifact.ArtifactState.CLEANING:
		printerr("FAIL: State should be CLEANING")
		quit(1)
		return
	print("PASS: State transitioned to CLEANING.")
	
	# Complete cleaning
	artifact.on_cleaning_done("apollo_lrv")
	# Merge P7: cleaning now opens the Catalogue Entry; the specimen is registered when it closes.
	await process_frame
	var entry: Node = null
	for c in artifact.get_children():
		if c is CanvasLayer and c.has_signal("documentation_closed"):
			entry = c
	if entry == null:
		printerr("FAIL: Catalogue Entry should open after cleaning")
		quit(1)
		return
	print("PASS: Catalogue Entry opened after cleaning.")
	entry._on_close_pressed()
	if artifact.current_state != artifact.ArtifactState.IDENTIFIED:
		printerr("FAIL: State should be IDENTIFIED")
		quit(1)
		return
	print("PASS: State transitioned to IDENTIFIED.")
	
	var gs = get_root().get_node_or_null("GameState")
	if gs and not gs.is_artifact_recovered("apollo_lrv"):
		printerr("FAIL: Artifact should be marked recovered in GameState")
		quit(1)
		return
	print("PASS: Artifact registered in GameState.")
	
	print("\n==================================================================")
	print("ALL TASK 5 & TASK 6 MINIGAME AUDIT CHECKS PASSED!")
	print("==================================================================")
	quit(0)
