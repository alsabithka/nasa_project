extends SceneTree

# Runs full game regression check: Main Menu, Moon Level, Mars Level
func _init() -> void:
	print("Running full game regression check...")
	call_deferred("_run_checks")

func _run_checks() -> void:
	# 1. Main menu
	var menu_scene = load("res://scenes/main_menu.tscn")
	if not menu_scene:
		printerr("FAIL: Main menu scene cannot load!")
		quit(1)
		return
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	menu.queue_free()
	print("PASS: Main menu loaded.")
	
	# 2. Moon level
	var moon_scene = load("res://scenes/levels/moon.tscn")
	var moon = moon_scene.instantiate()
	root.add_child(moon)
	for i in range(10):
		await process_frame
	moon.queue_free()
	print("PASS: Moon level loaded and initialized.")
	
	# 3. Mars level
	var mars_scene = load("res://scenes/levels/mars.tscn")
	var mars = mars_scene.instantiate()
	root.add_child(mars)
	for i in range(10):
		await process_frame
	mars.queue_free()
	print("PASS: Mars level loaded and initialized.")
	
	print("ALL REGRESSION CHECKS PASSED.")
	quit(0)
