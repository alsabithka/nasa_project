## Phase 6 screenshot helper. Renders the collection screens in one run.
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase6_screens.gd -- \
##       1280 720 /tmp/p6
## Writes: journal_empty, journal_partial, journal_full, journal_mars, journal_filter, journal_locked_detail,
##         (the gallery and inspector shots were removed in the merge, D6)
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]) if a.size() > 0 else 1280, int(a[1]) if a.size() > 1 else 720)
	var out: String = a[2] if a.size() > 2 else "/tmp/p6"
	root.size = size
	DisplayServer.window_set_size(size)
	DirAccess.make_dir_recursive_absolute(out)
	_run(out)


func _shot(path: String) -> void:
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)


func _run(out: String) -> void:
	var gs = root.get_node("GameState")
	gs.reset_progress()

	var world := ColorRect.new()                      # stand-in for the 3D world behind the journal
	world.color = Color(0.16, 0.17, 0.2)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)

	var j := JournalDrawer.new()
	root.add_child(j)
	await process_frame
	j.open("Moon")
	await _shot(out + "/journal_empty.png")

	var moon: Array = j._ids_for("Moon")
	for i in 3:
		gs.recovered_artifacts.append(moon[i])
	j.refresh()
	j.select_artifact(moon[0])
	await _shot(out + "/journal_partial.png")

	j.read_more_button.pressed.emit()
	await _shot(out + "/journal_read_more.png")

	var cat: String = str(gs.artifacts_data[moon[0]]["category"])
	j._on_filter_pressed(cat)
	await _shot(out + "/journal_filter.png")
	j._on_filter_pressed("")

	j.select_artifact(moon[moon.size() - 1])
	await _shot(out + "/journal_locked_detail.png")

	j.show_planet("Mars")
	await _shot(out + "/journal_mars.png")

	for id in moon:
		if not gs.recovered_artifacts.has(id):
			gs.recovered_artifacts.append(id)
	j.show_planet("Moon")
	await _shot(out + "/journal_full.png")
	j.queue_free()
	world.queue_free()
	gs.reset_progress()
	await process_frame

	quit(0)
