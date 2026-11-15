extends SceneTree
## Phase 5 regression: main menu (chapters, Mars lock, modals, Esc).
## godot --headless --path . --script res://scripts/test_phase5_menu.gd
var _fails := 0
func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1
func _key(code: Key) -> void:
	for p in [true, false]:
		var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = p; root.push_input(e)
func _frames(n: int = 3) -> void:
	for i in n: await process_frame
func _initialize() -> void:
	_run()
func _run() -> void:
	print("--- Phase 5: main menu ---")
	var gs: Node = root.get_node("GameState")
	gs.reset_progress()
	var menu: Control = (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu); current_scene = menu
	await _frames(4)
	_check(menu._moon_btn != null and not menu._moon_btn.disabled, "Moon chapter is playable")
	_check(menu._mars_btn.disabled, "Mars chapter is locked on a fresh game")
	_check(menu._mars_btn._lock_reason != "", "Mars shows WHY it is locked (not colour alone)")
	_check(menu.get_viewport().gui_get_focus_owner() == menu._moon_btn, "Moon chapter has initial focus")
	# no gallery, no old nodes
	_check(menu.find_child("PlayMoonBtn", true, false) == null, "old integrated1 menu nodes are gone")
	var has_gallery := false
	for b in menu.find_children("*", "Button", true, false):
		if "gallery" in String(b.text).to_lower(): has_gallery = true
	_check(not has_gallery, "no Spacecraft gallery entry (D6)")
	# Unlock rule
	menu._on_mars_pressed(); await _frames(2)
	_check(current_scene == menu and not gs.is_planet_unlocked("Mars"), "pressing locked Mars does nothing and does not unlock it")
	gs.unlock_planet("Mars")
	menu._update_chapters()
	_check(not menu._mars_btn.disabled, "Mars unlocks once the planet is unlocked")
	gs.reset_progress(); menu._update_chapters()
	# Settings + manual + credits via buttons
	menu._show_settings(); await _frames(2)
	_check(menu._settings.visible and menu._settings._fullscreen_btn != null, "Settings opens (with Fullscreen row)")
	_key(KEY_ESCAPE); await _frames(3)
	_check(not menu._settings.visible, "Esc closes Settings")
	menu._show_field_manual(); await _frames(2)
	_check(menu._manual.visible, "Field manual opens")
	_key(KEY_ESCAPE); await _frames(3)
	_check(not menu._manual.visible, "Esc closes the manual")
	var before: int = menu.find_children("*", "ModalShell", true, false).size()
	menu._show_credits(); await _frames(2)
	var shells: Array = menu.find_children("*", "ModalShell", true, false)
	_check(shells.size() == before + 1 and shells[shells.size() - 1].visible, "Credits opens")
	var txt: String = menu._credits_text()
	_check("Lunar Sample Compendium" in txt and "IBM Plex" in txt, "Credits carry both projects' attributions")
	_key(KEY_ESCAPE); await _frames(3)
	# Tree is never left paused by the menu
	_check(not paused, "menu leaves the tree unpaused")
	print("--- %s (%d failure%s) ---" % ["PASS" if _fails == 0 else "FAIL", _fails, "" if _fails == 1 else "s"])
	quit(1 if _fails > 0 else 0)
