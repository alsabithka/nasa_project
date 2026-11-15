## Phase 7: Catalogue Entry as opened by the real artifact pipeline.
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase7_catalogue_screen.gd -- 1280 720 out_dir [artifact_id]
extends SceneTree
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]), int(a[1]))
	var out: String = a[2]
	var id: String = a[3] if a.size() > 3 else "apollo_lrv"
	root.size = size
	DisplayServer.window_set_size(size)
	_run(size, out, id)
func _run(size: Vector2i, out: String, id: String) -> void:
	var world := ColorRect.new()
	world.color = Color(0.16, 0.17, 0.2)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)
	var hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var art = (load("res://scenes/artifact/artifact.tscn") as PackedScene).instantiate()
	art.artifact_id = id
	root.add_child(art)
	for i in 6: await process_frame
	art._is_player_in_zone = true
	art._set_state(art.ArtifactState.EXPOSED)
	for i in 10: await process_frame
	root.get_texture().get_image().save_png("%s/prompt_exposed_%dx%d.png" % [out, size.x, size.y])
	art._start_cleaning()
	art.on_cleaning_done(id)
	for i in 40: await process_frame
	root.get_texture().get_image().save_png("%s/catalogue_%dx%d.png" % [out, size.x, size.y])
	quit()
