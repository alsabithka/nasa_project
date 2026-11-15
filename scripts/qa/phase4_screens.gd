## Phase 4 screenshots: pause, settings, field manual, restart confirm, over the Moon HUD.
## xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase4_screens.gd -- <w> <h> <out_dir>
extends SceneTree

func _initialize() -> void:
	_run()

func _snap(dir: String, name: String) -> void:
	for i in 6: await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [dir, name])
	print("QA: saved ", name)

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]), int(a[1]))
	var dir: String = a[2]
	root.size = size
	DisplayServer.window_set_size(size)
	InputSetup.ensure()
	SettingsStore.set_value("first_run_shown", true)
	var level: Node = (load("res://scenes/levels/moon.tscn") as PackedScene).instantiate()
	root.add_child(level); current_scene = level
	for i in 30: await process_frame
	var hud = get_first_node_in_group("hud")
	var pm = hud._pause_menu
	pm.show_pause()
	await _snap(dir, "pause_%dx%d" % [size.x, size.y])
	pm._on_settings()
	await _snap(dir, "settings_%dx%d" % [size.x, size.y])
	pm._settings.close()
	pm._on_controls()
	await _snap(dir, "manual_%dx%d" % [size.x, size.y])
	pm._manual.close()
	pm._on_restart()
	await _snap(dir, "restart_confirm_%dx%d" % [size.x, size.y])
	quit()
