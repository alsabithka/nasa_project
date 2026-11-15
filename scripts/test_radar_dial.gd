extends SceneTree
## RadarDial regression test (merge P3/P9).  godot --headless --path . --script res://scripts/test_radar_dial.gd

var _fails := 0

func _check(ok: bool, msg: String) -> void:
	print(("  [PASS] " if ok else "  [FAIL] ") + msg)
	if not ok: _fails += 1

func _initialize() -> void:
	print("--- RadarDial ---")
	# Pure maths -------------------------------------------------------------------------
	var off := RadarDial.relative_offset(Vector3(-85, 0, 0), Vector3(85, 0, 0), 180.0)
	_check(is_equal_approx(off.x, 10.0), "toroidal wrap: artifact across the +x seam is 10 m east (got %.2f)" % off.x)
	off = RadarDial.relative_offset(Vector3(0, 0, 85), Vector3(0, 0, -85), 180.0)
	_check(is_equal_approx(off.y, -10.0), "toroidal wrap: artifact across the z seam is 10 m north (got %.2f)" % off.y)
	off = RadarDial.relative_offset(Vector3(30, 0, 0), Vector3(0, 0, 0), 180.0)
	_check(is_equal_approx(off.x, 30.0), "no wrap for a nearby artifact")
	var d := RadarDial.blip_dial_offset(100.0, 0.0, 65.0, 60.0)
	_check(is_equal_approx(d.length(), 0.94 * 60.0), "blip distance clamps to 0.94 of the radius")

	# Scene-level -------------------------------------------------------------------------
	var player := CharacterBody3D.new()
	player.add_to_group("player")
	root.add_child(player)
	var terrain := Node3D.new()
	terrain.set_script(load("res://scripts/qa/stub_terrain.gd"))
	terrain.add_to_group("terrain")
	root.add_child(terrain)
	var arts := {}
	for spec in [["near", Vector3(3.9, 0, 0)], ["mid", Vector3(5.0, 0, 0)], ["far", Vector3(60, 0, 0)],
			["outside", Vector3(-40, 0, 0)], ["seam", Vector3(0, 0, 0)]]:
		var a := Node3D.new()
		a.set_script(load("res://scripts/qa/stub_artifact.gd"))
		a.artifact_id = "test_" + spec[0]
		a.add_to_group("artifacts")
		root.add_child(a)
		a.global_position = spec[1]
		arts[spec[0]] = a
	player.global_position = Vector3(0, 0, 0)
	arts["seam"].global_position = Vector3(0, 0, 0)

	var dial := RadarDial.new()
	root.add_child(dial)
	await process_frame
	dial.refresh_artifacts()
	dial.update_blips()
	# near(3.9) mid(5) far(60) outside(40, wrapped dx=-40) seam(0 m) = 5 inside 74.75 m
	_check(dial.get_blip_count() == 5, "5 unrecovered artifacts in range show as blips (got %d)" % dial.get_blip_count())
	_check(dial.locked_on, "lock-on is true when an artifact is within 4 m")

	arts["near"].global_position = Vector3(5.5, 0, 0)
	arts["seam"].global_position = Vector3(50, 0, 0)
	dial.update_blips()
	_check(not dial.locked_on, "lock-on is false when the nearest artifact is 5.5 m away")

	# wrap in the scene: terrain_size is 100 (half 50). Player at +45, artifact at -45 => 10 m east.
	player.global_position = Vector3(45, 0, 0)
	arts["near"].global_position = Vector3(-45, 0, 0)
	dial.update_blips()
	var wrapped := false
	for b in dial.get_blips():
		if is_equal_approx(b["dx"], 10.0) and is_equal_approx(b["dz"], 0.0): wrapped = true
	_check(wrapped, "scene wrap uses terrain_size from the 'terrain' group")
	player.global_position = Vector3.ZERO

	# range culling
	arts["far"].global_position = Vector3(48, 0, 0)    # inside terrain half-size, 48 m < 74.75 => kept
	arts["outside"].global_position = Vector3(49.9, 49.9, 0)
	dial.radar_range = 20.0                            # cull beyond 23 m
	dial.update_blips()
	var kept_far := false
	for b in dial.get_blips():
		if b["dist"] > 23.0: kept_far = true
	_check(not kept_far, "artifacts beyond 1.15 x range are culled")
	dial.radar_range = 65.0

	# recovered artifacts vanish
	arts["mid"].artifact_id = "apollo_lrv"
	dial.update_blips()
	var before := dial.get_blip_count()
	var gs: Node = root.get_node("/root/GameState")
	gs.recovered_artifacts.append("apollo_lrv")
	dial.update_blips()
	_check(dial.get_blip_count() == before - 1, "a recovered artifact disappears from the radar")
	gs.recovered_artifacts.erase("apollo_lrv")

	# mystery rule: blips carry no identity
	var leaks := false
	for b in dial.get_blips():
		for k in b.keys():
			if k in ["id", "name", "artifact_id", "category"]: leaks = true
	_check(not leaks, "blips are anonymous (no id / name / category fields)")

	# motion
	SettingsStore.set_value("reduced_motion", false)
	dial.sweep_angle = 0.0
	dial._process(0.1)
	_check(dial.sweep_angle > 0.0, "sweep advances when motion is allowed")
	SettingsStore.set_value("reduced_motion", true)
	dial.sweep_angle = 0.0
	dial._process(0.1)
	_check(dial.sweep_angle == 0.0, "sweep is frozen at reduced motion")
	_check(dial.get_blip_count() > 0, "blips keep updating at reduced motion")
	SettingsStore.set_value("reduced_motion", false)

	print("--- RadarDial: %s ---" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
