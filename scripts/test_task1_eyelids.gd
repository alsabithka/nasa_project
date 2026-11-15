extends SceneTree

func _init() -> void:
	call_deferred("_test_eyelids")

func _test_eyelids() -> void:
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate()
	get_root().add_child(player)
	
	await process_frame
	await process_frame
	
	var left_eyelid = player.left_eyelid
	var right_eyelid = player.right_eyelid
	
	if not left_eyelid or not right_eyelid:
		printerr("FAIL: Eyelid nodes missing")
		quit(1)
		return
	
	var left_mat = left_eyelid.get_surface_override_material(0) as ShaderMaterial
	var right_mat = right_eyelid.get_surface_override_material(0) as ShaderMaterial
	
	if not left_mat or not right_mat:
		printerr("FAIL: Eyelids missing ShaderMaterial overrides")
		quit(1)
		return
	
	if left_mat == right_mat:
		printerr("FAIL: Eyelids must NOT share the same ShaderMaterial instance")
		quit(1)
		return
	
	print("PASS: Both eyelids have separate ShaderMaterials.")
	
	# Test Neutral
	player.set_expression(player.FacialExpression.NEUTRAL)
	if player._target_smile != 0.0 or player._target_calm != 0.0:
		printerr("FAIL: NEUTRAL target values mismatch")
		quit(1)
		return
	print("PASS: NEUTRAL expression smile=0.0, calm=0.0")
	
	# Test Happy
	player.set_expression(player.FacialExpression.HAPPY)
	if player._target_smile != 1.0 or player._target_calm != 0.0:
		printerr("FAIL: HAPPY target values mismatch")
		quit(1)
		return
	print("PASS: HAPPY expression smile=1.0, calm=0.0")
	
	# Test Calm
	player.set_expression(player.FacialExpression.CALM)
	if abs(player._target_smile - 0.60) > 0.01 or abs(player._target_calm - 0.50) > 0.01:
		printerr("FAIL: CALM target values mismatch: smile=%.2f, calm=%.2f" % [player._target_smile, player._target_calm])
		quit(1)
		return
	print("PASS: CALM expression smile=0.60, calm=0.50")
	
	# Test coverage application
	player._apply_eyelid_coverage(0.0)
	if left_eyelid.visible:
		printerr("FAIL: Eyelid should be hidden at coverage 0.0")
		quit(1)
		return
	
	player._apply_eyelid_coverage(0.5)
	if not left_eyelid.visible or not right_eyelid.visible:
		printerr("FAIL: Eyelid should be visible at coverage 0.5")
		quit(1)
		return
	var cov_l = left_mat.get_shader_parameter("coverage")
	var cov_r = right_mat.get_shader_parameter("coverage")
	if abs(cov_l - 0.5) > 0.01 or abs(cov_r - 0.5) > 0.01:
		printerr("FAIL: Shader coverage parameter not set properly: %s, %s" % [cov_l, cov_r])
		quit(1)
		return
	print("PASS: Coverage 0.5 correctly sets shader parameter.")
	
	# Test Blink in Calm state
	player._current_calm = 0.50
	player._is_blinking = false
	player._trigger_blink()
	# Mid-close
	player._update_eye_blinking(0.04)
	var mid_cov = left_mat.get_shader_parameter("coverage")
	print("Blink mid-close coverage: %.3f" % mid_cov)
	if mid_cov <= 0.5 or mid_cov >= 1.0:
		printerr("FAIL: Mid-close coverage invalid")
		quit(1)
		return
	
	# Full close hold
	player._update_eye_blinking(0.05)
	var close_cov = left_mat.get_shader_parameter("coverage")
	print("Blink closed coverage: %.3f" % close_cov)
	if abs(close_cov - 1.0) > 0.01:
		printerr("FAIL: Full close coverage should be 1.0")
		quit(1)
		return
	
	# Open back to calm
	player._update_eye_blinking(0.12)
	var end_cov = left_mat.get_shader_parameter("coverage")
	print("Blink reopened coverage: %.3f" % end_cov)
	if abs(end_cov - 0.50) > 0.02:
		printerr("FAIL: Reopened coverage should return to calm (0.50)")
		quit(1)
		return
	print("PASS: Blink in CALM state closes 0.5 -> 1.0 -> 0.5.")
	
	print("\nALL TASK 1 EYELID & BLINKING TESTS PASSED!")
	quit(0)
