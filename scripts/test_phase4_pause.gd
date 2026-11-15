extends SceneTree
## Phase 4 regression: pause / settings / restart / Esc policy.
## godot --headless --path . --script res://scripts/test_phase4_pause.gd

var _fails := 0

func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)

func _frames(n: int = 3) -> void:
	for i in n:
		await process_frame

func _initialize() -> void:
	_run()

func _run() -> void:
	print("--- Phase 4: pause / settings / restart ---")
	InputSetup.ensure()
	SettingsStore.set_value("first_run_shown", true)  # keep the first-run manual out of this test
	var scene: PackedScene = load("res://scenes/levels/moon.tscn")
	var level: Node = scene.instantiate()
	root.add_child(level)
	current_scene = level
	await _frames(8)
	var hud: Node = get_first_node_in_group("hud")
	_check(hud != null, "HUD present in the Moon level")
	var pm = hud._pause_menu
	_check(pm != null, "pause menu instantiated")
	var music: Node = level.get_node_or_null("LevelBGMPlayer")
	_check(music != null and music.process_mode == Node.PROCESS_MODE_ALWAYS, "level music keeps playing while paused (D11)")

	# Esc: gameplay -> pause
	_key(KEY_ESCAPE); await _frames()
	_check(pm.is_open() and paused, "Esc in gameplay opens pause and pauses the tree")
	# Esc again: resume (and does not reopen)
	_key(KEY_ESCAPE); await _frames()
	_check(not pm.is_open() and not paused, "Esc in pause resumes (no re-open on the same press)")

	# Journal hotkey inert while a blocking modal is visible
	var fake := CanvasLayer.new()
	fake.add_to_group("blocking_modal")
	root.add_child(fake)
	_key(KEY_J); await _frames()
	_check(not hud.journal.is_open(), "journal hotkey inert while a blocking modal is open")
	_key(KEY_ESCAPE); await _frames()
	_check(not pm.is_open(), "Esc does not open pause while a blocking modal is open")
	fake.queue_free(); await _frames()
	_key(KEY_J); await _frames()
	_check(hud.journal.is_open(), "journal opens once no modal is blocking")
	_key(KEY_ESCAPE); await _frames()
	_check(not hud.journal.is_open() and not pm.is_open(), "Esc closes the journal first, does not open pause")

	# Settings: Esc closes only settings
	_key(KEY_ESCAPE); await _frames()
	pm._on_settings(); await _frames()
	var st = pm._settings
	_check(st != null and st.visible, "Settings opens from pause")
	_check(st._fullscreen_btn != null, "Settings has a Fullscreen row (D10)")
	_key(KEY_ESCAPE); await _frames(4)
	_check(not st.visible and pm.is_open(), "Esc in Settings closes Settings only; pause stays open")
	# Field manual
	pm._on_controls(); await _frames()
	_check(pm._manual.visible, "Field manual opens from pause")
	_key(KEY_ESCAPE); await _frames(4)
	_check(not pm._manual.visible and pm.is_open(), "Esc in Field manual closes it only")

	# Fullscreen persistence (headless: value stored, window untouched)
	SettingsStore.set_value("fullscreen", true); SettingsStore.save(); SettingsStore.reload()
	_check(bool(SettingsStore.get_value("fullscreen")), "fullscreen setting persists")
	SettingsStore.set_value("fullscreen", false); SettingsStore.save()

	# Restart mission asks for confirmation, Cancel is the default focus
	pm._on_restart(); await _frames(3)
	var dlg: ConfirmDialog = null
	for c in root.get_children():
		if c is ConfirmDialog: dlg = c
	_check(dlg != null, "Restart opens a ConfirmDialog")
	_key(KEY_ESCAPE); await _frames(3)
	_check(pm.is_open() and paused, "Esc in the confirm dialog cancels; pause stays open")
	pm._on_restart(); await _frames(3)
	for c in root.get_children():
		if c is ConfirmDialog: dlg = c
	dlg.confirmed.emit(); await _frames(6)
	_check(not paused, "Restart unpauses before reloading the scene")
	_check(current_scene != null and current_scene != level, "Restart reloaded the current scene")

	print("--- %s (%d failure%s) ---" % ["PASS" if _fails == 0 else "FAIL", _fails, "" if _fails == 1 else "s"])
	quit(1 if _fails > 0 else 0)
