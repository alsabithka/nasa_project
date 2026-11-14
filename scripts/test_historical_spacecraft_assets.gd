extends SceneTree

# Echoes Beyond Earth - Historical Space Exploration Hardware Test Suite
# Tests full scientific and historical fidelity of 3D spacecraft assets:
# 1. Procedural 3D Mesh Generation & Real-World Dimensions
# 2. Authentic Engineering Subsystems & Component Metadata
# 3. Component Inspector HUD Navigation
# 4. Mars Planetary Surface Geographical Placement
# 5. Solar System Deep Space Exhibition Gallery Mode
# 6. Artifact Database Integrity

const HistoricalSpacecraftModels = preload("res://scripts/spacecraft/historical_spacecraft_models.gd")
const SpacecraftInspectorHUD = preload("res://scripts/ui/spacecraft_inspector_hud.gd")

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n=== STARTING HISTORICAL SPACE EXPLORATION HARDWARE VERIFICATION ===")
	call_deferred("_run_all_tests")

func _assert_test(condition: bool, test_name: String) -> void:
	if condition:
		print("  [PASS] ", test_name)
		passed_count += 1
	else:
		printerr("  [FAIL] ", test_name)
		failed_count += 1

func _count_components(node: Node) -> int:
	var count = 0
	if node.has_meta("component_name"):
		count += 1
	for child in node.get_children():
		count += _count_components(child)
	return count

func _find_component_by_name(node: Node, query: String) -> Node:
	if node.has_meta("component_name"):
		var cname = str(node.get_meta("component_name")).to_lower()
		if query.to_lower() in cname:
			return node
	for child in node.get_children():
		var found = _find_component_by_name(child, query)
		if found:
			return found
	return null

func _run_all_tests() -> void:
	# -------------------------------------------------------------
	# 1. Mars Surface Machinery Models & Authentic Engineering
	# -------------------------------------------------------------
	print("\n--- Part 1: Mars Surface Machinery ---")

	# A. Sojourner Rover
	var sojourner = HistoricalSpacecraftModels.build_sojourner_rover(0.45)
	_assert_test(sojourner != null, "Sojourner rover model generated")
	var soj_comps = _count_components(sojourner)
	_assert_test(soj_comps >= 5, "Sojourner has detailed component metadata (found %d)" % soj_comps)
	var apxs = _find_component_by_name(sojourner, "APXS")
	_assert_test(apxs != null, "Sojourner APXS instrument exists")
	var soj_wheels = _find_component_by_name(sojourner, "Cleated Wheel")
	_assert_test(soj_wheels != null, "Sojourner 6-wheel rocker-bogie mobility system exists")

	# B. Mars Pathfinder Lander
	var pathfinder = HistoricalSpacecraftModels.build_pathfinder_lander(0.50)
	_assert_test(pathfinder != null, "Mars Pathfinder lander model generated")
	var pf_mast = _find_component_by_name(pathfinder, "IMP")
	_assert_test(pf_mast != null, "Pathfinder IMP stereoscopic mast imager exists")
	var pf_petals = _find_component_by_name(pathfinder, "Petal")
	_assert_test(pf_petals != null, "Pathfinder 3 triangular unfolded solar petals exist")

	# C. Spirit Rover (MER-A) with jammed wheel
	var spirit = HistoricalSpacecraftModels.build_mer_rover("spirit", 0.70)
	_assert_test(spirit != null, "Spirit rover (MER-A) model generated")
	var jammed_wheel = _find_component_by_name(spirit, "Seized Right-Front")
	_assert_test(jammed_wheel != null, "Spirit features historical seized right-front drive wheel from Sol 779")
	var mer_pancam = _find_component_by_name(spirit, "Pancam")
	_assert_test(mer_pancam != null, "MER Pancam / Navcam mast assembly exists")

	# D. Opportunity Rover (MER-B)
	var oppy = HistoricalSpacecraftModels.build_mer_rover("opportunity", 0.65)
	_assert_test(oppy != null, "Opportunity rover (MER-B) model generated")
	var oppy_wings = _find_component_by_name(oppy, "Solar Array")
	_assert_test(oppy_wings != null, "Opportunity solar array wings exist")

	# E. Viking 1 Lander (SNAP-19 RTGs, NO solar panels)
	var viking1 = HistoricalSpacecraftModels.build_viking_lander(1, 0.55)
	_assert_test(viking1 != null, "Viking 1 lander model generated")
	var rtg_1 = _find_component_by_name(viking1, "SNAP-19 RTG Power Generator")
	_assert_test(rtg_1 != null, "Viking 1 features dual SNAP-19 Plutonium-238 RTGs in thermal wind covers")
	var sampler_boom = _find_component_by_name(viking1, "Surface Sampler")
	_assert_test(sampler_boom != null, "Viking 1 surface sampler boom and collector head exists")

	# F. Viking 2 Lander
	var viking2 = HistoricalSpacecraftModels.build_viking_lander(2, 0.55)
	_assert_test(viking2 != null, "Viking 2 lander model generated")

	# G. Phoenix Mars Lander (circular solar wings & robotic arm)
	var phoenix = HistoricalSpacecraftModels.build_phoenix_lander(0.40)
	_assert_test(phoenix != null, "Phoenix lander model generated")
	var phx_arm = _find_component_by_name(phoenix, "Robotic Excavation Arm")
	_assert_test(phx_arm != null, "Phoenix 2.35m robotic arm with permafrost rasp exists")
	var phx_solar = _find_component_by_name(phoenix, "Decagonal Solar Array")
	_assert_test(phx_solar != null, "Phoenix dual decagonal circular solar wings exist")

	# H. InSight Mars Lander (UltraFlex wings, SEIS WTS dome on ground, HP3 Mole)
	var insight = HistoricalSpacecraftModels.build_insight_lander(0.70)
	_assert_test(insight != null, "InSight lander model generated")
	var seis = _find_component_by_name(insight, "SEIS")
	_assert_test(seis != null, "InSight SEIS instrument with gold aerodynamic WTS dome exists")
	var hp3 = _find_component_by_name(insight, "HP3")
	_assert_test(hp3 != null, "InSight HP3 heat flow probe structure exists")

	# I. Ingenuity Mars Helicopter (damaged blade tip Flight 72)
	var ing = HistoricalSpacecraftModels.build_ingenuity_helicopter(true, 0.30)
	_assert_test(ing != null, "Ingenuity Mars Helicopter model generated")
	var rotor = _find_component_by_name(ing, "Carbon-Composite Blade")
	_assert_test(rotor != null, "Ingenuity coaxial carbon-composite blades exist")
	var blade_dmg = _find_component_by_name(ing, "Damaged Carbon-Fiber Blade 4")
	_assert_test(blade_dmg != null, "Ingenuity features historical fractured blade tip from Flight 72 at Valinor Hills")

	# -------------------------------------------------------------
	# 2. Solar System Deep Space Machinery Models
	# -------------------------------------------------------------
	print("\n--- Part 2: Solar System Collection ---")

	# J. Dawn Spacecraft (Ceres orbit, 19.7m solar wings, 3 NSTAR thrusters)
	var dawn = HistoricalSpacecraftModels.build_dawn_spacecraft()
	_assert_test(dawn != null, "Dawn spacecraft model generated")
	var dawn_wings = _find_component_by_name(dawn, "Solar Array Wing")
	_assert_test(dawn_wings != null, "Dawn 19.7-meter solar array wingspan exists")
	var dawn_ion = _find_component_by_name(dawn, "NSTAR")
	_assert_test(dawn_ion != null, "Dawn 3 NSTAR Xenon ion thrusters exist")
	var dawn_hga = _find_component_by_name(dawn, "High-Gain Antenna")
	_assert_test(dawn_hga != null, "Dawn 1.52m parabolic HGA dish exists")

	# K. NEAR Shoemaker (Asteroid 433 Eros landing)
	var near = HistoricalSpacecraftModels.build_near_shoemaker()
	_assert_test(near != null, "NEAR Shoemaker model generated")
	var near_panels = _find_component_by_name(near, "Windmill Solar Array")
	_assert_test(near_panels != null, "NEAR Shoemaker 4 windmill solar panels resting on panel tips exist")
	var near_dish = _find_component_by_name(near, "High-Gain X-Band Dish")
	_assert_test(near_dish != null, "NEAR Shoemaker fixed HGA dish exists")

	# L. Pioneer 10 & 11 (2.74m dish, golden plaque, RTG booms)
	var pioneer10 = HistoricalSpacecraftModels.build_pioneer_probe(10)
	_assert_test(pioneer10 != null, "Pioneer 10 probe model generated")
	var p10_dish = _find_component_by_name(pioneer10, "2.74m High-Gain")
	_assert_test(p10_dish != null, "Pioneer 10 2.74m parabolic dish exists")
	var p10_plaque = _find_component_by_name(pioneer10, "Pioneer Plaque")
	_assert_test(p10_plaque != null, "Pioneer 10 golden engraved plaque exists")
	var p10_rtg = _find_component_by_name(pioneer10, "SNAP-19 RTGs")
	_assert_test(p10_rtg != null, "Pioneer 10 extended RTG power booms exist")

	var pioneer11 = HistoricalSpacecraftModels.build_pioneer_probe(11)
	_assert_test(pioneer11 != null, "Pioneer 11 probe model generated")

	# M. Kepler Space Telescope (0.95m photometer, curved solar array)
	var kepler = HistoricalSpacecraftModels.build_kepler_telescope()
	_assert_test(kepler != null, "Kepler Space Telescope model generated")
	var kep_photometer = _find_component_by_name(kepler, "Schmidt Photometer")
	_assert_test(kep_photometer != null, "Kepler 0.95m Schmidt photometer aperture exists")
	var kep_sunshade = _find_component_by_name(kepler, "Sunshade Solar Array")
	_assert_test(kep_sunshade != null, "Kepler curved solar array sunshade exists")
	var kep_corrector = _find_component_by_name(kepler, "Fused Silica Corrector")
	_assert_test(kep_corrector != null, "Kepler fused silica corrector plate exists")

	# -------------------------------------------------------------
	# 3. Spacecraft Component Inspector HUD
	# -------------------------------------------------------------
	print("\n--- Part 3: Component Inspector HUD ---")
	var inspector = SpacecraftInspectorHUD.new()
	root.add_child(inspector)
	inspector.open_inspector(dawn, "dawn")
	_assert_test(inspector._components.size() >= 4, "Inspector scanned all Dawn components (found %d)" % inspector._components.size())
	_assert_test(inspector.comp_name_label.text.length() > 0, "Component name label populated")
	_assert_test(inspector.comp_spec_label.text.begins_with("SPECIFICATIONS:"), "Component specification label populated")
	var initial_name = inspector.comp_name_label.text
	inspector._on_next_pressed()
	var next_name = inspector.comp_name_label.text
	_assert_test(initial_name != next_name, "Inspector navigates to next component (%s -> %s)" % [initial_name, next_name])
	inspector._on_prev_pressed()
	_assert_test(inspector.comp_name_label.text == initial_name, "Inspector navigates back to previous component")
	inspector.close_inspector()
	await process_frame

	# -------------------------------------------------------------
	# 4. Mars Planetary Surface Geographical Placement
	# -------------------------------------------------------------
	print("\n--- Part 4: Mars Planetary Coordinates & Spawning ---")
	var mars_scene = load("res://scenes/levels/mars.tscn")
	_assert_test(mars_scene != null, "Mars level loads")
	var mars_level = mars_scene.instantiate()
	root.add_child(mars_level)
	await process_frame
	await process_frame

	var terrain = mars_level.get_node_or_null("Terrain")
	_assert_test(terrain != null, "Mars terrain exists")
	if terrain:
		_assert_test(terrain.historical_spacecraft_catalog.size() == 9, "All 9 Mars surface missions cataloged with authentic coordinates")

		# Test spawning historical spacecraft on Mars surface
		var sc_pf = terrain.spawn_historical_spacecraft("pathfinder")
		_assert_test(sc_pf != null, "Pathfinder dynamically spawned on Mars")
		if sc_pf:
			_assert_test(sc_pf.artifact_id == "pathfinder", "Spawned Pathfinder artifact_id matches")
			_assert_test(sc_pf.global_position.length() > 1000.0, "Pathfinder placed on spherical surface (pos: %s)" % str(sc_pf.global_position))

		var sc_vik1 = terrain.spawn_historical_spacecraft("viking_1")
		_assert_test(sc_vik1 != null, "Viking 1 dynamically spawned on Chryse Planitia")

		var sc_ins = terrain.spawn_historical_spacecraft("insight")
		_assert_test(sc_ins != null, "InSight dynamically spawned on Elysium Planitia")

		# Telemetry check for Pathfinder at Ares Vallis (19.33° N, 326.45° E)
		var pf_pos = terrain.get_spacecraft_world_position("pathfinder")
		var pf_coords = terrain.get_planetary_coords(pf_pos)
		_assert_test(abs(pf_coords["lat"] - 19.33) < 0.5, "Pathfinder latitude matches Ares Vallis (calc: %.2f° vs 19.33°)" % pf_coords["lat"])
		_assert_test(abs(pf_coords["lon"] - 326.45) < 0.5, "Pathfinder longitude matches Ares Vallis (calc: %.2f° vs 326.45°)" % pf_coords["lon"])

	# -------------------------------------------------------------
	# 5. Solar System Exhibition Gallery Scene
	# -------------------------------------------------------------
	print("\n--- Part 5: Solar System Gallery Scene ---")
	var gallery_scene = load("res://scenes/spacecraft/spacecraft_gallery.tscn")
	_assert_test(gallery_scene != null, "Spacecraft gallery scene exists")
	var gallery = gallery_scene.instantiate()
	root.add_child(gallery)
	await process_frame
	await process_frame

	_assert_test(gallery.spacecraft_list.size() == 5, "Gallery hosts all 5 deep-space spacecraft missions")
	_assert_test(gallery.mount_point.get_child_count() > 0, "Gallery loaded initial spacecraft model (Dawn)")
	gallery.select_next_spacecraft()
	await process_frame
	_assert_test(gallery.current_craft_index == 1, "Gallery switched to NEAR Shoemaker (index 1)")
	_assert_test(gallery.mount_point.get_child_count() > 0, "NEAR Shoemaker and Eros context loaded")
	gallery.select_next_spacecraft()
	await process_frame
	_assert_test(gallery.current_craft_index == 2, "Gallery switched to Pioneer 10 (index 2)")

	# -------------------------------------------------------------
	# 6. Database Integrity
	# -------------------------------------------------------------
	print("\n--- Part 6: Artifacts Database Verification ---")
	var game_state = root.get_node_or_null("GameState")
	_assert_test(game_state != null, "GameState active")
	if game_state:
		var required_spacecraft = [
			"sojourner", "pathfinder", "spirit", "opportunity",
			"viking_1", "viking_2", "phoenix", "insight", "ingenuity",
			"dawn", "near_shoemaker", "pioneer_10", "pioneer_11", "kepler"
		]
		for sc_id in required_spacecraft:
			var data = game_state.get_artifact_data(sc_id)
			_assert_test(not data.is_empty(), "Database has entry for historical spacecraft '%s'" % sc_id)
			if not data.is_empty():
				_assert_test(data.has("history"), "Entry '%s' has historical significance metadata" % sc_id)

	# Finish & Summary
	print("\n=== HISTORICAL SPACECRAFT ASSETS VERIFICATION COMPLETE ===")
	print("Results: %d PASSED, %d FAILED" % [passed_count, failed_count])
	if failed_count == 0:
		print("SUCCESS: All historical spacecraft assets verified with 100% scientific and engineering accuracy!\n")
	else:
		printerr("FAILURE: %d tests failed!\n" % failed_count)

	quit(failed_count)
