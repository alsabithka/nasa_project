## HUD area budget check (merge plan 6.4).
## xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/measure_hud.gd -- <w> <h>
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[0]) if a.size() > 0 else 1280, int(a[1]) if a.size() > 1 else 720)
	root.size = size
	DisplayServer.window_set_size(size)
	var inst = (load("res://scenes/levels/moon.tscn") as PackedScene).instantiate()
	root.add_child(inst)
	for i in 40: await process_frame
	var hud = get_first_node_in_group("hud")
	var zones := {}
	zones["mission (top-left)"] = hud.world_hud.get_child(0).get_global_rect()
	zones["buttons (top-right)"] = hud.world_hud.journal_button.get_parent().get_parent().get_global_rect()
	zones["scanner (bottom-right)"] = hud.world_hud.scanner.get_global_rect()
	var helmet := get_first_node_in_group("terrain").get_node_or_null("AstronautHelmetHUD")
	var tele: Control = null
	if helmet:
		for c in helmet.get_children():
			for g in c.get_children():
				if g is HudPanel: tele = g
	if tele: zones["telemetry (bottom-left)"] = tele.get_global_rect()
	var screen: float = size.x * size.y
	var total := 0.0
	print("== HUD zones at %dx%d ==" % [size.x, size.y])
	for k in zones:
		var r: Rect2 = zones[k]
		total += r.get_area()
		print("  %-26s %4dx%-4d  %.1f%%" % [k, r.size.x, r.size.y, r.get_area() / screen * 100.0])
	var keys := zones.keys()
	var overlaps := 0
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			if (zones[keys[i]] as Rect2).intersects(zones[keys[j]]):
				print("  OVERLAP: ", keys[i], " x ", keys[j]); overlaps += 1
	var off := 0
	for k in zones:
		if not Rect2(Vector2.ZERO, Vector2(size)).encloses(zones[k]): print("  OFF-SCREEN: ", k); off += 1
	print("  TOTAL %.1f%% of screen | overlaps=%d off-screen=%d" % [total / screen * 100.0, overlaps, off])
	quit()
