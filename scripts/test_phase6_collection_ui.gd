extends SceneTree

# Phase 6 verification — collection screens (journal drawer, gallery rail, component inspector).
# Run:  godot --headless --path . --script res://scripts/test_phase6_collection_ui.gd
# Checks:
#  1. JournalSlot shape mapping (pure function).
#  2. Journal, nothing found: slots == planet totals, every slot locked and anonymous, fits 1280x720,
#     Mars shows the locked-survey notice.
#  3. Journal, some found: names and categories appear only for found slots; filters list the
#     categories with found/total; filtering narrows the slots.
#  4. Detail panel: key facts first, narrative behind READ MORE; no raw BBCode; integer year;
#     locked detail never leaks the artifact name.
#  5. Full state (every Moon artifact found) and Esc handling / closed signal.
#  6. HUD scene: JournalModal gone, drawer opens and closes through toggle_journal().
#  7. Gallery: header / info / rail fit 1280x720 and 1366x768; inspector hides rail + info; no raw KEY_.
#  8. Inspector contract used by test_historical_spacecraft_assets.gd.
#  9. Source hygiene: no font-size or colour literals in the new components.

const GALLERY_SCENE := "res://scenes/spacecraft/spacecraft_gallery.tscn"

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		printerr("  FAIL ", msg)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _texts(n: Node, out: PackedStringArray) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func _all_text(n: Node) -> String:
	var a := PackedStringArray()
	_texts(n, a)
	return "\n".join(a)


func _fits(c: Control, view: Vector2) -> bool:
	var r := c.get_global_rect()
	return r.position.x >= -0.5 and r.position.y >= -0.5 and r.end.x <= view.x + 0.5 and r.end.y <= view.y + 0.5


func _source(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var gs = root.get_node_or_null("GameState")
	_check(gs != null, "GameState autoload present")
	if gs == null:
		quit(1)
		return
	gs.reset_progress()
	var view := Vector2(1280, 720)

	# ── 1. shapes ─────────────────────────────────────────────────────────────────────────
	print("\n--- 1. Silhouette mapping ---")
	_check(JournalSlot.shape_for("Natural Lunar Material") == "circle", "natural material -> circle")
	_check(JournalSlot.shape_for("Scientific Discoveries") == "triangle", "scientific discovery -> triangle")
	_check(JournalSlot.shape_for("Space Mission Remnants") == "square", "mission remnants -> square")
	_check(JournalSlot.shape_for("Historical Spacecraft") == "diamond", "historical spacecraft -> diamond")
	_check(JournalSlot.shape_for("Deep Space Probes") == "ring", "deep space probes -> ring")
	_check(JournalSlot.shape_for("") == "square", "unknown category falls back to square")

	# ── 2. Journal, nothing found ─────────────────────────────────────────────────────────
	print("\n--- 2. Journal: empty collection ---")
	var j := JournalDrawer.new()
	root.add_child(j)
	await _frames(2)
	var closed_seen := [0]
	j.closed.connect(func() -> void: closed_seen[0] += 1)
	j.open("Moon")
	await _frames(4)
	_check(j.is_open(), "drawer opens")
	_check(j.slots.size() == gs.get_total_count("Moon"), "Moon slots == total (%d)" % j.slots.size())
	_check(_fits(j.card, view), "card fits 1280x720 (%s)" % str(j.card.get_global_rect()))
	var txt := _all_text(j)
	var leaked := false
	for id in gs.artifacts_data.keys():
		if str(gs.artifacts_data[id].get("location", "")) == "Moon" and txt.contains(str(gs.artifacts_data[id]["name"])):
			leaked = true
	_check(not leaked, "no artifact name shown while nothing is catalogued")
	_check(txt.contains("Subsurface anomaly"), "locked slots read 'Subsurface anomaly'")
	_check(not ("[b]" in txt or "[/b]" in txt), "no raw BBCode")
	for s in j.slots:
		_check(not s.recovered, "%s locked" % s.artifact_id)
		break
	j.show_planet("Mars")
	await _frames(2)
	_check(j.slots.size() == gs.get_total_count("Mars"), "Mars slots == total (%d)" % j.slots.size())
	_check(j._notice_row.visible, "Mars shows the locked-survey notice")
	_check(_fits(j.card, view), "card still fits with Mars (14 slots)")
	j.show_planet("Moon")
	await _frames(2)
	_check(not j._notice_row.visible, "Moon shows no locked notice")

	# ── 3. Journal, some found ────────────────────────────────────────────────────────────
	print("\n--- 3. Journal: partial collection ---")
	var moon_ids: Array = j._ids_for("Moon")
	var first_id: String = moon_ids[0]
	gs.recovered_artifacts.append(first_id)
	j.refresh()
	await _frames(2)
	var first_name := str(gs.artifacts_data[first_id]["name"])
	var found_slot: JournalSlot = null
	for s in j.slots:
		if s.artifact_id == first_id:
			found_slot = s
	_check(found_slot != null and found_slot.recovered, "recovered artifact slot is catalogued")
	_check(_all_text(found_slot).contains(first_name), "catalogued slot shows its name")
	var locked_names := false
	for s in j.slots:
		if s.artifact_id != first_id and _all_text(s).contains("Subsurface anomaly") == false:
			locked_names = true
	_check(not locked_names, "all other slots stay anonymous")
	var cats: Array = j._categories_for("Moon")
	_check(j.filter_buttons.size() == cats.size() + 1, "filters = All + %d categories" % cats.size())
	_check(j.filter_buttons[0].text.contains("1/7") or j.filter_buttons[0].text.contains("1/%d" % moon_ids.size()), "All filter shows found/total: " + j.filter_buttons[0].text)
	var cat_first: String = str(gs.artifacts_data[first_id]["category"])
	var expected := 0
	for id in moon_ids:
		if str(gs.artifacts_data[id]["category"]) == cat_first:
			expected += 1
	j._on_filter_pressed(cat_first)
	await _frames(2)
	_check(j.slots.size() == expected, "filter '%s' narrows to %d slots" % [cat_first, expected])
	_check(j.slots.size() < moon_ids.size() or cats.size() == 1, "filtered list is smaller than the full list")
	j._on_filter_pressed("")
	await _frames(2)
	_check(j.slots.size() == moon_ids.size(), "All filter restores every slot")

	# ── 4. Detail panel ───────────────────────────────────────────────────────────────────
	print("\n--- 4. Detail panel ---")
	j.select_artifact(first_id)
	await _frames(2)
	var d: Dictionary = gs.artifacts_data[first_id]
	_check(j.detail_name != null and j.detail_name.text == first_name, "detail shows the artifact name")
	var dtxt := _all_text(j._detail_col)
	_check(dtxt.contains(str(int(d.get("year", 0)))) and not dtxt.contains(str(int(d.get("year", 0))) + ".0"), "year printed as integer")
	_check(not ("[b]" in dtxt or "[/b]" in dtxt), "detail has no raw markup")
	_check(j.read_more_button != null, "READ MORE exists for an entry with a narrative")
	var more = j._detail_col.get_node_or_null("More")
	_check(more != null and not more.visible, "narrative hidden by default (progressive disclosure)")
	if j.read_more_button != null:
		j.read_more_button.pressed.emit()
		await _frames(1)
		var more2 = j._detail_col.get_node_or_null("More")
		_check(more2 != null and more2.visible, "READ MORE reveals the narrative")
		_check(j.read_more_button.text == "Show less", "button label flips to Show less")
	_check(JournalDrawer.has_story("apollo_lrv"), "apollo_lrv has a story (WATCH STORY offered)")
	_check(not JournalDrawer.has_story("kepler"), "kepler has no story -> no WATCH STORY button")
	var locked_id: String = moon_ids[moon_ids.size() - 1]
	j.select_artifact(locked_id)
	await _frames(2)
	var ltxt := _all_text(j._detail_col)
	_check(not ltxt.contains(str(gs.artifacts_data[locked_id]["name"])), "locked detail never names the artifact")
	_check(not ltxt.contains(str(gs.artifacts_data[locked_id]["category"])), "locked detail never reveals the category")
	_check(ltxt.contains("NOT CATALOGUED"), "locked detail says NOT CATALOGUED (words, not colour)")
	_check(j.story_button == null, "locked detail has no WATCH STORY")

	# ── 5. Full state + Esc ───────────────────────────────────────────────────────────────
	print("\n--- 5. Full collection and Esc ---")
	for id in moon_ids:
		if not gs.recovered_artifacts.has(id):
			gs.recovered_artifacts.append(id)
	j.refresh()
	await _frames(2)
	var all_found := true
	for s in j.slots:
		if not s.recovered:
			all_found = false
	_check(all_found, "every Moon slot is catalogued in the full state")
	_check(j._planet_count.text == "%02d / %02d" % [moon_ids.size(), moon_ids.size()], "planet count: " + j._planet_count.text)
	_check(_fits(j.card, view), "full state fits 1280x720")
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	j._input(ev)
	await _frames(1)
	_check(not j.is_open() and not j.visible, "Esc closes the drawer")
	_check(closed_seen[0] == 1, "closed signal emitted once")
	j.queue_free()
	gs.reset_progress()
	await _frames(1)

	# ── 6. HUD scene ──────────────────────────────────────────────────────────────────────
	print("\n--- 6. HUD scene ---")
	var hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await _frames(3)
	_check(hud.get_node_or_null("JournalModal") == null, "old JournalModal removed from the HUD scene")
	_check(hud.journal != null and hud.journal is JournalDrawer, "HUD owns a JournalDrawer")
	hud.toggle_journal()
	await _frames(3)
	_check(hud.journal.is_open(), "toggle_journal() opens the journal")
	_check(not hud.radar_panel.visible, "scanner hidden while the journal is open (B7)")
	hud.toggle_journal()
	await _frames(2)
	_check(not hud.journal.is_open(), "toggle_journal() closes the journal")
	_check(hud.radar_panel.visible, "scanner back after close")
	hud.queue_free()
	await _frames(2)

	# ── 7. Gallery ────────────────────────────────────────────────────────────────────────
	print("\n--- 7. Gallery ---")
	for sz in [Vector2i(1280, 720), Vector2i(1366, 768)]:
		root.size = sz
		var gal = (load(GALLERY_SCENE) as PackedScene).instantiate()
		root.add_child(gal)
		await _frames(4)
		var v := Vector2(sz)
		_check(_fits(gal.rail_panel, v), "%s: rail fits (%s)" % [str(sz), str(gal.rail_panel.get_global_rect())])
		_check(_fits(gal.info_panel, v), "%s: info panel fits" % str(sz))
		for b in gal._craft_buttons:
			_check(_fits(b, v), "%s: rail button '%s' on screen" % [str(sz), b.text])
		_check(not gal.rail_panel.get_global_rect().intersects(gal.info_panel.get_global_rect()), "%s: rail and info do not overlap" % str(sz))
		if sz.x == 1280:
			_check(gal.title_label.text == "Dawn Spacecraft", "header shows the craft name")
			gal.select_next_spacecraft()
			await _frames(2)
			_check(gal.current_craft_index == 1 and gal.title_label.text == "NEAR Shoemaker", "next craft updates the header")
			_check(gal._craft_buttons[1].button_pressed, "rail shows the selected craft")
			gal.toggle_component_inspector()
			await _frames(3)
			_check(gal.inspector_hud != null, "inspector opens")
			_check(not gal.rail_panel.visible and not gal.info_panel.visible, "rail and info step aside for the inspector")
			gal.inspector_hud.close_inspector()
			await _frames(2)
			_check(gal.rail_panel.visible and gal.info_panel.visible, "rail and info return after the inspector closes")
		gal.queue_free()
		await _frames(2)
	root.size = Vector2i(1280, 720)
	var gsrc := _source("res://scripts/spacecraft/spacecraft_gallery.gd")
	var raw_keys := 0
	for line in gsrc.split("\n"):
		var t := line.strip_edges()
		if not t.begins_with("#") and t.contains("KEY_"):
			raw_keys += 1
	_check(raw_keys == 0, "gallery has no raw KEY_ literals (%d)" % raw_keys)

	# ── 8. Inspector contract ─────────────────────────────────────────────────────────────
	print("\n--- 8. Inspector ---")
	var target := Node3D.new()
	target.set_meta("component_name", "Test Craft")
	target.set_meta("component_desc", "A test craft.")
	for i in 3:
		var c := Node3D.new()
		c.set_meta("component_name", "Part %d" % i)
		c.set_meta("component_desc", "Description %d" % i)
		c.set_meta("component_spec", "Spec %d" % i)
		target.add_child(c)
	root.add_child(target)
	var insp := SpacecraftInspectorHUD.new()
	root.add_child(insp)
	insp.open_inspector(target, "test")
	await _frames(3)
	_check(insp._components.size() == 4, "components scanned (%d)" % insp._components.size())
	_check(insp.comp_spec_label.text.begins_with("SPECIFICATIONS:"), "spec label contract kept")
	var n0 := insp.comp_name_label.text
	insp._on_next_pressed()
	_check(insp.comp_name_label.text != n0, "next changes component")
	insp._on_prev_pressed()
	_check(insp.comp_name_label.text == n0, "prev returns")
	_check(insp.counter_label.text.begins_with("COMPONENT 01 / 04"), "counter format: " + insp.counter_label.text)
	_check(not insp.comp_name_label.text.begins_with("•"), "no glyph bullet in the component name")
	_check(_fits(insp.panel, Vector2(1280, 720)), "inspector panel fits 1280x720 (%s)" % str(insp.panel.get_global_rect()))
	var closed := [false]
	insp.inspection_closed.connect(func() -> void: closed[0] = true)
	insp.close_inspector()
	_check(closed[0], "inspection_closed emitted")
	target.queue_free()
	await _frames(2)

	# ── 9. Source hygiene ─────────────────────────────────────────────────────────────────
	print("\n--- 9. Source hygiene (tokens only) ---")
	for path in ["res://scripts/ui/components/journal_drawer.gd", "res://scripts/ui/components/journal_slot.gd", "res://scripts/ui/spacecraft_inspector_hud.gd"]:
		var src := _source(path)
		_check(not src.contains("add_theme_font_size_override"), "%s: no font-size overrides" % path.get_file())
		_check(not src.contains("Color(0.") and not src.contains("Color(1."), "%s: no colour literals" % path.get_file())

	print("\n==================================================")
	if failures == 0:
		print("ALL PHASE 6 COLLECTION UI CHECKS PASSED")
	else:
		printerr("%d CHECK(S) FAILED" % failures)
	print("==================================================")
	quit(1 if failures > 0 else 0)
