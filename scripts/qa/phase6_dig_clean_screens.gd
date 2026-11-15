## Phase 6 screenshots: dig (start / mid / won) and clean (0 / 50 / 100 %).
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/phase6_dig_clean_screens.gd -- 1280 720 /tmp/p6 [artifact_id]
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]) if a.size() > 0 else 1280, int(a[1]) if a.size() > 1 else 720)
	var out: String = a[2] if a.size() > 2 else "/tmp/p6"
	var id: String = a[3] if a.size() > 3 else "apollo_lrv"
	root.size = size
	DisplayServer.window_set_size(size)
	DirAccess.make_dir_recursive_absolute(out)
	_run(size, out, id)

func _shot(path: String) -> void:
	for i in 14:
		await process_frame
	root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)

func _run(size: Vector2i, out: String, id: String) -> void:
	var world := ColorRect.new()  # stand-in for the 3D world behind the UI
	world.color = Color(0.16, 0.17, 0.2)
	world.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(world)
	var tag := "%dx%d" % [size.x, size.y]

	var dig = (load("res://scenes/ui/dig_minigame.tscn") as PackedScene).instantiate()
	dig.artifact_id = id
	root.add_child(dig)
	await _shot("%s/dig_start_%s.png" % [out, tag])
	var n := 0
	for i in dig.tiles.size():
		if not dig.tiles[i].is_artifact and n < 14:
			dig.tiles[i].layers = max(0, dig.tiles[i].layers - 1)
			if dig.tiles[i].layers == 0: dig.tiles[i].cleared = true
			dig.tiles[i].crack_anim = 1.0
			n += 1
	for i in dig.tiles.size():
		if dig.tiles[i].is_artifact and i % 3 == 0:
			dig.tiles[i].cleared = true
	dig.combo_count = 3; dig._update_combo_ui(); dig._check_win_condition()
	await _shot("%s/dig_mid_%s.png" % [out, tag])
	for t in dig.tiles:
		if t.is_artifact: t.cleared = true
	dig._check_win_condition()
	dig.victory_timer = -10.0  # keep it on screen for the shot
	await _shot("%s/dig_won_%s.png" % [out, tag])
	dig.queue_free()
	await process_frame

	for pct in [0, 50, 100]:
		var c = (load("res://scenes/ui/dig_clean_ui.tscn") as PackedScene).instantiate()
		c.artifact_id = id
		root.add_child(c)
		await process_frame
		c._set_scrubbing(pct > 0 and pct < 100)
		var y := 0
		while c.percent_clean < float(pct) and pct > 0 and not c.is_complete:
			for x in range(0, 440, 8):
				c._apply_brush(Vector2(x, y))
			y += 10
			c._calculate_clean_percentage()
			if y > 240: break
		c._hovering = pct == 50
		c._hover_pos = Vector2(220, 120)
		await _shot("%s/clean_%d_%s.png" % [out, pct, tag])
		c.queue_free()
		await process_frame
	quit()
