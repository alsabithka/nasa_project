extends SceneTree

# Test interaction stability: verifies that player does NOT rubberband or get pushed out
func _init() -> void:
	print("--- Running Test: Player Interaction Stability ---")
	call_deferred("_run_test")

func _run_test() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load moon scene!")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	# Wait for ready and physics initialization
	for i in range(10):
		await process_frame
	
	var player = world.get_node_or_null("Player")
	var lrv = world.get_node_or_null("Artifact_LRV")
	
	if not player or not lrv:
		printerr("FAIL: Player or LRV not found!")
		quit(1)
		return
	
	print("[Test] Initial player position: ", player.global_position)
	print("[Test] LRV position: ", lrv.global_position)
	
	# Test 1: Approach LRV from front (within interaction range)
	print("\n--- Subtest 1: Approaching from Front ---")
	var approach_pos = lrv.global_position + Vector3(0, 0.2, 2.0)
	player.global_position = approach_pos
	player.velocity = Vector3.ZERO
	
	# Step physics a few frames
	for i in range(10):
		await process_frame
	
	print("[Test] Player position before pressing E: ", player.global_position)
	var pos_before_e = player.global_position
	
	# Simulate pressing interact key [E]
	var event_down = InputEventAction.new()
	event_down.action = "interact"
	event_down.pressed = true
	Input.parse_input_event(event_down)
	
	# Run frames during digging
	for i in range(30):
		await process_frame
	
	var pos_during_e = player.global_position
	var displacement = pos_before_e.distance_to(pos_during_e)
	print("[Test] Player position during digging: ", pos_during_e, " Displacement: ", displacement)
	
	if displacement > 1.2:
		printerr("FAIL: Player experienced large displacement/rubberband: ", displacement)
		quit(1)
		return
	else:
		print("PASS: Player remained stable during interaction from front (displacement: ", displacement, " m)")
	
	# Release interact
	var event_up = InputEventAction.new()
	event_up.action = "interact"
	event_up.pressed = false
	Input.parse_input_event(event_up)
	
	for i in range(5):
		await process_frame
	
	# Test 2: Approach from side
	print("\n--- Subtest 2: Approaching from Side ---")
	approach_pos = lrv.global_position + Vector3(2.2, 0.2, 0)
	player.global_position = approach_pos
	player.velocity = Vector3.ZERO
	
	for i in range(10):
		await process_frame
	
	pos_before_e = player.global_position
	Input.parse_input_event(event_down)
	
	for i in range(30):
		await process_frame
	
	pos_during_e = player.global_position
	displacement = pos_before_e.distance_to(pos_during_e)
	print("[Test] Player position during side digging: ", pos_during_e, " Displacement: ", displacement)
	
	if displacement > 1.2:
		printerr("FAIL: Player rubberbanded during side interaction: ", displacement)
		quit(1)
		return
	else:
		print("PASS: Player remained stable during side interaction (displacement: ", displacement, " m)")
	
	Input.parse_input_event(event_up)
	
	# Test 3: Complete digging sequence without displacement
	print("\n--- Subtest 3: Full Digging Sequence Completion ---")
	lrv.dig_duration = 0.2 # Fast-forward for test
	lrv.clean_duration = 0.2
	
	Input.parse_input_event(event_down)
	var timeout = 120
	while lrv.current_state == 2 and timeout > 0: # DIGGING
		timeout -= 1
		await process_frame
	
	print("[Test] Dig completed. LRV state: ", lrv.current_state, " (Expected 3 = EXPOSED)")
	if lrv.current_state != 3:
		printerr("FAIL: Expected state EXPOSED (3), got: ", lrv.current_state)
		quit(1)
		return
	
	var final_disp = approach_pos.distance_to(player.global_position)
	print("[Test] Player displacement after complete dig: ", final_disp)
	if final_disp > 1.5:
		printerr("FAIL: Player rubberbanded at end of dig: ", final_disp)
		quit(1)
		return
	
	print("PASS: Interaction stability confirmed across all conditions!")
	print("ALL INTERACTION STABILITY TESTS PASSED.")
	quit(0)
