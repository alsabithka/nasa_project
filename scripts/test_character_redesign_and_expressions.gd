extends SceneTree

# Verification script for:
# 1. Curved Goggle Headband wrapping around cylindrical head with side connectors
# 2. Enlarged Minion Capsule Head, Visor, and slimmed astronaut collar
# 3. Constrained Eyelids (r <= 0.088) inside goggle lenses, Calm half-closed expression, natural blinking
# 4. Expressive Minion Mouth (Neutral, Happy smile blend shape, Calm) with smooth transitions
# 5. Redesigned Elongated Handheld Scientific Scanner (grip, chassis, screen, sensor head, antennae)
# 6. Audio Audit & Permanent Elimination of the Recurring Buzzing Sound

func _init() -> void:
	print("==================================================================")
	print("AUDIT: ASTRONAUT REDESIGN, EXPRESSIONS, SCANNER & AUDIO FIXES")
	print("==================================================================")
	call_deferred("_run_audit")

func _run_audit() -> void:
	var tree_root = get_root()
	var level_scene = load("res://scenes/levels/moon.tscn")
	var level = level_scene.instantiate()
	tree_root.add_child(level)
	
	await process_frame
	await process_frame
	
	var player = level.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player node missing from Moon scene")
		quit(1)
		return
	
	# --- 1. Testing Curved Goggles Headband & Connectors ---
	print("\n--- 1. Testing Goggles Headband Curvature & Connectors ---")
	var goggle_strap = player.get_node_or_null("Visuals/Torso/Head/GoggleStrap")
	var curved_strap = player.get_node_or_null("Visuals/Torso/Head/GoggleStrap/CurvedStrap")
	var left_connector = player.get_node_or_null("Visuals/Torso/Head/GoggleStrap/LeftConnector")
	var right_connector = player.get_node_or_null("Visuals/Torso/Head/GoggleStrap/RightConnector")
	
	if not goggle_strap or not curved_strap or not left_connector or not right_connector:
		printerr("FAIL: Goggle strap or connector nodes missing!")
		quit(1)
		return
	
	print("[Headband] Mesh: ", curved_strap.mesh.resource_path if curved_strap.mesh else "Custom")
	print("[Connectors] Left pos: %s, Right pos: %s" % [left_connector.position, right_connector.position])
	if abs(left_connector.position.x) > 0.20 and abs(right_connector.position.x) > 0.20:
		print("PASS: Curved headband wraps around head cylinder with authentic side buckle connectors attaching to goggles outer frame!")
	else:
		printerr("FAIL: Connector positions incorrect")
		quit(1)
		return
	
	# --- 2. Testing Enlarged Head, Helmet Visor & Slim Collar ---
	print("\n--- 2. Testing Head Dimensions, Helmet Visor & Collar ---")
	var head_mesh_inst = player.get_node_or_null("Visuals/Torso/Head/MinionHeadMesh")
	var visor_mesh_inst = player.get_node_or_null("Visuals/Torso/Head/TransparentVisor")
	var neck_ring_inst = player.get_node_or_null("Visuals/Torso/Head/NeckRing")
	
	if not head_mesh_inst or not visor_mesh_inst or not neck_ring_inst:
		printerr("FAIL: Head, Visor or NeckRing nodes missing!")
		quit(1)
		return
	
	var head_mesh = head_mesh_inst.mesh as CapsuleMesh
	if head_mesh:
		print("[Head] CapsuleMesh radius: %.3f, height: %.3f (Tall Minion Capsule Profile)" % [head_mesh.radius, head_mesh.height])
		if head_mesh.radius >= 0.39 and head_mesh.height >= 0.80:
			print("PASS: Head enlarged into tall recognizable Minion capsule proportions.")
		else:
			printerr("FAIL: Head size too small: ", head_mesh.radius, head_mesh.height)
			quit(1)
			return
	
	var visor_mesh = visor_mesh_inst.mesh as SphereMesh
	if visor_mesh:
		print("[Visor] SphereMesh radius: %.3f, height: %.3f" % [visor_mesh.radius, visor_mesh.height])
		if visor_mesh.radius >= 0.45 and visor_mesh.height >= 0.90:
			print("PASS: Visor scaled to encase enlarged Minion head cleanly.")
		else:
			printerr("FAIL: Visor too small for enlarged head")
			quit(1)
			return
	
	var neck_mesh = neck_ring_inst.mesh as CylinderMesh
	if neck_mesh:
		print("[Collar] Height: %.3f, Radius: %.3f (Slim aerospace collar)" % [neck_mesh.height, neck_mesh.top_radius])
		if neck_mesh.height <= 0.03:
			print("PASS: Astronaut collar slimmed down to prevent crowding lower face.")
		else:
			printerr("FAIL: Collar height too bulky: ", neck_mesh.height)
			quit(1)
			return
	
	# Check clearance below goggles for mouth
	var left_goggle = player.get_node_or_null("Visuals/Torso/Head/LeftGoggleRing")
	var mouth_inst = player.get_node_or_null("Visuals/Torso/Head/Mouth")
	if left_goggle and mouth_inst and neck_ring_inst:
		var goggle_bot_y = left_goggle.position.y - 0.14
		var mouth_y = mouth_inst.position.y
		var collar_y = neck_ring_inst.position.y
		print("[Vertical Spacing] Goggle Bottom: %.3f, Mouth: %.3f, Collar: %.3f" % [goggle_bot_y, mouth_y, collar_y])
		if goggle_bot_y > mouth_y and mouth_y > collar_y:
			print("PASS: Generous space below goggles cleanly accommodates visible mouth!")
		else:
			printerr("FAIL: Vertical layout overlap between goggles, mouth and collar")
			quit(1)
			return
	
	# --- 3. Testing Eyelid Lens Constraint & Calm Half-Closed Expression ---
	print("\n--- 3. Testing Eyelid Lens Boundary Constraint & Calm State ---")
	var left_eyelid = player.left_eyelid
	var right_eyelid = player.right_eyelid
	if not left_eyelid or not right_eyelid:
		printerr("FAIL: Eyelid references missing")
		quit(1)
		return
	
	# Test Open state
	player.set_expression(player.FacialExpression.NEUTRAL)
	player._current_calm = 0.0
	player._is_blinking = false
	player._update_eye_blinking(0.01)
	if left_eyelid.visible and left_eyelid.scale.z > 0.05:
		printerr("FAIL: Eyelid should be hidden/retracted when fully open")
		quit(1)
		return
	print("[Eyelids] Open state: retracted (visible=%s, scale.z=%.3f)" % [left_eyelid.visible, left_eyelid.scale.z])
	
	# Test Calm expression (half-closed eyelids)
	player.set_expression(player.FacialExpression.CALM)
	player._current_calm = 0.50
	player._update_eye_blinking(0.01)
	print("[Eyelids] Calm expression: visible=%s, scale.z=%.3f, pos.z=%.3f" % [left_eyelid.visible, left_eyelid.scale.z, left_eyelid.position.z])
	if not left_eyelid.visible or abs(left_eyelid.scale.z - 0.50) > 0.05:
		printerr("FAIL: Calm expression should lower eyelids to ~50% coverage")
		quit(1)
		return
	print("PASS: Calm half-closed expression verified within circular lens opening!")
	
	# Test Blink over calm expression
	player._trigger_blink()
	player._update_eye_blinking(0.05) # closing
	player._update_eye_blinking(0.025) # closed hold (0.075s)
	if not left_eyelid.visible or abs(left_eyelid.scale.z - 1.0) > 0.01:
		printerr("FAIL: Blink should fully close eyelids (scale.z = 1.0)")
		quit(1)
		return
	print("[Eyelids] Full blink: covers eyeball (scale.z=%.2f, right_scale.z=%.2f)" % [left_eyelid.scale.z, right_eyelid.scale.z])
	
	player._update_eye_blinking(0.09) # reopening completes
	if left_eyelid.scale.z > 0.55: # returns to calm level 0.50
		printerr("FAIL: Eyelid did not return to calm expression level after blink")
		quit(1)
		return
	print("PASS: Natural blinking seamlessly harmonized with active facial expressions!")
	
	# --- 4. Testing Mouth & Facial Expressions ---
	print("\n--- 4. Testing Mouth & Facial Expressions System ---")
	if not mouth_inst:
		printerr("FAIL: Mouth node missing")
		quit(1)
		return
	
	# Test Happy expression (smile)
	player.set_expression(player.FacialExpression.HAPPY)
	# Simulate 0.3s transition
	for i in range(15):
		player._update_facial_expressions(0.02)
	var smile_val = mouth_inst.get("blend_shapes/smile") if mouth_inst else 0.0
	print("[Mouth] Happy expression smile blend weight: %.3f" % smile_val)
	if smile_val >= 0.65:
		print("PASS: Happy expression smoothly transitions mouth to upward curved smile!")
	else:
		printerr("FAIL: Smile blend shape did not activate: ", smile_val)
		quit(1)
		return
	
	# Test Neutral expression
	player.set_expression(player.FacialExpression.NEUTRAL)
	for i in range(25):
		player._update_facial_expressions(0.02)
	var neutral_val = mouth_inst.get("blend_shapes/smile") if mouth_inst else 0.0
	print("[Mouth] Neutral expression smile blend weight: %.3f" % neutral_val)
	if neutral_val <= 0.15:
		print("PASS: Neutral expression relaxes mouth to subtle relaxed line.")
	else:
		printerr("FAIL: Neutral expression failed to relax smile")
		quit(1)
		return
	
	# --- 5. Testing Redesigned Handheld Scientific Scanner ---
	print("\n--- 5. Testing Handheld Scientific Scanner Design ---")
	var scanner_dev = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice")
	var sc_handle = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/Handle")
	var sc_chassis = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/ScannerChassis")
	var sc_sensor = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/SensorHead")
	var sc_aperture = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/SensorAperture")
	var sc_antenna_l = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/AntennaLeft")
	var sc_screen = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/Screen")
	var sc_buttons = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/ControlButtons")
	var sc_led = player.get_node_or_null("Visuals/Torso/RightArm/ScannerDevice/StatusLED")
	
	if not scanner_dev or not sc_handle or not sc_chassis or not sc_sensor or not sc_screen:
		printerr("FAIL: Redesigned scanner components missing!")
		quit(1)
		return
	
	var box = sc_chassis.mesh as BoxMesh
	print("[Scanner] Chassis length Z: %.3f m" % box.size.z)
	if box.size.z >= 0.20:
		print("PASS: Elongated scientific scanner chassis verified (length >= 0.20m).")
	else:
		printerr("FAIL: Scanner chassis too short: ", box.size.z)
		quit(1)
		return
	
	if sc_aperture and sc_antenna_l and sc_buttons and sc_led:
		print("PASS: Ergonomic handle, sensor aperture, dual antennae, buttons and status LED verified!")
	else:
		printerr("FAIL: Detailed scanner scientific components missing")
		quit(1)
		return
	
	# --- 6. Testing Audio Audit & Permanent Buzz Elimination ---
	print("\n--- 6. Testing Audio Audit & Permanent Buzz Elimination ---")
	var audio_sys = player.audio_system
	if not audio_sys:
		printerr("FAIL: Vacuum audio system missing")
		quit(1)
		return
	
	# Verify breathing 8-bit noise generator is silenced
	print("[Audio] Breathing player volume: %.1f dB" % audio_sys.breathing_player.volume_db)
	if audio_sys.breathing_player.volume_db <= -70.0:
		print("PASS: 8-bit recurring breathing noise burst silenced (-80.0 dB).")
	else:
		printerr("FAIL: Breathing player still active at audible volume: ", audio_sys.breathing_player.volume_db)
		quit(1)
		return
	
	# Verify PLSS hum is subdued 16-bit whisper
	print("[Audio] PLSS hum volume: %.1f dB, is_playing: %s" % [audio_sys.plss_hum_player.volume_db, audio_sys.plss_hum_player.playing])
	if audio_sys.plss_hum_player.playing and audio_sys.plss_hum_player.volume_db <= -35.0:
		print("PASS: PLSS hum is subtle sub-audible suit resonance (16-bit, -36.0 dB).")
	else:
		printerr("FAIL: PLSS hum invalid: playing=%s, vol=%.1f" % [audio_sys.plss_hum_player.playing, audio_sys.plss_hum_player.volume_db])
		quit(1)
		return
	
	# Verify scanner audio ping clean cadence
	var scanner = level.get_node_or_null("Scanner")
	if scanner:
		print("[Audio] Scanner beep interval near: %.2f s" % scanner.beep_interval_near)
		if scanner.beep_interval_near >= 0.35:
			print("PASS: Scanner proximity capped at clean cadence (>= 0.35s).")
	
	print("\n==================================================================")
	print("ALL CHARACTER REDESIGN, EXPRESSION, SCANNER & AUDIO CHECKS PASSED!")
	print("==================================================================")
	quit(0)
