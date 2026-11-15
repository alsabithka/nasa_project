## Phase 8: flashback screenshots.
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase8_flashback_screens.gd -- 1280 720 out_dir [artifact_id]
extends SceneTree
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]), int(a[1]))
	root.size = size
	DisplayServer.window_set_size(size)
	_run(size, a[2], a[3] if a.size() > 3 else "apollo_lrv")
func _run(size: Vector2i, out: String, id: String) -> void:
	var world := ColorRect.new()
	world.color = Color(0.16, 0.17, 0.2)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)
	var fb = (load("res://scenes/ui/flashback.tscn") as PackedScene).instantiate()
	fb.artifact_id = id
	root.add_child(fb)
	for i in 8: await process_frame
	root.get_texture().get_image().save_png("%s/flashback_scene1_%dx%d.png" % [out, size.x, size.y])
	fb.scene_timer = 99.0
	for i in 8: await process_frame
	root.get_texture().get_image().save_png("%s/flashback_scene2_%dx%d.png" % [out, size.x, size.y])
	quit()
