extends SceneTree
## Phase 7: the discovery loop on the Moon with the three real artifacts.
## scan -> HUD key-cap prompt -> [E] dig -> [E] clean -> Catalogue Entry -> CONTINUE / WATCH STORY
## -> registered -> journal -> mission complete -> Mars unlock.
## godot --headless --path . --script res://scripts/test_phase7_discovery_loop.gd
var _fails := 0
func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1
func _frames(n: int = 3) -> void:
	for i in n: await process_frame
func _entry(art: Node) -> Node:
	for c in art.get_children():
		if c is CanvasLayer and c.has_signal("documentation_closed"):
			return c
	return null
func _initialize() -> void:
	_run()
func _run() -> void:
	print("--- Phase 7: discovery loop ---")
	var gs: Node = root.get_node("GameState")
	gs.reset_progress()
	var hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	hud.current_planet = "Moon"
	root.add_child(hud)
	await _frames(3)
	var arts := {}
	for id in ["apollo_lrv", "apollo_lm_descent_stage", "alsep"]:
		var a = (load("res://scenes/artifact/artifact.tscn") as PackedScene).instantiate()
		a.artifact_id = id
		root.add_child(a)
		arts[id] = a
	await _frames(3)
	var wh: WorldHud = hud.world_hud
	var art = arts["apollo_lrv"]

	# prompt: DIG_SITE inside the zone
	art._is_player_in_zone = true
	art._set_state(art.ArtifactState.DIG_SITE)
	_check(wh._prompt_panel.visible and wh._prompt_text.text == "Excavate subsurface anomaly", "DIG_SITE shows HUD prompt: '%s'" % wh._prompt_text.text)
	_check(wh._prompt_cap.action_name == "interact", "prompt key-cap reads the 'interact' action")
	_check(not art.prompt_label.visible, "old Label3D prompt stays hidden (node kept)")
	art._is_player_in_zone = false
	art._refresh_prompt()
	_check(not wh._prompt_panel.visible, "prompt hides when the player leaves the zone")
	art._is_player_in_zone = true
	art._refresh_prompt()
	art._start_digging_minigame()
	_check(not wh._prompt_panel.visible, "prompt hidden while the dig mini-game is open")
	art._on_dig_minigame_finished()
	_check(art.current_state == art.ArtifactState.EXPOSED and wh._prompt_text.text == "Recover and decontaminate specimen", "EXPOSED prompt: '%s'" % wh._prompt_text.text)
	art._start_cleaning()
	_check(not wh._prompt_panel.visible, "prompt hidden while cleaning")
	art.on_cleaning_done("apollo_lrv")
	await _frames(3)
	var panel = _entry(art)
	_check(panel != null, "Catalogue Entry opens after cleaning")
	_check(not gs.is_artifact_recovered("apollo_lrv"), "NOT registered while the entry is open (registration on close)")
	_check(art.current_state == art.ArtifactState.CLEANING, "artifact still CLEANING while the entry is open")
	_check(hud.is_modal_blocking(), "HUD reports a blocking modal (journal/pause hotkeys inert)")
	panel._armed = true
	panel._on_close_pressed()
	await _frames(3)
	_check(gs.is_artifact_recovered("apollo_lrv") and art.current_state == art.ArtifactState.IDENTIFIED, "CONTINUE registers the specimen and identifies it")
	_check(gs.get_recovered_count("Moon") == 1, "recovered count = 1")

	# WATCH STORY path
	var art2 = arts["apollo_lm_descent_stage"]
	art2._is_player_in_zone = true
	art2._set_state(art2.ArtifactState.EXPOSED)
	art2._start_cleaning()
	art2.on_cleaning_done("apollo_lm_descent_stage")
	await _frames(3)
	var p2 = _entry(art2)
	p2._on_story_pressed()
	await _frames(3)
	_check(gs.is_artifact_recovered("apollo_lm_descent_stage"), "WATCH STORY also registers the specimen")
	var fb := hud.get_children().filter(func(n): return n.is_in_group("blocking_modal") and n.get_script() != null and "flashback" in n.get_script().resource_path)
	_check(fb.size() == 1, "WATCH STORY opens the flashback through the HUD")
	for n in fb: n.queue_free()
	await _frames(2)

	# last artifact -> mission complete + Mars unlock
	var art3 = arts["alsep"]
	art3._set_state(art3.ArtifactState.EXPOSED)
	art3._start_cleaning()
	art3.on_cleaning_done("alsep")
	await _frames(3)
	_entry(art3)._on_close_pressed()
	await _frames(4)
	_check(gs.get_recovered_count("Moon") == 3, "all three Moon artifacts catalogued")
	_check(hud.completion_modal.visible, "mission-complete modal is shown")
	_check(hud.travel_mars_btn != null and hud.travel_mars_btn.visible, "Travel to Mars button offered")
	_check(gs.is_planet_unlocked("Mars"), "Mars unlocked")
	_check(hud.journal != null, "journal drawer exists for the catalogued entries")
	print("--- Phase 7: %s (%d failures) ---" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(_fails)
