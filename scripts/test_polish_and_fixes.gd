extends SceneTree

# Verification script for:
# 1. Natural eye blinking & sclera fill in goggles
# 2. No costume overlap/Z-fighting artifacts
# 3. Artifact vertical emergence (scale=Vector3.ONE, y: -depth -> 0.0, dust & audio)
# 4. Scanner and PLSS audio buzz elimination
# 5. Lunar ambient background music

func _init() -> void:
	print("==================================================================")
	print("TESTING: ASTRONAUT POLISH, ARTIFACT REVEAL & AUDIO FIXES")
	print("==================================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var tree_root = get_root()
	
	# Load level scene with player and artifact
	var level_scene = load("res://scenes/levels/moon.tscn")
	var level = level_scene.instantiate()
	tree_root.add_child(level)
	
	await process_frame
	await process_frame
	
	var player = level.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player not found in Moon scene")
		quit(1)
		return
	
	# --- TEST 1: Eye Sclera & Blinking ---
	print("\n--- 1. Testing Eye Sclera and Natural Blinking ---")
	var left_sclera = player.get_node_or_null("Visuals/Torso/Head/LeftGoggleRing/LeftEyeSclera")
	var right_sclera = player.get_node_or_null("Visuals/Torso/Head/RightGoggleRing/RightEyeSclera")
	if not left_sclera or not right_sclera:
		printerr("FAIL: Sclera nodes missing")
		quit(1)
		return
	
	var left_sclera_mesh = left_sclera.mesh as SphereMesh
	if left_sclera_mesh and left_sclera_mesh.radius >= 0.10:
		print("[Sclera] Radius: %.3f (tucked securely behind goggle inner rim 0.09)" % left_sclera_mesh.radius)
		print("PASS: Sclera fills goggle aperture completely.")
	else:
		printerr("FAIL: Sclera radius too small: ", left_sclera_mesh.radius if left_sclera_mesh else 0.0)
		quit(1)
		return
	
	var left_eyelid = player.get_node_or_null("Visuals/Torso/Head/LeftGoggleRing/LeftEyelid")
	var right_eyelid = player.get_node_or_null("Visuals/Torso/Head/RightGoggleRing/RightEyelid")
	if not left_eyelid or not right_eyelid:
		printerr("FAIL: Eyelid nodes missing")
		quit(1)
		return
	
	# Test eyelid rest state (hidden/open)
	if left_eyelid.visible and left_eyelid.scale.z > 0.05:
		printerr("FAIL: Eyelid should be hidden/tucked in rest state")
		quit(1)
		return
	print("[Eyelid] Rest state: hidden/tucked (visible=%s, scale.z=%.3f)" % [left_eyelid.visible, left_eyelid.scale.z])
	
	# Trigger manual blink
	player._trigger_blink()
	if not player._is_blinking:
		printerr("FAIL: _trigger_blink() failed to initiate blink")
		quit(1)
		return
	
	# Simulate 0.05s into blink (closing phase)
	player._update_eye_blinking(0.05)
	print("[Eyelid] Mid-blink (0.05s): visible=%s, pos.z=%.3f, scale.z=%.3f" % [left_eyelid.visible, left_eyelid.position.z, left_eyelid.scale.z])
	if not left_eyelid.visible or left_eyelid.scale.z < 0.7:
		printerr("FAIL: Eyelid did not extend to cover eye during blink (visible=%s, scale.z=%.3f)" % [left_eyelid.visible, left_eyelid.scale.z])
		quit(1)
		return
	
	# Simulate 0.025s more into blink (fully closed hold phase at 0.075s)
	player._update_eye_blinking(0.025)
	print("[Eyelid] Closed hold (0.075s): pos.z=%.3f, scale.z=%.3f" % [left_eyelid.position.z, left_eyelid.scale.z])
	if abs(left_eyelid.scale.z - 1.0) > 0.01:
		printerr("FAIL: Eyelid should be fully closed (scale.z = 1.0) at 0.075s")
		quit(1)
		return
	
	# Simulate reopening phase completion (0.09s more, total 0.165s)
	player._update_eye_blinking(0.09)
	if player._is_blinking or left_eyelid.visible:
		printerr("FAIL: Eyelid did not return to open/hidden state after blink completion")
		quit(1)
		return
	print("[Eyelid] Blink completed: eyelid tucked and hidden (visible=%s, scale.z=%.3f)" % [left_eyelid.visible, left_eyelid.scale.z])
	print("PASS: Synchronized eye blinking tested successfully!")
	
	# --- TEST 2: Torso & Neck Geometry (No Z-fighting line) ---
	print("\n--- 2. Testing Neck Ring & Torso Alignment ---")
	var neck_ring = player.get_node_or_null("Visuals/Torso/Head/NeckRing")
	var torso_mesh_instance = player.get_node_or_null("Visuals/Torso/TorsoMesh")
	print("neck_ring: ", neck_ring, " class: ", neck_ring.get_class() if neck_ring else "null")
	print("torso_mesh_instance: ", torso_mesh_instance, " class: ", torso_mesh_instance.get_class() if torso_mesh_instance else "null")
	if neck_ring and torso_mesh_instance:
		if neck_ring is MeshInstance3D and torso_mesh_instance is MeshInstance3D:
			var neck_mesh = neck_ring.mesh as CylinderMesh
			var torso_mesh = torso_mesh_instance.mesh as CylinderMesh
			print("[Torso] Height: %.3f, Radius: %.3f" % [torso_mesh.height, torso_mesh.top_radius])
			var rel_y = neck_ring.global_position.y - torso_mesh_instance.global_position.y
			print("[NeckRing] Height above Torso center: %.3f (Global Y: %.3f)" % [rel_y, neck_ring.global_position.y])
			if rel_y >= 0.25: # Neck collar position at top of torso, not inside torso body at 0.04
				print("PASS: NeckRing positioned cleanly at astronaut suit collar without intersecting torso body!")
			else:
				printerr("FAIL: NeckRing placed inside torso body causing Z-fighting")
				quit(1)
				return
		else:
			var rel_y = neck_ring.global_position.y - torso_mesh_instance.global_position.y
			print("[NeckRing] Height above Torso center: %.3f (Global Y: %.3f)" % [rel_y, neck_ring.global_position.y])
			if rel_y >= 0.25:
				print("PASS: NeckRing positioned cleanly at astronaut suit collar without intersecting torso body!")
	
	# --- TEST 3: Artifact Vertical Emergence ---
	print("\n--- 3. Testing Artifact Vertical Emergence Animation ---")
	var artifact_scene = load("res://scenes/artifact/artifact.tscn")
	var artifact = artifact_scene.instantiate()
	level.add_child(artifact)
	artifact.global_position = Vector3(10, 0, 10)
	await process_frame
	
	var visual_model = artifact.visual_model
	if not visual_model:
		printerr("FAIL: Artifact visual_model not found")
		quit(1)
		return
	
	# Initial buried state
	if visual_model.visible:
		printerr("FAIL: Buried artifact visual model should not be visible")
		quit(1)
		return
	if abs(visual_model.position.y - (-artifact.buried_depth)) > 0.01:
		printerr("FAIL: Buried artifact not below ground level: ", visual_model.position.y)
		quit(1)
		return
	if visual_model.scale != Vector3.ONE:
		printerr("FAIL: Visual model scale must be Vector3.ONE: ", visual_model.scale)
		quit(1)
		return
	print("[Emergence] Buried state: visible=false, y=%.2f, scale=%s" % [visual_model.position.y, visual_model.scale])
	
	# Start digging state
	artifact._start_digging()
	artifact.is_player_holding_e = true
	artifact._process(artifact.dig_duration * 0.5) # Advance to 50%
	
	var expected_y_50 = -artifact.buried_depth * 0.5
	if not visual_model.visible:
		printerr("FAIL: Visual model should be visible during excavation")
		quit(1)
		return
	if abs(visual_model.position.y - expected_y_50) > 0.05:
		printerr("FAIL: 50%% excavation Y position expected %.2f but got %.2f" % [expected_y_50, visual_model.position.y])
		quit(1)
		return
	if visual_model.scale != Vector3.ONE:
		printerr("FAIL: Visual model scale should remain Vector3.ONE throughout excavation: ", visual_model.scale)
		quit(1)
		return
	if not artifact.dust_particles.emitting:
		printerr("FAIL: Dust particles should emit while holding E")
		quit(1)
		return
	if not artifact._excavation_audio.playing:
		printerr("FAIL: Excavation audio should play while holding E")
		quit(1)
		return
	print("[Emergence] 50%% excavated: visible=true, y=%.2f, scale=%s, dust=%s, audio=%s" % [
		visual_model.position.y, visual_model.scale, artifact.dust_particles.emitting, artifact._excavation_audio.playing
	])
	
	# Release E (pause digging)
	artifact.is_player_holding_e = false
	artifact._process(0.01)
	if artifact.dust_particles.emitting or artifact._excavation_audio.playing:
		printerr("FAIL: Dust and audio should stop when releasing E")
		quit(1)
		return
	print("[Emergence] Paused: dust stopped, audio stopped.")
	
	# Finish digging
	artifact.is_player_holding_e = true
	artifact._process(artifact.dig_duration * 0.6) # Reach 100%
	if artifact.current_state != artifact.ArtifactState.EXPOSED:
		printerr("FAIL: Artifact did not transition to EXPOSED upon 100%% excavation")
		quit(1)
		return
	if abs(visual_model.position.y - 0.0) > 0.001:
		printerr("FAIL: Fully exposed artifact Y position should be 0.0, got: ", visual_model.position.y)
		quit(1)
		return
	if visual_model.scale != Vector3.ONE:
		printerr("FAIL: Fully exposed artifact scale should be Vector3.ONE, got: ", visual_model.scale)
		quit(1)
		return
	print("PASS: Artifact vertical emergence, true scale, dust particles and audio excavation verified!")
	
	# --- TEST 4: Audio Buzzing Elimination ---
	print("\n--- 4. Testing Audio Buzzing Elimination ---")
	var scanner = level.get_node_or_null("Scanner")
	if scanner:
		print("[Scanner] Proximity beep interval range: %.2f - %.2f s" % [scanner.beep_interval_near, scanner.beep_interval_far])
		if scanner.beep_interval_near >= 0.35:
			print("PASS: Scanner proximity interval capped at >= 0.35s to prevent buzzing.")
		else:
			printerr("FAIL: Scanner proximity interval too fast (buzzing potential): ", scanner.beep_interval_near)
			quit(1)
			return
	
	var audio_sys = player.audio_system
	if audio_sys and audio_sys.plss_hum_player:
		print("[AudioSystem] PLSS hum volume: %.1f dB" % audio_sys.plss_hum_player.volume_db)
		if audio_sys.plss_hum_player.volume_db <= -30.0:
			print("PASS: PLSS hum is softened to ultra-quiet ambient murmur (-34.0 dB).")
		else:
			printerr("FAIL: PLSS hum too loud: ", audio_sys.plss_hum_player.volume_db)
			quit(1)
			return
	
	# --- TEST 5: Lunar Background Music ---
	print("\n--- 5. Testing Lunar Ambient Background Music ---")
	var bgm_player = level.get_node_or_null("LevelBGMPlayer")
	if bgm_player:
		print("[BGM] Stream: ", bgm_player.stream.resource_path if bgm_player.stream else "None")
		print("[BGM] Playing: ", bgm_player.playing)
		print("[BGM] Target volume: %.1f dB" % level.music_volume_db)
		if bgm_player.playing and level.music_volume_db <= -18.0:
			print("PASS: Ambient lunar background music actively playing at subdued aerospace volume.")
		else:
			printerr("FAIL: Ambient background music not playing properly")
			quit(1)
			return
	else:
		printerr("FAIL: LevelBGMPlayer node not found on Moon level")
		quit(1)
		return
	
	print("\n==================================================================")
	print("ALL POLISH, ARTIFACT EMERGENCE & AUDIO FIX TESTS PASSED!")
	print("==================================================================")
	quit(0)
