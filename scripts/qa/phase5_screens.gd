## Phase 5 screenshot helper. Renders the discovery-pipeline screens in one run.
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase5_screens.gd -- \
##       1280 720 /tmp/p5 [artifact_id]
## Writes: excavation.png, clean_0.png, clean_50.png, clean_100.png, catalogue.png
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]) if a.size() > 0 else 1280, int(a[1]) if a.size() > 1 else 720)
	var out: String = a[2] if a.size() > 2 else "/tmp/p5"
	var id: String = a[3] if a.size() > 3 else "apollo_lrv"
	root.size = size
	DisplayServer.window_set_size(size)
	DirAccess.make_dir_recursive_absolute(out)
	_run(size, out, id)


func _shot(path: String) -> void:
	for i in 12:
		await process_frame
	root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)


func _run(size: Vector2i, out: String, id: String) -> void:
	var world := ColorRect.new()                       # stand-in for the 3D world behind the UI
	world.color = Color(0.16, 0.17, 0.2)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)

	var menu = CanvasLayer.new()
	menu.set_script(load("res://scripts/ui/excavation_menu.gd"))
	root.add_child(menu)
	menu.set_anomaly_details("", 6.5, "Strong Ferromagnetic & Aluminum Eddy Response")
	await _shot(out + "/excavation.png")
	menu.queue_free()
	await process_frame

	for pct in [0, 50, 100]:
		var scn := load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene
		var clean = scn.instantiate()
		clean.artifact_id = id
		root.add_child(clean)
		await process_frame
		clean.set_progress_preview(pct / 100.0)
		await _shot(out + "/clean_%d.png" % pct)
		clean.queue_free()
		await process_frame

	var p = CanvasLayer.new()
	p.set_script(load("res://scripts/ui/scientific_examination_panel.gd"))
	p.artifact_id = id
	root.add_child(p)
	await create_timer(1.4).timeout                    # entrance + stamp
	await _shot(out + "/catalogue.png")
	quit(0)
