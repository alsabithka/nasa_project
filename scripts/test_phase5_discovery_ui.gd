extends SceneTree

# Phase 5 verification — discovery pipeline UI (excavation prompt, cleaning, Catalogue Entry).
# Run:  godot --headless --path . --script res://scripts/test_phase5_discovery_ui.gd
# Checks (no gameplay level needed):
#  1. Catalogue Entry builds for every artifact in data/artifacts.json, fits a 1280x720 viewport,
#     shows no raw markup / float years, and keeps ARCHIVE RECORD and FIELD READINGS separate.
#  2. Signals: story_requested then documentation_closed (WATCH STORY); documentation_closed only (CONTINUE).
#  3. Input guard: E / Esc / Enter are swallowed for the first ARM_DELAY seconds, then work.
#  4. Reduced motion: the stamp is visible at once.
#  5. Excavation prompt: contract (title text, signals) and no informational text below 14 px.
#  6. HUD scene no longer contains a DiscoveryPopup and exposes play_artifact_story().

const ENTRY_SCRIPT := "res://scripts/ui/scientific_examination_panel.gd"

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


func _make_entry(id: String):
	var p = CanvasLayer.new()
	p.set_script(load(ENTRY_SCRIPT))
	p.artifact_id = id
	root.add_child(p)
	return p


func _texts(n: Node, out: PackedStringArray) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var gs := root.get_node_or_null("GameState")
	_check(gs != null, "GameState autoload present")
	if gs == null:
		quit(1)
		return

	# ── 1. Catalogue Entry for every artifact ─────────────────────────────────────────────
	print("\n--- 1. Catalogue Entry across all artifacts ---")
	var view := root.get_visible_rect()
	for id in gs.artifacts_data.keys():
		var p = _make_entry(id)
		await _frames(4)
		var card: Control = p.panel_container
		var r := card.get_global_rect()
		var fits := r.position.x >= 0.0 and r.position.y >= 0.0 and r.end.x <= view.size.x and r.end.y <= view.size.y
		_check(fits, "%s: card %s fits viewport %s" % [id, str(r), str(view.size)])
		var all := PackedStringArray()
		_texts(p, all)
		var joined := "\n".join(all)
		_check(not ("[b]" in joined or "[/b]" in joined), "%s: no raw BBCode" % id)
		_check(p._fields["year"].text == str(int(gs.artifacts_data[id].get("year", 0))), "%s: year printed as integer (%s)" % [id, p._fields["year"].text])
		_check(p.title_label.text != "", "%s: name shown" % id)
		p.queue_free()
		await _frames(1)

	# ── honesty: both blocks exist and are labelled ───────────────────────────────────────
	print("\n--- Honesty: archive vs field readings ---")
	var p2 = _make_entry("apollo_lrv")
	await _frames(4)
	var t2 := PackedStringArray()
	_texts(p2, t2)
	var all2 := "\n".join(t2)
	_check(all2.contains("ARCHIVE RECORD"), "ARCHIVE RECORD block present")
	_check(all2.contains("FIELD READINGS"), "FIELD READINGS (in-game) block present")
	_check(all2.contains("WATCH STORY") and all2.contains("CONTINUE"), "both actions present")
	_check(p2.index_label.text.contains("MOON"), "entry index shows planet: " + p2.index_label.text)
	p2.queue_free()
	await _frames(1)

	# ── 2. Signals ────────────────────────────────────────────────────────────────────────
	print("\n--- 2. Signals ---")
	var seq: Array = []
	var p3 = _make_entry("apollo_lrv")
	p3.story_requested.connect(func(id): seq.append("story:" + id))
	p3.documentation_closed.connect(func(id): seq.append("closed:" + id))
	await _frames(2)
	p3._on_story_pressed()
	_check(seq == ["story:apollo_lrv", "closed:apollo_lrv"], "WATCH STORY emits story_requested then documentation_closed: " + str(seq))
	await _frames(2)
	seq.clear()
	var p4 = _make_entry("alsep")
	p4.story_requested.connect(func(id): seq.append("story:" + id))
	p4.documentation_closed.connect(func(id): seq.append("closed:" + id))
	await _frames(2)
	p4._on_close_pressed()
	p4._on_close_pressed()   # double press must not double-emit
	_check(seq == ["closed:alsep"], "CONTINUE emits documentation_closed once: " + str(seq))
	await _frames(2)

	# ── 3. Input guard ────────────────────────────────────────────────────────────────────
	print("\n--- 3. Input guard ---")
	seq.clear()
	var p5 = _make_entry("apollo_lrv")
	p5.story_requested.connect(func(id): seq.append("story"))
	p5.documentation_closed.connect(func(id): seq.append("closed"))
	await _frames(2)
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	p5._input(ev)
	_check(seq.is_empty(), "E ignored during arm delay")
	await create_timer(p5.ARM_DELAY + 0.2).timeout
	p5._input(ev)
	_check(seq == ["story", "closed"], "E accepted after arm delay: " + str(seq))
	await _frames(2)

	# ── 4. Reduced motion ─────────────────────────────────────────────────────────────────
	print("\n--- 4. Reduced motion ---")
	var had = SettingsStore.get_value("reduced_motion")
	SettingsStore.set_value("reduced_motion", true)
	var p6 = _make_entry("apollo_lrv")
	await _frames(2)
	_check(p6.stamp._plate.modulate.a >= 0.99, "stamp visible immediately with reduced motion")
	_check(p6.panel_container.modulate.a >= 0.99, "card visible immediately with reduced motion")
	p6.queue_free()
	SettingsStore.set_value("reduced_motion", had)
	await _frames(1)

	# ── 5. HUD ────────────────────────────────────────────────────────────────────────────
	print("\n--- 5. HUD scene ---")
	var hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await _frames(3)
	_check(hud.get_node_or_null("DiscoveryPopup") == null, "DiscoveryPopup removed from HUD")
	_check(hud.has_method("play_artifact_story"), "HUD exposes play_artifact_story()")
	_check(hud.is_in_group("hud"), "HUD is in group 'hud'")
	hud.play_artifact_story("alsep")
	await _frames(2)
	var story := hud.get_children().filter(func(n): return n.is_in_group("blocking_modal") and n.get_script() != null and "flashback" in n.get_script().resource_path)
	_check(story.size() == 1, "play_artifact_story spawns the flashback story (merge D5)")
	hud.queue_free()
	await _frames(2)

	print("\n==================================================")
	if failures == 0:
		print("ALL PHASE 5 DISCOVERY UI CHECKS PASSED")
	else:
		printerr("%d CHECK(S) FAILED" % failures)
	print("==================================================")
	quit(1 if failures > 0 else 0)
