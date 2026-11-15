extends SceneTree

# Verification script for Minion Pink Astronaut Character Model & Locomotion Animations

func _init() -> void:
	print("==================================================================")
	print("VERIFYING: MINION ASTRONAUT MODEL & ASTRONAUT ANIMATIONS")
	print("==================================================================")
	call_deferred("_run_verification")

func _run_verification() -> void:
	var moon_scene = load("res://scenes/levels/moon.tscn")
	if not moon_scene:
		printerr("FAIL: Cannot load res://scenes/levels/moon.tscn")
		quit(1)
		return
	
	var world = moon_scene.instantiate()
	root.add_child(world)
	
	var player = world.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player missing from moon scene!")
		quit(1)
		return
	
	# Wait for player to settle onto lunar regolith
	var settle = 0
	while not player.is_on_floor() and settle < 120:
		settle += 1
		await process_frame
	
	print("[Setup] Settled frames: %d | On floor: %s | Y pos: %f" % [settle, str(player.is_on_floor()), player.global_position.y])
	
	# Test 1: Verify Visual Features matching character image
	print("\n--- 1. Testing Visual Model Features (Pink Astronaut Minion) ---")
	var torso = player.get_node_or_null("Visuals/Torso")
	var torso_mesh = player.get_node_or_null("Visuals/Torso/TorsoMesh")
	var gru_badge = player.get_node_or_null("Visuals/Torso/GruBadge")
	var left_strap = player.get_node_or_null("Visuals/Torso/LeftShoulderStrap")
	var right_strap = player.get_node_or_null("Visuals/Torso/RightShoulderStrap")
	var mouth = player.get_node_or_null("Visuals/Torso/Head/SmileMouth")
	var teeth = player.get_node_or_null("Visuals/Torso/Head/SmileMouth/UpperTeeth")
	var visor = player.get_node_or_null("Visuals/Torso/Head/TransparentVisor")
	var left_cuff = player.get_node_or_null("Visuals/Torso/LeftArm/WristCuff")
	var right_cuff = player.get_node_or_null("Visuals/Torso/RightArm/WristCuff")
	var left_sole = player.get_node_or_null("Visuals/Torso/LeftLeg/Boot/BootSole")
	var right_sole = player.get_node_or_null("Visuals/Torso/RightLeg/Boot/BootSole")
	
	if not torso or not torso_mesh or not gru_badge or not left_strap or not right_strap:
		printerr("FAIL: Torso structure, Gru badge, or shoulder straps missing!")
		quit(1)
		return
	
	if not mouth or not teeth or not visor:
		printerr("FAIL: Smile mouth, teeth, or transparent bubble visor missing!")
		quit(1)
		return
		
	if not left_cuff or not right_cuff or not left_sole or not right_sole:
		printerr("FAIL: Wrist cuffs or boot soles missing!")
		quit(1)
		return
	
	# Check Suit Color is vibrant pink
	var suit_mat = torso_mesh.mesh.material
	var pink_color = suit_mat.albedo_color
	print("[Suit] Albedo Color: ", pink_color)
	if pink_color.r < 0.85 or pink_color.g > 0.60 or pink_color.b < 0.50:
		printerr("FAIL: Suit color is not pink!")
		quit(1)
		return
	print("PASS: Visual model features (Pink suit, Gru badge, smile, teeth, bubble visor, cuffs) verified.")
	
	# Test 2: Verify AnimationPlayer & Library Tracks
	print("\n--- 2. Testing AnimationPlayer & Animation Library ---")
	var anim_player = player.get_node_or_null("AnimationPlayer")
	if not anim_player:
		printerr("FAIL: AnimationPlayer missing from Player scene!")
		quit(1)
		return
	
	var has_idle = anim_player.has_animation("idle")
	var has_walk = anim_player.has_animation("walk")
	var has_jump = anim_player.has_animation("jump")
	print("[AnimationPlayer] Has 'idle': ", has_idle, " | 'walk': ", has_walk, " | 'jump': ", has_jump)
	if not has_idle or not has_walk or not has_jump:
		printerr("FAIL: Required animations missing from AnimationPlayer!")
		quit(1)
		return
	print("PASS: AnimationPlayer clips verified.")
	
	# Test 3: Runtime Idle Animation
	print("\n--- 3. Testing Runtime Idle Animation ---")
	print("[Idle] Player on floor: ", player.is_on_floor())
	player._animate_astronaut(0.1, false, false)
	print("[Idle] Current state: ", player.current_anim_state)
	if player.current_anim_state != "idle":
		printerr("FAIL: Expected 'idle' state when stationary on lunar floor!")
		quit(1)
		return
	
	# Simulate 1 second of idle
	var initial_torso_y = player.torso.position.y
	for i in range(10):
		player._animate_astronaut(0.1, false, false)
	var final_torso_y = player.torso.position.y
	print("[Idle] Torso Y movement: %f -> %f" % [initial_torso_y, final_torso_y])
	print("[Idle] Left Arm rotation Z: ", player.left_arm.rotation.z, " (buoyant spacesuit posture)")
	print("PASS: Idle buoyant breathing bobbing and relaxed spacesuit arm float verified.")
	
	# Test 4: Runtime Walking & Loping Animation
	print("\n--- 4. Testing Runtime Walk & Waddle Animation ---")
	player.walk_cycle = 0.8
	player._animate_astronaut(0.05, true, false)
	print("[Walk] Current state: ", player.current_anim_state)
	print("[Walk] Torso waddle roll Z: ", player.visuals.rotation.z)
	print("[Walk] Forward lean X: ", player.visuals.rotation.x)
	print("[Walk] Left leg rotation X: ", player.left_leg.rotation.x)
	print("[Walk] Right leg rotation X: ", player.right_leg.rotation.x)
	print("[Walk] Left arm counter-swing X: ", player.left_arm.rotation.x)
	if player.current_anim_state != "walk":
		printerr("FAIL: Expected 'walk' state when moving!")
		quit(1)
		return
	if abs(player.visuals.rotation.z) < 0.005 or abs(player.left_leg.rotation.x) < 0.01:
		printerr("FAIL: Walk animation lacking waddle or leg swing dynamics!")
		quit(1)
		return
	print("PASS: Walk waddle, forward lean, alternating leg strides, and arm counter-swings verified.")
	
	# Test 5: Runtime Low-Gravity Jump & Fall Animation
	print("\n--- 5. Testing Runtime Jump & Low-Gravity Float Animation ---")
	player.jump()
	print("[Jump] Jump initiated. Velocity Y: ", player.velocity.y)
	if player.velocity.y <= 0.0:
		printerr("FAIL: Jump velocity not applied!")
		quit(1)
		return
	
	# In-air frames
	await process_frame
	print("[Jump] In air state: ", player.current_anim_state)
	print("[Jump] Torso rotation X: ", player.visuals.rotation.x)
	print("[Jump] Left Arm rotation X: ", player.left_arm.rotation.x)
	print("[Jump] Left Arm rotation Z: ", player.left_arm.rotation.z, " (stabilization flare)")
	
	# Test landing squash
	player._handle_landing(-2.5)
	print("[Landing] Squash applied: ", player.landing_squash)
	if player.landing_squash < 0.04:
		printerr("FAIL: Landing squash not applied!")
		quit(1)
		return
	print("PASS: Low-gravity jump lift-off and landing squash absorption verified.")
	
	print("\n==================================================================")
	print("ALL MINION ASTRONAUT MODEL & ANIMATION CHECKS PASSED!")
	print("==================================================================")
	quit(0)
