extends SceneTree

# Captures visual verification screenshots of:
# 1. Three-quarter view (Curved strap, enlarged head, mouth, new scanner)
# 2. Front view: Neutral expression
# 3. Front view: Happy expression (smile)
# 4. Front view: Calm expression (half-closed eyelids)
# 5. Side view: Headband hugging cylinder curvature

func _init() -> void:
	print("--- Commencing Visual Verification Capture ---")
	call_deferred("_capture_views")

func _capture_views() -> void:
	var tree_root = get_root()
	var level_scene = load("res://scenes/levels/moon.tscn")
	var level = level_scene.instantiate()
	tree_root.add_child(level)
	
	await process_frame
	await process_frame
	
	var player = level.get_node_or_null("Player")
	if not player:
		printerr("FAIL: Player missing")
		quit(1)
		return
	
	# Wait for settlement
	for i in range(40):
		await process_frame
	
	# Create a dedicated high-fidelity inspection camera
	var cam = Camera3D.new()
	cam.current = true
	cam.fov = 40.0
	level.add_child(cam)
	
	var player_pos = player.global_position
	var head_pos = player_pos + Vector3(0, 1.05, 0)
	
	# VIEW 1: Three-Quarter Perspective (Curved headband, connector, enlarged head, new scanner)
	player.set_expression(player.FacialExpression.HAPPY)
	player._current_smile = 1.0
	player._current_calm = 0.0
	player._target_smile = 1.0
	player._target_calm = 0.0
	player._update_facial_expressions(0.001)
	player._apply_eyelid_coverage(0.0)
	
	cam.global_position = head_pos + Vector3(1.3, 0.25, 1.9)
	cam.look_at(head_pos + Vector3(0, -0.1, 0), Vector3.UP)
	
	await process_frame
	await process_frame
	_save_screenshot("verify_three_quarter.png")
	print("Captured verify_three_quarter.png")
	
	# VIEW 2: Front Close-Up - Happy Expression (Smile)
	cam.global_position = head_pos + Vector3(0.0, 0.0, 1.55)
	cam.look_at(head_pos, Vector3.UP)
	
	await process_frame
	await process_frame
	_save_screenshot("verify_front_happy.png")
	print("Captured verify_front_happy.png")
	
	# VIEW 3: Front Close-Up - Calm Expression (Half-closed eyelids within lens)
	player.set_expression(player.FacialExpression.CALM)
	player._current_smile = 0.0
	player._current_calm = 0.50
	player._target_smile = 0.0
	player._target_calm = 0.50
	player._update_facial_expressions(0.001)
	player._apply_eyelid_coverage(0.50)
	
	await process_frame
	await process_frame
	_save_screenshot("verify_front_calm.png")
	print("Captured verify_front_calm.png")
	
	# VIEW 4: Side View - Headband Curvature
	player.set_expression(player.FacialExpression.NEUTRAL)
	player._current_smile = 0.0
	player._current_calm = 0.0
	player._target_smile = 0.0
	player._target_calm = 0.0
	player._update_facial_expressions(0.001)
	player._apply_eyelid_coverage(0.0)
	
	cam.global_position = head_pos + Vector3(1.7, 0.05, 0.1)
	cam.look_at(head_pos, Vector3.UP)
	
	await process_frame
	await process_frame
	_save_screenshot("verify_side_headband.png")
	print("Captured verify_side_headband.png")
	
	print("--- Visual Screenshots Successfully Captured ---")
	quit(0)

func _save_screenshot(filename: String) -> void:
	var img = get_root().get_viewport().get_texture().get_image()
	if img:
		img.save_png(filename)
