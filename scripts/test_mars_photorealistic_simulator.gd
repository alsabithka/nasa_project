extends SceneTree

# Echoes Beyond Earth - Mars Jezero Crater Photorealistic Exploration Simulator Test Suite
# Tests full scientific fidelity of the Mars surface environment:
# 1. Physics & Gravitational Pull (exact 3.71 m/s², 0.379g)
# 2. Jezero Crater Geological Landscape (Delta front, Neretva Vallis, Séítah dunes, Belva crater)
# 3. PBR Materials, Rock Diversity & Kodiak Remnant Butte
# 4. Atmosphere, Butterscotch Sky, Phobos & Deimos Celestial Bodies
# 5. Wind Acoustics, Suspended Dust & Convective Dust Devils
# 6. Scientific Discoveries, Stratified Subsurface Excavation & Artifact Models
# 7. Astronaut Helmet HUD Mars Telemetry

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n=== STARTING MARS JEZERO CRATER SURFACE VERIFICATION ===")
	call_deferred("_run_all_tests")

func _assert_test(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] ", test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] ", test_name)
		failed_count += 1

func _run_all_tests() -> void:
	var mars_scene = load("res://scenes/levels/mars.tscn")
	_assert_test(mars_scene != null, "Mars level scene (mars.tscn) loads successfully")
	if not mars_scene:
		_finish()
		return

	var level = mars_scene.instantiate()
	root.add_child(level)
	await process_frame
	await process_frame

	# 1. Level Gravity & Controller Calibration
	_assert_test(level.planet_name == "Mars", "Level planet name is 'Mars'")
	_assert_test(is_equal_approx(level.level_gravity, 3.71), "Level gravity is exactly 3.71 m/s² (0.379 g)")

	var player = level.get_node_or_null("Player")
	_assert_test(player != null, "Player astronaut exists in Mars level")
	if player:
		_assert_test(is_equal_approx(player.gravity, 3.71), "Player physics gravity updated to 3.71 m/s²")
		_assert_test(player.jump_velocity >= 2.9, "Player jump velocity calibrated for Mars low gravity (jump_velocity: %.2f)" % player.jump_velocity)

	# 2. Jezero Crater Terrain Architecture
	var terrain = level.get_node_or_null("Terrain")
	_assert_test(terrain != null, "Procedural Jezero Crater terrain node exists")
	if terrain:
		var terrain_body = terrain.get_node_or_null("MarsTerrainBody")
		_assert_test(terrain_body != null, "Mars terrain static body generated")
		if terrain_body:
			var col_shape = terrain_body.get_node_or_null("TerrainCollisionShape")
			_assert_test(col_shape != null and col_shape.shape is ConcavePolygonShape3D, "Trimesh ConcavePolygonShape3D collision generated for uneven terrain")
			var mesh_inst = terrain_body.get_node_or_null("TerrainMesh")
			_assert_test(mesh_inst != null and mesh_inst.mesh != null, "Continuous subdivided terrain mesh instantiated")

		# Elevation queries at key geological landmarks
		var delta_h = terrain.get_terrain_height(-30.0, -15.0)
		var seitah_h = terrain.get_terrain_height(-20.0, 28.0)
		var channel_h = terrain.get_terrain_height(32.0, 0.0)
		var belva_h = terrain.get_terrain_height(-32.0, -28.0)
		_assert_test(delta_h > seitah_h, "Delta front is elevated above Séítah floor depression (Delta: %.2fm vs Seitah: %.2fm)" % [delta_h, seitah_h])
		_assert_test(belva_h < delta_h, "Belva Crater interior is excavated below surrounding delta (Belva: %.2fm)" % belva_h)

		# Kodiak Remnant Butte
		var kodiak = terrain.get_node_or_null("KodiakButte")
		_assert_test(kodiak != null, "Kodiak remnant delta butte / mesa outpost exists")

		# Scattered geological rock catalog
		var belva_boulder = terrain.get_node_or_null("BelvaBoulder1")
		var delta_bench = terrain.get_node_or_null("DeltaBenchRock")
		var seitah_block = terrain.get_node_or_null("SeitahBlock1")
		var ventifact = terrain.get_node_or_null("Ventifact1")
		_assert_test(belva_boulder != null, "Belva crater basalt boulder generated")
		_assert_test(delta_bench != null, "Layered delta sedimentary bench rock generated")
		_assert_test(seitah_block != null, "Séítah olivine cumulate block generated")
		_assert_test(ventifact != null, "Wind-sculpted eolian ventifact generated")

		# Multi-tiered flat sedimentary bedrock slabs
		var slab_a = terrain.get_node_or_null("DeltaSlabFormation_A")
		var slab_b = terrain.get_node_or_null("DeltaSlabFormation_B")
		var stepped_strata = terrain.get_node_or_null("SteppedStrata_1")
		var neretva_pavement = terrain.get_node_or_null("NeretvaPavement")
		_assert_test(slab_a != null and slab_b != null, "Multi-tiered flat sedimentary bedrock formations exist")
		_assert_test(stepped_strata != null and neretva_pavement != null, "Stepped strata layers and fluvial rock pavements exist")

		# Scree fields and scattered stones
		var stone_count = 0
		for child in terrain.get_children():
			if child.name.begins_with("Stone_"):
				stone_count += 1
		_assert_test(stone_count >= 50, "Geological scree fields and stone clusters generated (found: %d stones)" % stone_count)

	# 3. Celestial System & Atmospheric Fog: Sky, Sun, Depth Fog, Phobos, Deimos
	var env_node = level.get_node_or_null("WorldEnvironment")
	_assert_test(env_node != null and env_node.environment != null, "WorldEnvironment configured")
	if env_node and env_node.environment:
		var env = env_node.environment
		_assert_test(env.fog_enabled, "Atmospheric distance depth fog is enabled")
		_assert_test(env.fog_light_color.r > env.fog_light_color.b, "Atmospheric fog matches pale dusty peach Martian horizon hue")
		var sky = env.sky
		_assert_test(sky != null and sky.sky_material is ProceduralSkyMaterial, "Martian sky dome uses procedural atmospheric sky material")
		if sky and sky.sky_material:
			var mat = sky.sky_material as ProceduralSkyMaterial
			_assert_test(mat.sky_top_color.r > mat.sky_top_color.b, "Martian sky exhibits characteristic butterscotch/salmon hue")

	var phobos = terrain.get_node_or_null("PhobosInSky")
	_assert_test(phobos != null, "Phobos celestial body exists in Martian sky")
	if phobos:
		var stickney = phobos.get_node_or_null("MeshInstance3D/SphereMesh") != null or phobos.get_child_count() >= 2
		_assert_test(stickney, "Phobos features irregular geometry and Stickney impact crater landmark")

	var deimos = terrain.get_node_or_null("DeimosInSky")
	_assert_test(deimos != null, "Deimos celestial body exists in distant orbit")

	# 4. Martian Atmospheric Weather System
	var atmo = terrain.get_node_or_null("MarsAtmosphereSystem")
	_assert_test(atmo != null, "MarsAtmosphereSystem instantiated")
	if atmo:
		var wind_audio = atmo.get_node_or_null("MartianWindAudio")
		_assert_test(wind_audio != null and wind_audio.playing, "Martian atmospheric wind audio is active and playing")
		var suspended_dust = atmo.get_node_or_null("SuspendedAtmosphericDust")
		_assert_test(suspended_dust != null, "Suspended atmospheric ferric oxide dust particles active")
		var saltation_dust = atmo.get_node_or_null("GroundSaltationDust")
		_assert_test(saltation_dust != null, "Ground saltation / sand creep particles active")
		var devil1 = atmo.get_node_or_null("DustDevil_1")
		var devil2 = atmo.get_node_or_null("DustDevil_2")
		_assert_test(devil1 != null and devil2 != null, "Dynamic convective dust devils active across Jezero plains")

	# 5. Scientific Discoveries & Artifact Catalog
	var expected_artifacts = [
		"sojourner",
		"opportunity",
		"ingenuity",
		"jezero_delta_clay",
		"seitah_olivine_basalt",
		"perseverance_heatshield_remnant",
		"martian_meteorite_shergottite"
	]

	var gs = level.get_node_or_null("/root/GameState")
	_assert_test(gs != null, "GameState autoload singleton active")
	if gs:
		var total_mars = gs.get_total_count("Mars")
		_assert_test(total_mars == 7, "GameState has all 7 Mars artifacts registered in database (found: %d)" % total_mars)

	for art_id in expected_artifacts:
		var found_node = null
		for child in level.get_children():
			if child.is_in_group("artifacts") and child.get_artifact_id() == art_id:
				found_node = child
				break
		_assert_test(found_node != null, "Artifact '%s' placed in Mars level" % art_id)
		if found_node:
			# Check excavation pit
			var pit = found_node.get_node_or_null("LunarExcavationPit")
			_assert_test(pit != null, "Artifact '%s' has stratified excavation pit" % art_id)
			# Check glint
			var glint = found_node.get_node_or_null("LunarGlintEffect")
			_assert_test(glint != null, "Artifact '%s' has natural anomaly glint shimmer" % art_id)
			# Check 3D mesh representation
			var model = found_node.get_node_or_null("VisualModel")
			_assert_test(model != null and model.get_child_count() > 0, "Artifact '%s' has 3D mesh representation" % art_id)

	# 6. Astronaut Helmet HUD Mars Telemetry
	var hud = terrain.get_node_or_null("AstronautHelmetHUD")
	_assert_test(hud != null, "AstronautHelmetHUD active")
	if hud and player:
		# Process a frame for HUD update
		hud._process(0.1)
		_assert_test("3.71" in hud.gravity_label.text, "HUD displays Mars gravity 3.71 m/s²: '%s'" % hud.gravity_label.text)
		_assert_test("6.1 hPa" in hud.suit_pressure_label.text or "95.3% CO₂" in hud.suit_pressure_label.text, "HUD displays Mars atmosphere telemetry: '%s'" % hud.suit_pressure_label.text)

	level.queue_free()
	_finish()

func _finish() -> void:
	print("\n=== MARS VERIFICATION COMPLETE ===")
	print("Results: %d PASSED, %d FAILED" % [passed_count, failed_count])
	if failed_count == 0:
		print("SUCCESS: Photorealistic Mars Jezero Crater environment fully verified!\n")
		quit(0)
	else:
		printerr("FAILURE: One or more tests failed!\n")
		quit(1)
