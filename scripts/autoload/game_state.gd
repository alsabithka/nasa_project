extends Node

# Echoes Beyond Earth - GameState Autoload Singleton
# Manages artifact database, recovery state, and planet unlocks.

signal artifact_recovered(artifact_id: String)
signal mission_completed(planet: String)
signal planet_unlocked(planet: String)

var artifacts_data: Dictionary = {}
var recovered_artifacts: Array[String] = []
var unlocked_planets: Array[String] = ["Moon"]
var current_planet: String = "Moon"

func _ready() -> void:
	setup_default_inputs()
	load_artifacts_data()
	print("[GameState] Initialized. Loaded ", artifacts_data.size(), " artifacts. Unlocked planets: ", unlocked_planets)

func setup_default_inputs() -> void:
	_add_key_action("move_forward", [KEY_W, KEY_UP])
	_add_key_action("move_backward", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE])
	_add_key_action("interact", [KEY_E])
	_add_key_action("toggle_journal", [KEY_J])
	_add_key_action("toggle_scanner", [KEY_TAB])
	_add_key_action("inspect_geology", [KEY_F])
	_add_key_action("toggle_camera_view", [KEY_V])
	_add_key_action("toggle_gait", [KEY_C])

func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for k in keys:
		var event = InputEventKey.new()
		event.physical_keycode = k
		InputMap.action_add_event(action_name, event)

func load_artifacts_data() -> void:
	artifacts_data.clear()
	var file_path = "res://data/artifacts.json"
	if not FileAccess.file_exists(file_path):
		printerr("[GameState] Artifact data file not found at: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("[GameState] Failed to open: ", file_path)
		return
	
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		printerr("[GameState] JSON Parse Error: ", json.get_error_message(), " on line ", json.get_error_line())
		return
	
	var data = json.data
	if data is Dictionary and data.has("artifacts"):
		for item in data["artifacts"]:
			if item is Dictionary and item.has("id"):
				artifacts_data[item["id"]] = item

func register_artifact(artifact_id: String) -> void:
	if not artifacts_data.has(artifact_id):
		printerr("[GameState] Attempted to register unknown artifact: ", artifact_id)
		return
	
	if recovered_artifacts.has(artifact_id):
		print("[GameState] Artifact already recovered: ", artifact_id)
		return
	
	recovered_artifacts.append(artifact_id)
	var art_name = artifacts_data[artifact_id].get("name", artifact_id)
	print("[GameState] Artifact recovered: ", art_name, " (", artifact_id, ")")
	artifact_recovered.emit(artifact_id)
	
	# Check mission completion
	var planet = artifacts_data[artifact_id].get("location", "Moon")
	var rec_count = get_recovered_count(planet)
	var total_count = get_total_count(planet)
	
	if rec_count >= total_count:
		print("[GameState] Mission completed for planet: ", planet)
		mission_completed.emit(planet)
		if planet == "Moon" and not is_planet_unlocked("Mars"):
			unlock_planet("Mars")

func is_artifact_recovered(artifact_id: String) -> bool:
	return recovered_artifacts.has(artifact_id)

func get_artifact_data(artifact_id: String) -> Dictionary:
	if artifacts_data.has(artifact_id):
		return artifacts_data[artifact_id]
	return {}

func get_recovered_count(planet: String) -> int:
	var count = 0
	for id in recovered_artifacts:
		if artifacts_data.has(id):
			var loc = artifacts_data[id].get("location", "")
			if loc.to_lower() == planet.to_lower():
				count += 1
	return count

func get_total_count(planet: String) -> int:
	var count = 0
	for id in artifacts_data.keys():
		var loc = artifacts_data[id].get("location", "")
		if loc.to_lower() == planet.to_lower():
			count += 1
	return count

func is_planet_unlocked(planet: String) -> bool:
	for p in unlocked_planets:
		if p.to_lower() == planet.to_lower():
			return true
	return false

func unlock_planet(planet: String) -> void:
	if not is_planet_unlocked(planet):
		unlocked_planets.append(planet)
		print("[GameState] Unlocked planet: ", planet)
		planet_unlocked.emit(planet)

func reset_progress() -> void:
	recovered_artifacts.clear()
	unlocked_planets = ["Moon"]
