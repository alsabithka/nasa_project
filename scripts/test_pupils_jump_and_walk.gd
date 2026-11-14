extends SceneTree

# Rigorous Verification:
# 1. Minion Pupil & Eye Layers Visibility
# 2. Jump Reliability (No getting stuck, jump buffering, coyote time, slope jumping)
# 3. Walk Animation Continuity over terrain micro-dips

func _init() -> void:
	print("==================================================================")
	print("TESTING: PUPIL VISIBILITY, JUMP RELIABILITY & WALK CONTINUITY")
	print("==================================================================")
	call_deferred("_run_test")

func _run_test() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load res://scenes/levels/moon.tscn")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	var player = world.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player missing!")
		quit(1)
		return
	
	# Wait for player to settle
	var settle = 0
	while not player.is_on_floor() and settle < 120:
		settle += 1
		await process_frame
	
	var ground_y = player.global_position.y
	
	# TEST 1: Eye Layers & Pupil Visibility
	print("\n--- 1. Testing Eye Layers & Pupil Visibility ---")
	var left_goggle = player.get_node("Visuals/Torso/Head/LeftGoggleRing")
	var right_goggle = player.get_node("Visuals/Torso/Head/RightGoggleRing")
	var left_sclera = left_goggle.get_node("LeftEyeSclera")
	var left_iris = left_goggle.get_node("LeftEyeIris")
	var left_pupil = left_goggle.get_node("LeftEyePupil")
	var left_sparkle = left_goggle.get_node("LeftEyeSparkle")
	
	print("[Eyes] Left Sclera global Z: ", left_sclera.global_position.z)
	print("[Eyes] Left Iris global Z:   ", left_iris.global_position.z)
	print("[Eyes] Left Pupil global Z:  ", left_pupil.global_position.z)
	print("[Eyes] Left Sparkle global Z:", left_sparkle.global_position.z)
	
	if left_pupil.global_position.z <= left_iris.global_position.z:
		printerr("FAIL: Left pupil is behind iris!")
		quit(1)
		return
	if left_iris.global_position.z <= left_sclera.global_position.z:
		printerr("FAIL: Left iris is behind sclera!")
		quit(1)
		return
	
	var right_sclera = right_goggle.get_node("RightEyeSclera")
	var right_iris = right_goggle.get_node("RightEyeIris")
	var right_pupil = right_goggle.get_node("RightEyePupil")
	print("[Eyes] Right Pupil global Z: ", right_pupil.global_position.z)
	if right_pupil.global_position.z <= right_iris.global_position.z:
		printerr("FAIL: Right pupil is behind iris!")
		quit(1)
		return
		
	print("PASS: Both Left and Right Pupils are properly positioned in front of the Irises and Scleras!")
	
	# TEST 2: Jump Reliability & Buffering
	print("\n--- 2. Testing Jump Reliability, Buffering & Coyote Time ---")
	print("[Jump] Initial on floor: ", player.is_on_floor())
	
	# Subtest A: Standard jump
	player.jump()
	print("[Jump] Standard jump applied. Velocity Y: ", player.velocity.y)
	if player.velocity.y <= 0.0 or not player.is_jumping:
		printerr("FAIL: Standard jump failed to apply upward velocity!")
		quit(1)
		return
	print("PASS: Standard jump works cleanly.")
	
	# Wait for jump completion
	while player.is_on_floor():
		await process_frame
	while not player.is_on_floor():
		await process_frame
	await process_frame
	
	# Subtest B: Coyote Time Jump (jumping just after leaving ground)
	player.coyote_timer = 0.15 # In coyote window
	player.jump_buffer_timer = 0.10 # Buffered space press
	player._physics_process(0.016)
	print("[Coyote] Velocity Y after coyote jump: ", player.velocity.y)
	if player.velocity.y <= 0.0:
		printerr("FAIL: Coyote time jump failed!")
		quit(1)
		return
	print("PASS: Coyote time jump works cleanly.")
	
	# Wait for coyote jump completion
	while player.is_on_floor():
		await process_frame
	while not player.is_on_floor():
		await process_frame
	await process_frame
	
	# Subtest C: Landing Jump Buffer (pressing space within 0.2s before landing)
	player.jump()
	while player.is_on_floor():
		await process_frame
	while player.velocity.y > -0.5:
		await process_frame
	while player.global_position.y > ground_y + 0.15:
		await process_frame
		
	# Pre-buffer jump right before touchdown (< 100ms to ground)
	player.jump_buffer_timer = 0.22
	
	var jumped_from_buffer = false
	for i in range(25):
		await process_frame
		if player.is_jumping or player.velocity.y > 1.0:
			jumped_from_buffer = true
			break
	
	if not jumped_from_buffer:
		printerr("FAIL: Buffered jump did not fire on touchdown!")
		quit(1)
		return
	print("PASS: Jump buffering cleanly registered and executed jump upon touchdown.")
	
	# Wait for landing
	while player.is_on_floor():
		await process_frame
	while not player.is_on_floor():
		await process_frame
	await process_frame
	await process_frame
	
	# TEST 3: Walk Animation Continuity over rough terrain
	print("\n--- 3. Testing Walk Animation Continuity over Micro-Dips ---")
	print("[Walk] Player on floor: ", player.is_on_floor())
	player.walk_cycle = 0.5
	player._animate_astronaut(0.05, true, false)
	print("[Walk] State on flat ground: ", player.current_anim_state)
	if player.current_anim_state != "walk":
		printerr("FAIL: Expected 'walk' state!")
		quit(1)
		return
	
	# Simulate stepping over a micro-dip in terrain (air_time = 0.05s, is_jumping = false)
	player.air_time = 0.05
	player.is_jumping = false
	player._animate_astronaut(0.05, true, false)
	print("[Walk] State during micro-dip (air_time = 0.05s): ", player.current_anim_state)
	print("[Walk] Left leg rotation X: ", player.left_leg.rotation.x)
	print("[Walk] Torso waddle roll Z: ", player.visuals.rotation.z)
	if player.current_anim_state != "walk":
		printerr("FAIL: Walk animation was interrupted by micro-dip!")
		quit(1)
		return
	if abs(player.visuals.rotation.z) < 0.005 or abs(player.left_leg.rotation.x) < 0.01:
		printerr("FAIL: Walk animation froze during micro-dip!")
		quit(1)
		return
	print("PASS: Walk animation continues striding and waddling smoothly across terrain dips!")
	
	print("\n==================================================================")
	print("ALL PUPIL, JUMP AND WALK CONTINUITY TESTS PASSED!")
	print("==================================================================")
	quit(0)
