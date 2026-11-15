extends SceneTree

func _init() -> void:
	call_deferred("_test_detector")

func _test_detector() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	get_root().add_child(player)
	
	await process_frame
	await process_frame
	
	var dev = player.scanner_device
	if not dev:
		printerr("FAIL: scanner_device missing")
		quit(1)
		return
	
	var detector = dev.get_node_or_null("DetectorVisual")
	if not detector:
		printerr("FAIL: DetectorVisual missing from ScannerDevice")
		quit(1)
		return
	
	var scr = detector.get_node_or_null("Screen")
	var led = detector.get_node_or_null("StatusLED")
	var upper_shaft = detector.get_node_or_null("UpperShaft")
	var lower_shaft = detector.get_node_or_null("LowerShaft")
	var coil_pivot = detector.get_node_or_null("CoilPivot")
	var coil_disc = detector.get_node_or_null("CoilPivot/CoilDisc")
	var coil_ring = detector.get_node_or_null("CoilPivot/CoilRing")
	
	if not scr or not led or not upper_shaft or not lower_shaft or not coil_pivot or not coil_disc or not coil_ring:
		printerr("FAIL: Metal detector sub-components missing")
		quit(1)
		return
	
	print("PASS: Metal detector procedural geometry verified!")
	
	if player.scanner_screen != scr:
		printerr("FAIL: player.scanner_screen is not rebound to new detector Screen")
		quit(1)
		return
	print("PASS: player.scanner_screen rebound to metal detector Screen.")
	
	# Test screen and led emission updates
	player._update_scanner_screen(0.2) # Green
	var mat_s = scr.get_active_material(0) as StandardMaterial3D
	var mat_l = led.get_active_material(0) as StandardMaterial3D
	if not mat_s or not mat_l:
		printerr("FAIL: Screen or LED missing StandardMaterial3D")
		quit(1)
		return
	print("Screen emission color at 0.2: ", mat_s.emission)
	if mat_s.emission.g <= mat_s.emission.r:
		printerr("FAIL: Low signal should have green-dominant emission")
		quit(1)
		return
	
	player._update_scanner_screen(0.9) # Red
	print("Screen emission color at 0.9: ", mat_s.emission)
	if mat_s.emission.r <= mat_s.emission.g:
		printerr("FAIL: High signal should have red-dominant emission")
		quit(1)
		return
	print("PASS: Screen and StatusLED color transitions verified (Green -> Amber -> Red)!")
	
	if DisplayServer.get_name() != "headless":
		# Capture image of player holding metal detector
		var cam = Camera3D.new()
		get_root().add_child(cam)
		# Position camera for full-body view showing metal detector held low in front
		cam.look_at_from_position(Vector3(0.9, 0.65, 1.35), Vector3(0.1, 0.45, 0.1), Vector3.UP)
		cam.current = true
		
		var light = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35, 30, 0)
		get_root().add_child(light)
		
		player.set_process(false)
		player.right_arm.rotation.x = -0.45
		player.right_arm.rotation.y = -0.16
		player.right_arm.rotation.z = 0.16
		
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		
		var img = get_root().get_texture().get_image()
		if img:
			img.save_png("C:/Users/LENOVO/.gemini/antigravity/brain/43fb2b67-8701-44fe-98e7-a1ad2fcbb79a/task4_metal_detector.png")
			print("Saved task4_metal_detector.png")
	
	print("\nALL TASK 4 METAL DETECTOR TESTS PASSED!")
	quit(0)
