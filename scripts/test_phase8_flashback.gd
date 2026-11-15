extends SceneTree
## Phase 8: flashback re-skin. Skinned scene keeps the system-script contract (node paths, signal,
## Space skip) and follows the design system.
## godot --headless --path . --script res://scripts/test_phase8_flashback.gd
var _fails := 0
var _completed := false
func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1
func _frames(n: int = 3) -> void:
	for i in n: await process_frame
func _initialize() -> void:
	_run()
func _all(n: Node, out: Array) -> void:
	out.append(n)
	for c in n.get_children(): _all(c, out)
func _spawn(id: String) -> CanvasLayer:
	_completed = false
	var fb := (load("res://scenes/ui/flashback.tscn") as PackedScene).instantiate()
	fb.artifact_id = id
	fb.flashback_complete.connect(func(): _completed = true)
	root.add_child(fb)
	return fb
func _run() -> void:
	print("--- Phase 8: flashback ---")
	var fb := _spawn("apollo_lrv")
	await _frames(4)
	var nodes: Array = []
	_all(fb, nodes)
	_check(fb.layer == UITokens.LAYER_MODALS, "layer is LAYER_MODALS (%d)" % fb.layer)
	_check(fb.get_node_or_null("GridOverlay") == null and fb.get_node_or_null("TopBorder") == null and fb.get_node_or_null("BottomBorder") == null, "old grid overlay + cyan/amber borders removed")
	var card := fb.get_node("CenterContainer/Card")
	_check(card is ArchiveCard, "card is an ArchiveCard")
	var bad := 0
	for path in ["HeaderBox/TitleLabel", "HeaderBox/SubtitleLabel", "ContentBox/SceneHeader", "ContentBox/NarrativeText", "FooterBox/SkipHint"]:
		var c := fb.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/" + path) as Control
		if c.has_theme_font_size_override("font_size") or c.has_theme_font_size_override("normal_font_size"): bad += 1
	_check(bad == 0, "scene text nodes use theme sizes, no font-size overrides (%d)" % bad)
	_check(not (fb.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/FooterBox/ProgressDots") as Label).visible, "glyph progress dots hidden")
	var badges := nodes.filter(func(n): return n is Badge)
	_check(badges.size() == 1 and (badges[0] as Badge).kind == Badge.Kind.ARCHIVE, "one reconstruction badge (icon + text, not colour alone)")
	var caps := nodes.filter(func(n): return n is KeyCap)
	_check(caps.size() == 2, "skip key-caps: Space + Esc")
	var meters := nodes.filter(func(n): return n is SegmentedMeter)
	_check(meters.size() == 1 and (meters[0] as SegmentedMeter).segment_count == 3, "progress meter has 3 segments (apollo_lrv has 3 scenes)")
	var count := fb.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/FooterBox/ProgressRow").get_child(0) as Label
	_check(count.text == "SCENE 1 / 3", "counter reads '%s'" % count.text)
	_check(fb.get_node("CenterContainer/Card/MarginContainer/VBoxContainer/HeaderBox/TitleLabel").text.begins_with("Lunar Roving"), "title comes from flashbacks.json")
	# scene advance drives the meter
	fb.scene_timer = 99.0
	await _frames(3)
	_check(count.text == "SCENE 2 / 3" and absf((meters[0] as SegmentedMeter).value - 2.0/3.0) < 0.01, "advancing a scene updates counter + meter")
	# Esc skips and is consumed
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(2)
	_check(fb.is_fading_out, "Esc starts the fade-out")
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(fb) and Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	_check(_completed and not is_instance_valid(fb), "flashback_complete emitted and layer freed")
	# unknown id keeps the old fallback
	var fb2 := _spawn("does_not_exist")
	await _frames(3)
	_check(_completed, "unknown artifact id completes immediately (unchanged fallback)")
	# every artifact with a story renders at 1280x720 without overflowing the viewport
	var f := FileAccess.open("res://data/flashbacks.json", FileAccess.READ)
	var ids: Array = JSON.parse_string(f.get_as_text())["flashbacks"].keys()
	root.size = Vector2i(1280, 720)
	var over := 0
	for id in ids:
		var s := _spawn(id)
		await _frames(3)
		var c := s.get_node("CenterContainer/Card") as Control
		if c.size.y > 720 - 32 or c.size.x > 1280 - 32: over += 1; print("   overflow: ", id, c.size)
		s.queue_free()
		await _frames(1)
	_check(over == 0, "all %d stories fit 1280x720 (%d overflow)" % [ids.size(), over])
	print("--- Phase 8: %s ---" % ("PASS" if _fails == 0 else "FAIL (%d)" % _fails))
	quit(1 if _fails > 0 else 0)
