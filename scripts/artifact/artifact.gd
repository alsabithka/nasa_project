extends Area3D

const HistoricalSpacecraftModels = preload("res://scripts/spacecraft/historical_spacecraft_models.gd")

# Echoes Beyond Earth - Artifact with full dig/clean discovery sequence

# ---- Existing signals (kept for compatibility) ----
signal artifact_interacted(artifact_id: String)

# ---- New discovery-sequence signals ----
signal dig_started()
signal dig_completed()
signal cleaning_started()
signal cleaning_completed(artifact_id: String)
signal state_changed(new_state: int)

# ---- State machine ----
enum ArtifactState {
	BURIED,       # Only scanner can detect; no visual
	DIG_SITE,     # Player is here; show dig prompt
	DIGGING,      # E held; digging in progress
	EXPOSED,      # Fully dug; show recover prompt
	CLEANING,     # Cleaning UI active
	IDENTIFIED    # Fully recovered and identified
}

# ---- Exports ----
@export var artifact_id: String = "apollo_lrv"
@export var interaction_range: float = 3.5
@export var dig_duration: float = 4.0
@export var clean_duration: float = 7.0
@export var buried_depth: float = 1.35 # Distance below ground before excavation begins

# ---- Onready nodes (must match artifact.tscn) ----
@onready var prompt_label: Label3D = $PromptLabel
@onready var beacon_ring: MeshInstance3D = $BeaconRing
@onready var visual_model: Node3D = $VisualModel
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var dig_progress_label: Label3D = $DigProgressLabel

# ---- State variables ----
var current_state: ArtifactState = ArtifactState.BURIED
var dig_progress: float = 0.0
var clean_progress: float = 0.0
var is_player_holding_e: bool = false
var dig_particles_active: bool = false

# ---- Internal ----
var is_recovered: bool = false
var artifact_name: String = ""
var _beacon_phase: float = 0.0
var _dig_minigame: CanvasLayer = null
var _clean_ui: CanvasLayer = null
var _scanner_ref: Node = null
var _is_player_in_zone: bool = false
var _interacting_player: CharacterBody3D = null
var _excavation_audio: AudioStreamPlayer3D = null
var _story_requested: bool = false   # P7: player chose WATCH STORY in the Catalogue Entry
var _prompt_shown: bool = false      # P7: contextual key-cap prompt currently shown on the HUD

func _get_player() -> CharacterBody3D:
	if _interacting_player and is_instance_valid(_interacting_player):
		return _interacting_player
	return get_tree().get_first_node_in_group("player") as CharacterBody3D

func get_interaction_anchor(player_pos: Vector3) -> Vector3:
	var diff = player_pos - global_position
	diff.y = 0.0
	var dist = diff.length()
	var dir = diff.normalized() if dist > 0.1 else Vector3(0, 0, 1.8)
	var anchor = global_position + dir * 1.8
	anchor.y = player_pos.y
	return anchor

# ---- Public interface (kept for scanner & game_state compatibility) ----
func get_artifact_id() -> String:
	return artifact_id

func get_world_position() -> Vector3:
	return global_position

func _ready() -> void:
	add_to_group("artifacts")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_load_artifact_metadata()
	_update_visual_representation()
	_update_state_from_gamestate()
	_update_state_visuals()
	
	# Configure dust particles
	_setup_dust_particles()
	_setup_excavation_audio()
	
	# Listen for future recovery signals from game_state
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.artifact_recovered.connect(_on_artifact_recovered_globally)
	
	# Connect to scanner's locked_on_location signal
	call_deferred("_connect_to_scanner")

func _connect_to_scanner() -> void:
	var scanner = get_tree().get_first_node_in_group("scanner")
	if scanner:
		_scanner_ref = scanner
		if scanner.has_signal("locked_on_location"):
			scanner.locked_on_location.connect(_on_scanner_locked_on)
		if scanner.has_signal("left_location"):
			scanner.left_location.connect(_on_scanner_left)

func _setup_dust_particles() -> void:
	if not dust_particles:
		return
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, -1.62, 0)
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.5
	pm.scale_min = 0.03
	pm.scale_max = 0.06
	pm.color = Color(0.65, 0.6, 0.5, 0.8)
	dust_particles.process_material = pm
	dust_particles.amount = 24
	dust_particles.lifetime = 1.2
	dust_particles.emitting = false

func _setup_excavation_audio() -> void:
	_excavation_audio = AudioStreamPlayer3D.new()
	_excavation_audio.name = "ExcavationAudio"
	_excavation_audio.bus = &"Master"
	_excavation_audio.volume_db = -16.0
	_excavation_audio.max_distance = 18.0
	add_child(_excavation_audio)
	
	# Generate 16-bit soft regolith granulated excavation loop
	var sample_rate = 22050
	var duration = 0.5
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var scrape = sin(t * 110.0 * TAU) * 0.25
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var env = sin(t / duration * PI) * 0.8
		var sample_val = clampi(int((scrape + noise) * env * 22000.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.data = data
	_excavation_audio.stream = wav

func _play_excavation_audio() -> void:
	if _excavation_audio and not _excavation_audio.playing:
		_excavation_audio.play()

func _stop_excavation_audio() -> void:
	if _excavation_audio and _excavation_audio.playing:
		_excavation_audio.stop()

func _load_artifact_metadata() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var data = game_state.get_artifact_data(artifact_id)
		if not data.is_empty():
			artifact_name = data.get("name", artifact_id)
		else:
			artifact_name = artifact_id.capitalize()
	else:
		artifact_name = artifact_id.capitalize()

func _update_state_from_gamestate() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_artifact_recovered(artifact_id):
		current_state = ArtifactState.IDENTIFIED
		is_recovered = true

func _on_artifact_recovered_globally(recovered_id: String) -> void:
	if recovered_id == artifact_id and current_state != ArtifactState.IDENTIFIED:
		current_state = ArtifactState.IDENTIFIED
		is_recovered = true
		_update_state_visuals()

# ---- Scanner event handlers ----
func _on_scanner_locked_on() -> void:
	# Only respond if buried and scanner's current closest is this artifact
	if current_state != ArtifactState.BURIED:
		return
	if not _scanner_ref:
		_scanner_ref = get_tree().get_first_node_in_group("scanner")
	if _scanner_ref and _scanner_ref.get_current_target() == artifact_id:
		_set_state(ArtifactState.DIG_SITE)

func _on_scanner_left() -> void:
	# If we were in DIG_SITE but player moved away (via scanner leaving)
	if current_state == ArtifactState.DIG_SITE:
		_set_state(ArtifactState.BURIED)

# ---- Body enter/exit ----
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_is_player_in_zone = true
		_interacting_player = body as CharacterBody3D
		if current_state == ArtifactState.BURIED:
			_set_state(ArtifactState.DIG_SITE)
		_refresh_prompt()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_is_player_in_zone = false
		if current_state == ArtifactState.DIG_SITE:
			_set_state(ArtifactState.BURIED)
		elif current_state == ArtifactState.DIGGING:
			_cancel_digging()
		_interacting_player = null
		_refresh_prompt()

# ---- State machine ----
func _set_state(new_state: ArtifactState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	_update_state_visuals()

func _update_state_visuals() -> void:
	_refresh_prompt()
	if prompt_label:
		prompt_label.visible = false  # P7: the prompt is the HUD key-cap (node kept: tests reference it)
	if not prompt_label or not beacon_ring or not visual_model:
		return
	
	match current_state:
		ArtifactState.BURIED:
			visual_model.visible = false
			visual_model.scale = Vector3.ONE
			visual_model.position.y = -buried_depth
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(1.0, 0.65, 0.0, 0.7), Color(1.0, 0.5, 0.0))
		
		ArtifactState.DIG_SITE:
			visual_model.visible = false
			visual_model.scale = Vector3.ONE
			visual_model.position.y = -buried_depth
			prompt_label.text = "Excavate subsurface anomaly"
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(1.0, 0.616, 0.196, 0.9), Color(1.0, 0.616, 0.196))
		
		ArtifactState.DIGGING:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			visual_model.position.y = lerp(-buried_depth, 0.0, dig_progress)
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = true
				dig_progress_label.text = "EXCAVATING REGOLITH: %d%%" % int(dig_progress * 100.0)
				dig_progress_label.modulate = UITokens.SIGNAL_CYAN
			_set_beacon_color(Color(1.0, 0.616, 0.196, 0.9), Color(1.0, 0.616, 0.196))
		
		ArtifactState.EXPOSED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			visual_model.position.y = 0.0
			prompt_label.text = "Recover and decontaminate specimen"
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(0.224, 0.898, 0.549, 0.7), Color(0.224, 0.898, 0.549))
		
		ArtifactState.CLEANING:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			visual_model.position.y = 0.0
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.IDENTIFIED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			visual_model.position.y = 0.0
			prompt_label.text = "Catalogued: " + artifact_name
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(0.224, 0.898, 0.549, 0.6), Color(0.224, 0.898, 0.549))
			is_recovered = true

# P7: contextual prompt = WorldHud key-cap + verb (key comes from the InputMap), shown only while
# the player stands in the zone. Routed through the "world_hud" group so no HUD reference is needed.
func _refresh_prompt() -> void:
	var verb := ""
	if _is_player_in_zone:
		match current_state:
			ArtifactState.DIG_SITE:
				verb = "Excavate subsurface anomaly"
			ArtifactState.EXPOSED:
				verb = "Recover and decontaminate specimen"
	if not is_inside_tree():
		return
	if verb != "":
		get_tree().call_group("world_hud", "show_prompt", "interact", verb)
		_prompt_shown = true
	elif _prompt_shown:
		get_tree().call_group("world_hud", "hide_prompt")
		_prompt_shown = false

func _exit_tree() -> void:
	if _prompt_shown and is_inside_tree():
		get_tree().call_group("world_hud", "hide_prompt")
		_prompt_shown = false

func _set_beacon_color(albedo: Color, emission: Color) -> void:
	if not beacon_ring:
		return
	var mat = beacon_ring.get_active_material(0)
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		mat.albedo_color = albedo
		mat.emission = emission
		beacon_ring.set_surface_override_material(0, mat)

# ---- Process ----
func _process(delta: float) -> void:
	_beacon_phase += delta
	
	# Beacon ring animation
	if beacon_ring:
		beacon_ring.rotate_y(delta * (2.5 if current_state == ArtifactState.DIG_SITE else 0.8))
		match current_state:
			ArtifactState.BURIED, ArtifactState.DIG_SITE:
				var pulse = (sin(_beacon_phase * 3.0) + 1.0) * 0.5
				var spd = 4.0 if current_state == ArtifactState.DIG_SITE else 1.5
				pulse = (sin(_beacon_phase * spd) + 1.0) * 0.5
				beacon_ring.scale = Vector3(1.0 + pulse * 0.2, 1.0, 1.0 + pulse * 0.2)
			ArtifactState.EXPOSED, ArtifactState.IDENTIFIED:
				var pulse = (sin(_beacon_phase * 2.0) + 1.0) * 0.5
				beacon_ring.scale = Vector3(1.0 + pulse * 0.1, 1.0, 1.0 + pulse * 0.1)
			_:
				beacon_ring.scale = Vector3.ONE
	
# ---- Input ----
func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_in_zone and current_state != ArtifactState.CLEANING and current_state != ArtifactState.DIGGING:
		return
	
	if event.is_action_pressed("interact"):
		match current_state:
			ArtifactState.DIG_SITE:
				_start_digging_minigame()
			ArtifactState.EXPOSED:
				_start_cleaning()

func _start_digging_minigame() -> void:
	_set_state(ArtifactState.DIGGING)
	dig_started.emit()
	var player = _get_player()
	if player and player.has_method("begin_interaction"):
		var anchor = get_interaction_anchor(player.global_position)
		player.begin_interaction(anchor, global_position)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var minigame_scene = load("res://scenes/ui/dig_minigame.tscn")
	if not minigame_scene:
		_complete_digging()
		return
	
	_dig_minigame = minigame_scene.instantiate()
	if "artifact_id" in _dig_minigame:
		_dig_minigame.artifact_id = artifact_id
	_dig_minigame.dig_finished.connect(_on_dig_minigame_finished)
	_dig_minigame.dig_cancelled.connect(_on_dig_minigame_cancelled)
	add_child(_dig_minigame)

func _on_dig_minigame_finished() -> void:
	if _dig_minigame:
		_dig_minigame.queue_free()
		_dig_minigame = null
	_complete_digging()
	var player = _get_player()
	if player and player.has_method("capture_mouse"):
		player.capture_mouse()

func _on_dig_minigame_cancelled() -> void:
	if _dig_minigame:
		_dig_minigame.queue_free()
		_dig_minigame = null
	_set_state(ArtifactState.DIG_SITE)
	var player = _get_player()
	if player and player.has_method("end_interaction"):
		player.end_interaction()
	if player and player.has_method("capture_mouse"):
		player.capture_mouse()

func _start_digging() -> void:
	_start_digging_minigame()

func _pause_digging() -> void:
	pass

func _cancel_digging() -> void:
	_on_dig_minigame_cancelled()

# ---- Dig completion ----
func _complete_digging() -> void:
	dig_progress = 1.0
	if dust_particles:
		dust_particles.emitting = false
	_stop_excavation_audio()
	if visual_model:
		visual_model.visible = true
		visual_model.scale = Vector3.ONE
		visual_model.position.y = -buried_depth
		var tw = create_tween()
		tw.tween_property(visual_model, "position:y", 0.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dig_completed.emit()
	_set_state(ArtifactState.EXPOSED)
	var player = _get_player()
	if player and player.has_method("end_interaction"):
		player.end_interaction()

# ---- Cleaning UI ----
func _start_cleaning() -> void:
	cleaning_started.emit()
	_set_state(ArtifactState.CLEANING)
	var player = _get_player()
	if player and player.has_method("begin_interaction"):
		var anchor = get_interaction_anchor(player.global_position)
		player.begin_interaction(anchor, global_position)
	_start_cleaning_ui()

func _start_cleaning_ui() -> void:
	# Load and instantiate the cleaning UI
	var ui_scene = load("res://scenes/ui/dig_clean_ui.tscn")
	if not ui_scene:
		# Fallback: auto-complete cleaning if scene not found
		call_deferred("on_cleaning_done", artifact_id)
		return
	_clean_ui = ui_scene.instantiate()
	_clean_ui.artifact_id = artifact_id
	_clean_ui.clean_duration = clean_duration
	if _clean_ui.has_signal("cleaning_done"):
		_clean_ui.cleaning_done.connect(on_cleaning_done)
	add_child(_clean_ui)

func on_cleaning_done(done_artifact_id: String) -> void:
	if _clean_ui:
		_clean_ui.queue_free()
		_clean_ui = null
	# P7: the Catalogue Entry opens first; the specimen is registered when it closes.
	# The player stays in interaction (controls locked, mouse visible) until then.
	_open_catalogue_entry()

func _open_catalogue_entry() -> void:
	var exam_script = load("res://scripts/ui/scientific_examination_panel.gd")
	if not exam_script:
		_on_documentation_closed(artifact_id)  # fallback: never lose the specimen
		return
	var panel := CanvasLayer.new()
	panel.set_script(exam_script)
	panel.artifact_id = artifact_id
	panel.documentation_closed.connect(_on_documentation_closed)
	if panel.has_signal("story_requested"):
		panel.story_requested.connect(func(_id: String) -> void: _story_requested = true)
	add_child(panel)

func _on_documentation_closed(done_id: String) -> void:
	_identify_artifact()
	var player = _get_player()
	if player and player.has_method("end_interaction"):
		player.end_interaction()
	# WATCH STORY hands over to the HUD, which owns the flashback and recaptures the mouse when it
	# ends. CONTINUE (or no HUD present) recaptures the mouse right away.
	var story_started := false
	if _story_requested:
		var huds := get_tree().get_nodes_in_group("hud")
		if not huds.is_empty() and huds[0].has_method("play_artifact_story"):
			huds[0].play_artifact_story(done_id)
			story_started = true
	_story_requested = false
	if not story_started and player and player.has_method("capture_mouse"):
		player.capture_mouse()

func _identify_artifact() -> void:
	_set_state(ArtifactState.IDENTIFIED)
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.register_artifact(artifact_id)
	cleaning_completed.emit(artifact_id)
	artifact_interacted.emit(artifact_id)

# ---- Visual representation (all existing mesh builders kept intact) ----
func set_recovered_visuals() -> void:
	is_recovered = true
	current_state = ArtifactState.IDENTIFIED
	_update_state_visuals()

func _update_visual_representation() -> void:
	if not visual_model:
		return
	
	# Clear any previous child geometry
	for c in visual_model.get_children():
		c.queue_free()
	
	# Generate stylized 3D geometry corresponding to the artifact ID
	match artifact_id:
		"apollo_lrv":
			_build_lrv_mesh()
		"apollo_lm_descent_stage":
			_build_lm_descent_mesh()
		"alsep":
			_build_alsep_mesh()
		"sojourner":
			_build_sojourner_mesh()
		"pathfinder":
			_build_pathfinder_mesh()
		"spirit":
			_build_spirit_mesh()
		"opportunity":
			_build_opportunity_mesh()
		"viking_1":
			_build_viking_1_mesh()
		"viking_2":
			_build_viking_2_mesh()
		"phoenix":
			_build_phoenix_mesh()
		"insight":
			_build_insight_mesh()
		"ingenuity":
			_build_ingenuity_mesh()
		"jezero_delta_clay":
			_build_jezero_clay_mesh()
		"seitah_olivine_basalt":
			_build_seitah_basalt_mesh()
		"perseverance_heatshield_remnant":
			_build_heatshield_remnant_mesh()
		"martian_meteorite_shergottite":
			_build_martian_meteorite_mesh()
		_:
			_build_default_mesh()

func _build_lrv_mesh() -> void:
	# Stylized Lunar Roving Vehicle
	var chassis = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.8, 0.35, 1.1)
	chassis.mesh = box
	chassis.position = Vector3(0, 0.45, 0)
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.9, 0.9, 0.95)
	chassis.set_surface_override_material(0, white_mat)
	visual_model.add_child(chassis)
	
	# Seats
	var seat = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.5, 0.4, 0.8)
	seat.mesh = s_box
	seat.position = Vector3(-0.2, 0.7, 0)
	visual_model.add_child(seat)
	
	# Antenna Dish
	var antenna = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.05
	cyl.height = 0.2
	antenna.mesh = cyl
	antenna.position = Vector3(0.6, 1.0, 0)
	antenna.rotation_degrees = Vector3(25, 0, 45)
	visual_model.add_child(antenna)
	
	# 4 Wire-mesh wheels
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.3, 0.32, 0.35)
	var wheel_offsets = [
		Vector3(-0.7, 0.3, -0.65), Vector3(0.7, 0.3, -0.65),
		Vector3(-0.7, 0.3, 0.65), Vector3(0.7, 0.3, 0.65)
	]
	for off in wheel_offsets:
		var wheel = MeshInstance3D.new()
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.3
		w_cyl.bottom_radius = 0.3
		w_cyl.height = 0.2
		wheel.mesh = w_cyl
		wheel.rotation_degrees = Vector3(90, 0, 0)
		wheel.position = off
		wheel.set_surface_override_material(0, wheel_mat)
		visual_model.add_child(wheel)

func _build_lm_descent_mesh() -> void:
	# Gold foil octagonal descent stage
	var body = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radial_segments = 8
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.4
	cyl.height = 0.9
	body.mesh = cyl
	body.position = Vector3(0, 0.65, 0)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.2)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.25
	body.set_surface_override_material(0, gold_mat)
	visual_model.add_child(body)
	
	# Central Rocket Nozzle
	var nozzle = MeshInstance3D.new()
	var n_cyl = CylinderMesh.new()
	n_cyl.top_radius = 0.25
	n_cyl.bottom_radius = 0.45
	n_cyl.height = 0.4
	nozzle.mesh = n_cyl
	nozzle.position = Vector3(0, 0.2, 0)
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.15, 0.15, 0.18)
	nozzle.set_surface_override_material(0, dark_mat)
	visual_model.add_child(nozzle)
	
	# 4 Landing Legs
	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.85, 0.85, 0.9)
	var leg_angles = [45, 135, 225, 315]
	for a in leg_angles:
		var rad = deg_to_rad(a)
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.15, 0.15, 1.4)
		leg.mesh = l_box
		leg.position = Vector3(sin(rad) * 1.5, 0.35, cos(rad) * 1.5)
		leg.rotation.y = rad
		leg.rotation.x = deg_to_rad(30)
		leg.set_surface_override_material(0, leg_mat)
		visual_model.add_child(leg)
		
		# Footpad
		var pad = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.25
		p_cyl.bottom_radius = 0.25
		p_cyl.height = 0.06
		pad.mesh = p_cyl
		pad.position = Vector3(sin(rad) * 2.1, 0.03, cos(rad) * 2.1)
		pad.set_surface_override_material(0, gold_mat)
		visual_model.add_child(pad)

func _build_alsep_mesh() -> void:
	# Central station box
	var station = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.7, 0.6, 0.7)
	station.mesh = s_box
	station.position = Vector3(0, 0.3, 0)
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.92, 0.92, 0.95)
	station.set_surface_override_material(0, white_mat)
	visual_model.add_child(station)
	
	# RTG Power cask (cylinder with cooling fins)
	var rtg = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.radial_segments = 12
	r_cyl.top_radius = 0.2
	r_cyl.bottom_radius = 0.2
	r_cyl.height = 0.5
	rtg.mesh = r_cyl
	rtg.position = Vector3(0.7, 0.25, 0.3)
	var rtg_mat = StandardMaterial3D.new()
	rtg_mat.albedo_color = Color(0.4, 0.42, 0.45)
	rtg_mat.metallic = 0.5
	rtg.set_surface_override_material(0, rtg_mat)
	visual_model.add_child(rtg)
	
	# Helical Antenna Mast
	var antenna = MeshInstance3D.new()
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.03
	a_cyl.bottom_radius = 0.03
	a_cyl.height = 1.0
	antenna.mesh = a_cyl
	antenna.position = Vector3(0, 0.9, 0)
	visual_model.add_child(antenna)

func _build_sojourner_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_sojourner_rover(0.45)
	visual_model.add_child(model)

func _build_pathfinder_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_pathfinder_lander(0.50)
	visual_model.add_child(model)

func _build_opportunity_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_mer_rover("opportunity", 0.65)
	visual_model.add_child(model)

func _build_spirit_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_mer_rover("spirit", 0.70)
	visual_model.add_child(model)

func _build_viking_1_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_viking_lander(1, 0.55)
	visual_model.add_child(model)

func _build_viking_2_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_viking_lander(2, 0.55)
	visual_model.add_child(model)

func _build_phoenix_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_phoenix_lander(0.40)
	visual_model.add_child(model)

func _build_insight_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_insight_lander(0.70)
	visual_model.add_child(model)

func _build_ingenuity_mesh() -> void:
	var model = HistoricalSpacecraftModels.build_ingenuity_helicopter(true, 0.30)
	visual_model.add_child(model)

func _build_default_mesh() -> void:
	var box = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = Vector3(0.8, 0.8, 0.8)
	box.mesh = b
	box.position = Vector3(0, 0.4, 0)
	visual_model.add_child(box)

func _build_jezero_clay_mesh() -> void:
	# Stratified sedimentary delta mudstone sample with distinct fine bedding laminations
	var base_rock = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.38, 0.16, 0.28)
	var mat_clay = StandardMaterial3D.new()
	mat_clay.albedo_color = Color(0.60, 0.52, 0.42) # Tan/beige smectite-bearing mudstone
	mat_clay.roughness = 0.94
	b_box.material = mat_clay
	base_rock.mesh = b_box
	base_rock.position = Vector3(0, 0.10, 0)
	visual_model.add_child(base_rock)

	# Laminated sedimentary bedding layers
	var layer1 = MeshInstance3D.new()
	var l_box1 = BoxMesh.new()
	l_box1.size = Vector3(0.39, 0.03, 0.29)
	var mat_silt = StandardMaterial3D.new()
	mat_silt.albedo_color = Color(0.72, 0.60, 0.48)
	mat_silt.roughness = 0.96
	l_box1.material = mat_silt
	layer1.mesh = l_box1
	layer1.position = Vector3(0, 0.14, 0)
	visual_model.add_child(layer1)

	# Light calcium sulfate evaporite vein
	var vein = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.36, 0.015, 0.05)
	var mat_vein = StandardMaterial3D.new()
	mat_vein.albedo_color = Color(0.92, 0.90, 0.88) # White gypsum/sulfate mineral filling
	mat_vein.roughness = 0.70
	v_box.material = mat_vein
	vein.mesh = v_box
	vein.position = Vector3(0, 0.18, 0.04)
	visual_model.add_child(vein)

func _build_seitah_basalt_mesh() -> void:
	# Igneous olivine cumulate rock from the Jezero crater floor
	var rock = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radial_segments = 7
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.25
	cyl.height = 0.24
	var mat_basalt = StandardMaterial3D.new()
	mat_basalt.albedo_color = Color(0.24, 0.23, 0.21) # Dark basaltic groundmass
	mat_basalt.roughness = 0.88
	cyl.material = mat_basalt
	rock.mesh = cyl
	rock.position = Vector3(0, 0.12, 0)
	rock.rotation_degrees = Vector3(15, 30, -10)
	visual_model.add_child(rock)

	# Distinct green-tinted olivine crystal phenocrysts
	var mat_olivine = StandardMaterial3D.new()
	mat_olivine.albedo_color = Color(0.36, 0.44, 0.26) # Characteristic forsterite/olivine green
	mat_olivine.roughness = 0.45
	mat_olivine.metallic = 0.1
	for i in range(5):
		var crystal = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(0.06, 0.05, 0.06)
		c_mesh.material = mat_olivine
		crystal.mesh = c_mesh
		var a = i * 1.25
		crystal.position = Vector3(cos(a) * 0.16, 0.14 + sin(a) * 0.06, sin(a) * 0.16)
		crystal.rotation_degrees = Vector3(a * 20, a * 45, a * 15)
		visual_model.add_child(crystal)

func _build_heatshield_remnant_mesh() -> void:
	# Curvilinear thermal protection tile with titanium bracket
	var tile = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.48, 0.08, 0.36)
	var mat_tile = StandardMaterial3D.new()
	mat_tile.albedo_color = Color(0.18, 0.16, 0.16) # Charred PICA ablator surface
	mat_tile.roughness = 0.95
	t_box.material = mat_tile
	tile.mesh = t_box
	tile.position = Vector3(0, 0.08, 0)
	tile.rotation_degrees = Vector3(8, -15, 6)
	visual_model.add_child(tile)

	# Lightweight reflective aerospace alloy backing
	var backing = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.46, 0.02, 0.34)
	var mat_back = StandardMaterial3D.new()
	mat_back.albedo_color = Color(0.85, 0.85, 0.88)
	mat_back.metallic = 0.92
	mat_back.roughness = 0.25
	b_box.material = mat_back
	backing.mesh = b_box
	backing.position = Vector3(0, 0.04, 0)
	tile.add_child(backing)

	# Inconel fastener and serial tag
	var tag = MeshInstance3D.new()
	var tag_mesh = BoxMesh.new()
	tag_mesh.size = Vector3(0.12, 0.01, 0.06)
	var mat_tag = StandardMaterial3D.new()
	mat_tag.albedo_color = Color(0.95, 0.90, 0.40) # Brass/anodized ID plate
	mat_tag.metallic = 0.80
	tag_mesh.material = mat_tag
	tag.mesh = tag_mesh
	tag.position = Vector3(0.12, 0.05, 0.08)
	tile.add_child(tag)

func _build_martian_meteorite_mesh() -> void:
	# Shergottite basaltic meteorite with black fusion crust and shock melt veins
	var rock = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.28
	sphere.radial_segments = 12
	sphere.rings = 6
	var mat_shergottite = StandardMaterial3D.new()
	mat_shergottite.albedo_color = Color(0.28, 0.26, 0.24) # Dark interior pyroxene
	mat_shergottite.roughness = 0.82
	sphere.material = mat_shergottite
	rock.mesh = sphere
	rock.position = Vector3(0, 0.10, 0)
	visual_model.add_child(rock)

	# Glassy shock melt vein
	var vein = MeshInstance3D.new()
	var v_cyl = CylinderMesh.new()
	v_cyl.top_radius = 0.015
	v_cyl.bottom_radius = 0.015
	v_cyl.height = 0.22
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.08, 0.08, 0.09) # Black impact glass / maskelynite
	mat_glass.roughness = 0.20
	mat_glass.metallic = 0.15
	v_cyl.material = mat_glass
	vein.mesh = v_cyl
	vein.position = Vector3(0.05, 0.10, 0)
	vein.rotation_degrees = Vector3(35, 20, 45)
	visual_model.add_child(vein)
