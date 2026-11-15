extends SceneTree
## Phase 6 regression: dig mini-game + cleaning screen (integrated1 rules, harsh chrome).
## godot --headless --path . --script res://scripts/test_phase6_dig_clean.gd
var _fails := 0
var _done_count := 0
var _dig_done := 0
func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1
func _frames(n: int = 3) -> void:
	for i in n: await process_frame
func _initialize() -> void:
	_run()
func _run() -> void:
	print("--- Phase 6: dig + clean ---")
	var ss: Variant = root.get_node_or_null("SettingsStore")
	# ---------------- DIG ----------------
	var dig = (load("res://scenes/ui/dig_minigame.tscn") as PackedScene).instantiate()
	dig.artifact_id = "apollo_lrv"
	root.add_child(dig)
	await _frames(3)
	dig.dig_finished.connect(func(): _dig_done += 1)
	_check(dig.layer == UITokens.LAYER_MODALS, "dig on LAYER_MODALS (20)")
	_check(dig.is_in_group("blocking_modal"), "dig joins blocking_modal")
	_check(dig.tiles.size() == 40, "8x5 grid = 40 tiles")
	_check(dig.depth_bar is SegmentedMeter and dig.depth_bar.vertical, "depth gauge is a vertical SegmentedMeter")
	_check(dig.grid_canvas.custom_minimum_size == Vector2(618, 344), "grid footprint unchanged (618x344)")
	_check(dig.find_children("*", "ProgressBar", true, false).is_empty(), "no ProgressBar left")
	var rocks := 0
	for t in dig.tiles:
		if t.is_rock: rocks += 1
	_check(rocks > 0, "seeded grid has rock tiles (%d) that get hatch + warning icon" % rocks)
	# hit decrements layers (pick a non-artifact tile with 2 layers if possible)
	var idx := -1
	for i in dig.tiles.size():
		if not dig.tiles[i].is_artifact and dig.tiles[i].layers >= 2:
			idx = i; break
	var before: int = dig.tiles[idx].layers
	dig._hit_tile(idx)
	_check(dig.tiles[idx].layers == before - 1, "a hit removes one layer")
	_check(dig.combo_label.text == "COMBO 1×", "combo readout: '%s'" % dig.combo_label.text)
	# power burst on the 5th consecutive hit
	dig.combo_count = 4
	var any_t := -1
	for i in dig.tiles.size():
		if not dig.tiles[i].cleared: any_t = i; break
	dig._hit_tile(any_t)
	_check(dig.burst_badge.visible, "POWER BURST badge appears on the 5th hit")
	_check(dig.status_label.text.to_lower().find("power burst") >= 0 and not ("★" in dig.status_label.text), "burst status text, no glyph")
	await create_timer(dig.BURST_FLASH_TIME + 0.2).timeout
	_check(not dig.burst_badge.visible, "burst badge goes away again")
	# win
	for i in dig.tiles.size():
		var t = dig.tiles[i]
		if t.is_artifact:
			while not t.cleared:
				t.cleared = true
	dig._check_win_condition()
	_check(dig.is_won and is_equal_approx(dig.depth_bar.value, 1.0), "win when all artifact tiles are cleared; depth meter full")
	_check(dig.status_label.text == "ARTIFACT EXPOSED" and dig.status_icon.visible, "victory = check icon + 'ARTIFACT EXPOSED'")
	await create_timer(1.6).timeout
	_check(_dig_done == 1, "dig_finished emitted exactly once (%d)" % _dig_done)
	# reduced motion: shake and sparks off
	var dig2 = (load("res://scenes/ui/dig_minigame.tscn") as PackedScene).instantiate()
	dig2.artifact_id = "alsep"
	root.add_child(dig2); await _frames(2)
	SettingsStore.set_value("reduced_motion", true)
	dig2._spawn_particles(Vector2.ZERO, 6)
	_check(dig2.hit_sparks.is_empty(), "reduced motion: no sparks")
	SettingsStore.set_value("reduced_motion", false)
	dig2._spawn_particles(Vector2.ZERO, 6)
	_check(dig2.hit_sparks.size() == 6, "motion on: sparks spawn")
	var cancelled := [0]
	dig2.dig_cancelled.connect(func(): cancelled[0] += 1)
	var esc := InputEventKey.new(); esc.keycode = KEY_ESCAPE; esc.physical_keycode = KEY_ESCAPE; esc.pressed = true
	root.push_input(esc); await _frames(2)
	_check(cancelled[0] == 1, "Esc cancels the dig exactly once")

	# ---------------- CLEAN ----------------
	var clean = (load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene).instantiate()
	clean.artifact_id = "apollo_lrv"
	clean.cleaning_done.connect(func(_id): _done_count += 1)
	root.add_child(clean)
	await _frames(3)
	_check(clean.layer == UITokens.LAYER_MODALS, "clean on LAYER_MODALS (20)")
	_check(clean.is_in_group("blocking_modal"), "clean joins blocking_modal")
	_check(clean.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer") != null, "contract node path kept")
	_check(clean.get_node("CenterContainer/PanelContainer") is ArchiveCard, "card is an ArchiveCard")
	_check(clean.specimen is SpecimenReveal and not clean.specimen.show_dust, "specimen = SpecimenReveal in static mode (no cell dust)")
	_check(clean.progress_meter.segment_count == 20, "20-segment meter")
	_check(clean.state_label.text == "Unidentified subsurface anomaly", "state text at 0 %")
	_check(clean.get_node("CenterContainer/PanelContainer/VBoxContainer/Subtitle").text.begins_with("TARGET:"), "target line keeps artifact data")
	# brush erases alpha; crust erases slower
	var cp: Vector3 = clean.crust_patches[0]
	var plate := Vector2(440, 240)
	var px := Vector2(cp.x / 160.0 * plate.x, cp.y / 160.0 * plate.y)
	var a0: float = clean.dirt_image.get_pixel(int(cp.x), int(cp.y)).a
	clean._apply_brush(px)
	var a1: float = clean.dirt_image.get_pixel(int(cp.x), int(cp.y)).a
	_check(a1 < a0, "brush erases alpha (%.2f -> %.2f)" % [a0, a1])
	# find a non-crust pixel and compare removal
	var free := Vector2i(-1, -1)
	for y in range(8, 152, 4):
		for x in range(8, 152, 4):
			var inside := false
			for p in clean.crust_patches:
				if Vector2(x - p.x, y - p.y).length() < p.z + BRUSH_PAD: inside = true
			if not inside: free = Vector2i(x, y); break
		if free.x >= 0: break
	if free.x >= 0:
		var f0: float = clean.dirt_image.get_pixel(free.x, free.y).a
		clean._apply_brush(Vector2(free.x / 160.0 * plate.x, free.y / 160.0 * plate.y))
		var f1: float = clean.dirt_image.get_pixel(free.x, free.y).a
		_check((f0 - f1) > (a0 - a1), "crust patch erases slower than open regolith (%.2f vs %.2f)" % [a0 - a1, f0 - f1])
	# scrubbing UI state
	clean._set_scrubbing(true)
	_check(clean.tool_status.text == "SCRUBBING", "tool state words change while scrubbing")
	clean._set_scrubbing(false)
	_check(clean.tool_status.text == "IDLE", "…and back to IDLE")
	# scrub everything
	for y in range(0, 240, 6):
		for x in range(0, 440, 6):
			if clean.is_complete: break
			clean._apply_brush(Vector2(x, y))
			clean._calculate_clean_percentage()
	_check(clean.is_complete, "complete at >= 94.8 %")
	_check(is_equal_approx(clean.progress_meter.value, 1.0), "meter follows percent_clean (full)")
	_check(clean.state_label.text == "Cleaned and preserved", "final state text")
	await create_timer(1.5).timeout
	_check(_done_count == 1, "cleaning_done emitted exactly once (%d)" % _done_count)
	var left := 0
	for y in range(0, 160, 4):
		for x in range(0, 160, 4):
			if clean.dirt_image.get_pixel(x, y).a > 0.01: left += 1
	_check(left == 0, "remaining dust faded out completely")
	clean.queue_free()
	# Esc during cleaning returns control (no parent artifact in this test, so it just frees)
	var clean2 = (load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene).instantiate()
	root.add_child(clean2); await _frames(2)
	root.push_input(esc); await _frames(2)
	_check(not is_instance_valid(clean2) or clean2.is_queued_for_deletion(), "Esc cancels cleaning")
	print("--- Phase 6: %s (%d failures) ---" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(_fails)
const BRUSH_PAD := 20.0
